// ============================================================
// AUTH SERVICE -- GetWork App
// Thin wrapper around Firebase Auth for sign-in, sign-out,
// and current user state checks.
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // -- Current state --------------------------------------------------

  /// Returns true if a Firebase user is currently signed in.
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Returns the UID of the signed-in user, or null.
  static String? get uid => _auth.currentUser?.uid;

  /// Returns the phone number of the signed-in user, or null.
  static String? get phone => _auth.currentUser?.phoneNumber;

  /// Stream that emits whenever auth state changes.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // -- Phone OTP -------------------------------------------------------

  /// Kick off phone verification.
  /// [codeSent] is called with (verificationId, resendToken).
  /// [onError] is called with a human-readable message.
  static Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(String message) onError,
    void Function(PhoneAuthCredential credential)? autoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) {
        autoVerified?.call(credential);
      },
      verificationFailed: (e) {
        String msg;
        switch (e.code) {
          case 'invalid-phone-number':
            msg = 'The phone number is not valid.';
            break;
          case 'too-many-requests':
            msg = 'Too many attempts. Please wait and try again.';
            break;
          case 'quota-exceeded':
            msg = 'SMS quota exceeded. Please try again later.';
            break;
          default:
            msg = e.message ?? 'Phone verification failed. Please try again.';
        }
        onError(msg);
      },
      codeSent: (verificationId, resendToken) {
        codeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Confirm OTP and sign the user in.
  /// Returns null on success, or an error message string.
  static Future<String?> confirmOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      return null; // success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-verification-code':
          return 'Incorrect OTP. Please check and try again.';
        case 'session-expired':
          return 'OTP expired. Please request a new one.';
        default:
          return e.message ?? 'OTP verification failed.';
      }
    }
  }

  /// Sign the current user out.
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}