// ============================================================
// APPLY SUCCESS SCREEN — GetWork App
// Premium animated success page shown after worker applies
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../router.dart';

class ApplySuccessScreen extends StatefulWidget {
  final String? jobTitle;
  final String? businessName;

  const ApplySuccessScreen({
    super.key,
    this.jobTitle,
    this.businessName,
  });

  @override
  State<ApplySuccessScreen> createState() => _ApplySuccessScreenState();
}

class _ApplySuccessScreenState extends State<ApplySuccessScreen>
    with TickerProviderStateMixin {
  // Check mark draw animation
  late AnimationController _checkController;
  late Animation<double> _checkProgress;

  // Circle scale-in
  late AnimationController _circleController;
  late Animation<double> _circleScale;
  late Animation<double> _circleOpacity;

  // Card slide-up
  late AnimationController _cardController;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardOpacity;

  // Confetti particles
  late AnimationController _confettiController;
  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();

    // ── Circle pop-in ──────────────────────────────────────────
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _circleScale = CurvedAnimation(
      parent: _circleController,
      curve: const Cubic(0.34, 1.56, 0.64, 1.0), // spring
    );
    _circleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeOut),
    );

    // ── Check draw ─────────────────────────────────────────────
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkProgress = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOutCubic,
    );

    // ── Card slide-up ─────────────────────────────────────────
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));
    _cardOpacity = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);

    // ── Confetti ───────────────────────────────────────────────
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _spawnParticles();

    // Start sequence
    _circleController.forward().then((_) {
      _checkController.forward().then((_) {
        _cardController.forward();
        _confettiController.forward();
      });
    });
  }

  void _spawnParticles() {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      const Color(0xFF7C4DFF),
      const Color(0xFFFFC107),
      const Color(0xFFFF5722),
      const Color(0xFF00BCD4),
    ];
    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(
        color: colors[_rng.nextInt(colors.length)],
        angle: _rng.nextDouble() * 2 * math.pi,
        speed: _rng.nextDouble() * 280 + 80,
        size: _rng.nextDouble() * 8 + 4,
        shape: _rng.nextBool() ? _ParticleShape.circle : _ParticleShape.rect,
      ));
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    _circleController.dispose();
    _cardController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF4), // very light green tint
      body: Stack(
        children: [
          // ── Gradient Background ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8F8EE), Color(0xFFF7FDF9)],
              ),
            ),
          ),

          // ── Decorative Circles ───────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.04),
              ),
            ),
          ),

          // ── Confetti Layer ───────────────────────────────────
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) {
              return CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _confettiController.value,
                  center: Offset(
                    MediaQuery.of(context).size.width / 2,
                    MediaQuery.of(context).size.height * 0.38,
                  ),
                ),
                size: Size.infinite,
              );
            },
          ),

          // ── Main Content ─────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Animated Check Circle ──────────────────────
                  ScaleTransition(
                    scale: _circleScale,
                    child: FadeTransition(
                      opacity: _circleOpacity,
                      child: SizedBox(
                        width: 130,
                        height: 130,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow ring
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: 0.12),
                              ),
                            ),
                            // Mid ring
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: 0.18),
                              ),
                            ),
                            // Core circle
                            Container(
                              width: 76,
                              height: 76,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF4CAF50),
                                    Color(0xFF2E7D32),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x5529AB61),
                                    blurRadius: 20,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _checkProgress,
                                builder: (context, _) => CustomPaint(
                                  painter: _CheckPainter(
                                    progress: _checkProgress.value,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Heading ────────────────────────────────────
                  FadeTransition(
                    opacity: _cardOpacity,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: Column(
                        children: [
                          const Text(
                            'Application Sent!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B4332),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.businessName != null
                                ? 'Your application to ${widget.businessName} is on its way.\nWe\'ll notify you once reviewed!'
                                : 'Your application is on its way.\nWe\'ll notify you once the business reviews it!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              color: Color(0xFF52796F),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Status Steps Card ──────────────────────────
                  FadeTransition(
                    opacity: _cardOpacity,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _StatusStep(
                              icon: Icons.send_rounded,
                              label: 'Application Submitted',
                              isDone: true,
                              color: AppColors.primary,
                            ),
                            _StepConnector(isDone: true),
                            _StatusStep(
                              icon: Icons.visibility_outlined,
                              label: 'Business Reviews Your Profile',
                              isDone: false,
                              color: AppColors.accent,
                            ),
                            _StepConnector(isDone: false),
                            _StatusStep(
                              icon: Icons.notifications_active_outlined,
                              label: 'You Get Notified & Start Shift',
                              isDone: false,
                              color: const Color(0xFF7C4DFF),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Buttons ────────────────────────────────────
                  FadeTransition(
                    opacity: _cardOpacity,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: Column(
                        children: [
                          // Primary CTA
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => context.go(AppRoutes.home),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                              ),
                              child: const Text(
                                'Browse More Jobs',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Secondary
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () => context.go(AppRoutes.profile),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'View My Profile',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step Status Row ────────────────────────────────────────────
class _StatusStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;
  final Color color;

  const _StatusStep({
    required this.icon,
    required this.label,
    required this.isDone,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? color : color.withValues(alpha: 0.1),
            border: Border.all(
              color: isDone ? color : color.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Icon(
            isDone ? Icons.check_rounded : icon,
            size: 18,
            color: isDone ? Colors.white : color.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
              color: isDone ? const Color(0xFF1B4332) : const Color(0xFF6B7280),
            ),
          ),
        ),
        if (isDone)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'Done',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool isDone;
  const _StepConnector({required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 19, top: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              color: isDone
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : const Color(0xFFE5E7EB),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Check Painter ───────────────────────────────────────────────
class _CheckPainter extends CustomPainter {
  final double progress;
  const _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Check path: short arm then long arm
    final path = Path()
      ..moveTo(cx - 12, cy)
      ..lineTo(cx - 3, cy + 10)
      ..lineTo(cx + 13, cy - 10);

    final metrics = path.computeMetrics().first;
    final drawn = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

// ── Confetti Particle ───────────────────────────────────────────
enum _ParticleShape { circle, rect }

class _Particle {
  final Color color;
  final double angle;
  final double speed;
  final double size;
  final _ParticleShape shape;
  const _Particle({
    required this.color,
    required this.angle,
    required this.speed,
    required this.size,
    required this.shape,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Offset center;

  const _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final eased = Curves.easeOutCubic.transform(progress);

    for (final p in particles) {
      final dist = p.speed * eased;
      final gravity = 200 * eased * eased;
      final dx = math.cos(p.angle) * dist;
      final dy = math.sin(p.angle) * dist + gravity;
      final opacity = (1.0 - eased * 0.8).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final cx = center.dx + dx;
      final cy = center.dy + dy;

      if (p.shape == _ParticleShape.circle) {
        canvas.drawCircle(Offset(cx, cy), p.size / 2, paint);
      } else {
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(eased * math.pi * 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size / 2),
            const Radius.circular(2),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
