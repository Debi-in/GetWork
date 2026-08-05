// ============================================================
// CHAT REPOSITORY — GetWork App
// Reads conversations + messages from Supabase.
// Always guarantees one "system welcome" conversation exists.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/encryption_service.dart';

// ── Models ────────────────────────────────────────────────────

class ConversationModel {
  final String id;
  final String jobId;
  final String businessName;
  final String workerName;
  final String workerPhone;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isSystem;

  const ConversationModel({
    required this.id,
    required this.jobId,
    required this.businessName,
    required this.workerName,
    required this.workerPhone,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    this.isSystem = false,
  });

  factory ConversationModel.fromRow(Map<String, dynamic> row) {
    final convId = row['id']?.toString() ?? '';
    final rawLastMsg = row['last_message']?.toString() ?? '';
    final decryptedLastMsg =
        EncryptionService.instance.decryptMessage(rawLastMsg, convId);

    return ConversationModel(
      id: convId,
      jobId: row['job_id']?.toString() ?? '',
      businessName: row['business_name']?.toString() ?? '',
      workerName: row['worker_name']?.toString() ?? '',
      workerPhone: row['worker_phone']?.toString() ?? '',
      lastMessage: decryptedLastMsg,
      lastMessageAt: row['last_message_at'] != null
          ? DateTime.parse(row['last_message_at'].toString())
          : DateTime.now(),
      unreadCount: (row['unread_count'] as num?)?.toInt() ?? 0,
      isSystem: row['worker_name']?.toString() == 'GetWork System',
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderType; // 'system' | 'business' | 'worker'
  final String senderName;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.senderName,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });

  bool get isSystem => senderType == 'system';
  bool get isMe => senderType == 'business';

  factory MessageModel.fromRow(Map<String, dynamic> row) {
    final convId = row['conversation_id']?.toString() ?? '';
    final rawBody = (row['body'] ?? row['content'])?.toString() ?? '';
    final decryptedBody =
        EncryptionService.instance.decryptMessage(rawBody, convId);

    return MessageModel(
      id: row['id']?.toString() ?? '',
      conversationId: convId,
      senderType: row['sender_type']?.toString() ?? 'system',
      senderName: row['sender_name']?.toString() ?? 'GetWork',
      body: decryptedBody,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'].toString())
          : DateTime.now(),
      isRead: row['read_at'] != null,
    );
  }
}

// ── Repository ────────────────────────────────────────────────

