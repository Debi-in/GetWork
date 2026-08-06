// ============================================================
// LOGIN SCREEN — GetWork App
// Phone OTP authentication using Firebase Auth.
// Two-step: Phone entry → OTP verification.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────
  bool _otpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  String? _errorMessage;

  final _phoneController = TextEditingController(text: '+977');
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: const Interval(0.0, 0.7)));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _otpNodes) {
      n.dispose();
    }
    super.dispose();
  }

  // ── Step 1: Send OTP ─────────────────────────────────────────
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid phone number');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await AuthService.verifyPhone(
      phoneNumber: phone,
      codeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _isLoading = false;
        });
        // Slide to OTP panel
        _slideCtrl.reset();
        _slideCtrl.forward();
        // Auto-focus first OTP box
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _otpNodes[0].requestFocus();
        });
      },
      onError: (msg) {
        if (!mounted) return;
        setState(() {
          _errorMessage = msg;
          _isLoading = false;
        });
      },
      autoVerified: (credential) async {
        await _signInWithCredential(credential);
      },
    );
  }

  // ── Step 2: Verify OTP ───────────────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP');
      return;
    }
    if (_verificationId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await AuthService.confirmOtp(
      verificationId: _verificationId!,
      otp: otp,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
      return;
    }

    await _postLoginRoute();
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) await _postLoginRoute();
    } catch (_) {}
  }

  // ── Post-login routing: check Firestore role ─────────────────
  Future<void> _postLoginRoute() async {
    final uid = AuthService.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Check Firestore for existing locked role
    final role = await FirestoreUserService.getRole(uid);

    if (!mounted) return;

    if (role != null && role.isNotEmpty) {
      // Role already locked — cache locally and go straight to home
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      if (!mounted) return;
      if (role == 'business') {
        context.go('/business');
      } else {
        context.go('/home');
      }
    } else {
      // No role yet — go to choose role screen
      context.go('/choose-role');
    }
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Logo + App Name
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowMedium,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.work_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'GetWork',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  if (!_otpSent) ...[
                    // ── Step 1: Phone Entry ──────────────────────────
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter your phone number to sign in or create a new account.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Phone number field
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '+977 98XXXXXXXX',
                        hintStyle: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textHint,
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.phone_android_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'A 6-digit OTP will be sent via SMS to verify your number.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ] else ...[
                    // ── Step 2: OTP Entry ────────────────────────────
                    const Text(
                      'Enter OTP',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          const TextSpan(text: 'We sent a 6-digit code to '),
                          TextSpan(
                            text: _phoneController.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 6-box OTP input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        return SizedBox(
                          width: 48,
                          height: 56,
                          child: TextFormField(
                            controller: _otpControllers[i],
                            focusNode: _otpNodes[i],
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 2),
                              ),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty && i < 5) {
                                _otpNodes[i + 1].requestFocus();
                              } else if (val.isEmpty && i > 0) {
                                _otpNodes[i - 1].requestFocus();
                              }
                              // Auto-verify when last digit entered
                              if (i == 5 && val.isNotEmpty) {
                                _verifyOtp();
                              }
                            },
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Did not receive the OTP? ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: _isLoading ? null : _sendOtp,
                          child: const Text(
                            'Resend',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Error Message ────────────────────────────────
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Primary CTA Button ───────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (_otpSent ? _verifyOtp : _sendOtp),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                _otpSent ? 'Verify OTP' : 'Send OTP',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _otpSent = false;
                            _errorMessage = null;
                            for (final c in _otpControllers) {
                              c.clear();
                            }
                          });
                          _slideCtrl.reset();
                          _slideCtrl.forward();
                        },
                        child: const Text(
                          'Change phone number',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // ── Legal note ───────────────────────────────────
                  const Center(
                    child: Text(
                      'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textHint,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
