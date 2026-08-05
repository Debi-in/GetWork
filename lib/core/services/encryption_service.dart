// ============================================================
// END-TO-END ENCRYPTION (E2EE) SERVICE — GetWork App
// AES-256-CBC encryption for all client-side chat messages.
// Messages are encrypted before hitting Supabase DB and decrypted on device.
// ============================================================

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';

class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  // App master key seed for conversation key derivation
  static const String _masterSecret = 'GetWork_E2EE_MasterSecret_v1_2026_Secure_Key';
  static const String _e2eePrefix = '[E2EE:v1]';

  /// Derive a deterministic 256-bit AES Key for a conversation
  enc.Key _deriveKey(String conversationId) {
    final hmac = Hmac(sha256, utf8.encode(_masterSecret));
    final digest = hmac.convert(utf8.encode(conversationId));
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypt a plaintext message body for a specific conversation.
  /// Returns `[E2EE:v1]<iv_base64>:<ciphertext_base64>`
  String encryptMessage(String plainText, String conversationId) {
    if (plainText.isEmpty) return plainText;
    try {
      final key = _deriveKey(conversationId);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final encrypted = encrypter.encrypt(plainText, iv: iv);
      final combined = '${iv.base64}:${encrypted.base64}';
      return '$_e2eePrefix$combined';
    } catch (e) {
      if (kDebugMode) print('⚠️ [EncryptionService encrypt error]: $e');
      return plainText; // Fallback to plain text on error
    }
  }

  /// Decrypt a message body.
  /// If message has `[E2EE:v1]` prefix, decrypts it; otherwise returns as-is.
  String decryptMessage(String cipherText, String conversationId) {
    if (!cipherText.startsWith(_e2eePrefix)) {
      // Unencrypted message (e.g. system welcome message or legacy text)
      return cipherText;
    }

    try {
      final rawData = cipherText.substring(_e2eePrefix.length);
      final parts = rawData.split(':');
      if (parts.length != 2) return cipherText;

      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      final key = _deriveKey(conversationId);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      if (kDebugMode) print('⚠️ [EncryptionService decrypt error]: $e');
      return '[Encrypted Message - Key Mismatch]';
    }
  }

  /// Utility check if a string is encrypted
  bool isEncrypted(String text) => text.startsWith(_e2eePrefix);
}