class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  final SupabaseClient _db = Supabase.instance.client;

  static const String _systemConvId = '00000000-0000-0000-0000-000000000001';

  // ── Fetch all conversations, system message always first ──
  Future<List<ConversationModel>> fetchConversations() async {
    try {
      final response = await _db
          .from('conversations')
          .select()
          .order('last_message_at', ascending: false)
          .limit(50);

      final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
      final convs = rows.map(ConversationModel.fromRow).toList();

      // Ensure system welcome is always present (fallback if DB seeding failed)
      final hasSystem = convs.any((c) => c.id == _systemConvId);
      if (!hasSystem) {
        convs.insert(0, _systemWelcomeConversation());
      } else {
        // Move system to top
        final sysIdx = convs.indexWhere((c) => c.id == _systemConvId);
        if (sysIdx > 0) {
          final sys = convs.removeAt(sysIdx);
          convs.insert(0, sys);
        }
      }
      return convs;
    } catch (e) {
      if (kDebugMode) print('⚠️ [ChatRepository fetchConversations]: $e');
      // Always return at least the system welcome message
      return [_systemWelcomeConversation()];
    }
  }

  // ── Fetch messages for a conversation ─────────────────────
  Future<List<MessageModel>> fetchMessages(String conversationId) async {
    try {
      final response = await _db
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
      final msgs = rows.map(MessageModel.fromRow).toList();

      // Always inject system welcome at top if not present
      final hasWelcome = msgs.any((m) => m.isSystem);
      if (!hasWelcome) {
        msgs.insert(0, _systemWelcomeMessage(conversationId));
      }
      return msgs;
    } catch (e) {
      if (kDebugMode) print('⚠️ [ChatRepository fetchMessages]: $e');
      return [_systemWelcomeMessage(conversationId)];
    }
  }

  // ── Send a message (End-to-End Encrypted) ────────────────────
  Future<bool> sendMessage({
    required String conversationId,
    required String body,
    String senderType = 'business',
    String senderName = 'Himalayan Mart',
  }) async {
    try {
      // 🔒 Encrypt body before writing to Supabase DB
      final encryptedBody =
          EncryptionService.instance.encryptMessage(body, conversationId);

      await _db.from('messages').insert({
        'conversation_id': conversationId,
        'sender_type': senderType,
        'sender_name': senderName,
        'body': encryptedBody,
        'content': encryptedBody,
      });
      // Update encrypted last_message on conversation
      await _db.from('conversations').update({
        'last_message': encryptedBody,
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);
      return true;
    } catch (e) {
      if (kDebugMode) print('⚠️ [ChatRepository sendMessage]: $e');
      return false;
    }
  }

  // ── Mark conversation as read ──────────────────────────────
  Future<void> markRead(String conversationId) async {
    try {
      await _db
          .from('conversations')
          .update({'unread_count': 0})
          .eq('id', conversationId);
    } catch (e) {
      if (kDebugMode) print('⚠️ [ChatRepository markRead]: $e');
    }
  }

  // ── Create a conversation when worker applies ──────────────
  Future<String?> createOrGetConversation({
    required String jobId,
    required String businessName,
    required String workerName,
    required String workerPhone,
  }) async {
    try {
      // Check if already exists
      final existing = await _db
          .from('conversations')
          .select('id')
          .eq('job_id', jobId)
          .eq('worker_phone', workerPhone)
          .maybeSingle();

      if (existing != null) return existing['id']?.toString();

      // Create new
      final resp = await _db.from('conversations').insert({
        'job_id': jobId,
        'business_name': businessName,
        'worker_name': workerName,
        'worker_phone': workerPhone,
        'last_message': '${workerName} applied for the job.',
        'unread_count': 1,
      }).select('id').single();

      final convId = resp['id']?.toString();

      // Seed system welcome for this conversation
      if (convId != null) {
        final systemMsg = '👋 Hi! $workerName just applied for your job. You can chat here to coordinate shift details.';
        await _db.from('messages').insert({
          'conversation_id': convId,
          'sender_type': 'system',
          'sender_name': 'GetWork',
          'body': systemMsg,
          'content': systemMsg,
        });
        // Then add the worker's first message (End-to-End Encrypted)
        final workerMsgText = 'Hi! I just applied for the position.';
        final encryptedWorkerMsg = EncryptionService.instance
            .encryptMessage(workerMsgText, convId);

        await _db.from('messages').insert({
          'conversation_id': convId,
          'sender_type': 'worker',
          'sender_name': workerName,
          'body': encryptedWorkerMsg,
          'content': encryptedWorkerMsg,
        });
      }
      return convId;
    } catch (e) {
      if (kDebugMode) print('⚠️ [ChatRepository createConversation]: $e');
      return null;
    }
  }

  // ── Local fallback: system welcome conversation ────────────
  static ConversationModel _systemWelcomeConversation() {
    return ConversationModel(
      id: _systemConvId,
      jobId: '',
      businessName: 'GetWork',
      workerName: 'GetWork System',
      workerPhone: '',
      lastMessage:
          '👋 Welcome! Post your first job to receive applications here.',
      lastMessageAt: DateTime.now(),
      unreadCount: 1,
      isSystem: true,
    );
  }

  static MessageModel _systemWelcomeMessage(String convId) {
    return MessageModel(
      id: 'sys-welcome-0',
      conversationId: convId,
      senderType: 'system',
      senderName: 'GetWork',
      body:
          '👋 Welcome to GetWork Business! Here you\'ll see messages from workers who apply to your jobs. Post your first shift to get started — workers in your area will apply within minutes.',
      createdAt: DateTime.now(),
      isRead: false,
    );
  }
}
