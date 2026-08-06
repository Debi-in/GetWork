// ============================================================
// MORPHIC JOB SHEET WRAPPER — GetWork App
// Handles PowerPoint-like Morph expand/collapse transition
// Synchronized with map camera glide (staggered entrance)
// Gate: sheet only expands AFTER map has centered on the pin
// ============================================================

import 'package:flutter/material.dart';
import '../../../models/job_model.dart';
import 'job_bottom_sheet.dart';

class MorphicJobBottomSheetWrapper extends StatefulWidget {
  final JobModel? job;
  final VoidCallback onClose;

  /// True once the map camera has finished flying to the job location.
  /// The sheet will NOT animate open until this is true.
  final bool mapCentered;

  const MorphicJobBottomSheetWrapper({
    super.key,
    required this.job,
    required this.onClose,
    this.mapCentered = false,
  });

  @override
  State<MorphicJobBottomSheetWrapper> createState() =>
      _MorphicJobBottomSheetWrapperState();
}

class _MorphicJobBottomSheetWrapperState
    extends State<MorphicJobBottomSheetWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<Offset> _slide;
  late Animation<double> _opacity;
  JobModel? _cachedJob;

  @override
  void initState() {
    super.initState();
    _cachedJob = widget.job;
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    // Staggered morph scale expansion — starts from pin center
    _scale = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Slide up synchronized with map glide
    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.15, 1.0, curve: Curves.fastOutSlowIn),
      ),
    );

    // Fade in
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
      ),
    );

    // Only start if map is already centered (edge case: pre-centered)
    if (widget.job != null && widget.mapCentered) {
      _anim.forward();
    }
  }

  @override
  void didUpdateWidget(covariant MorphicJobBottomSheetWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.job != null) {
      _cachedJob = widget.job;
      // Fire open animation only when map finishes centering
      if (widget.mapCentered && !oldWidget.mapCentered) {
        _anim.forward(from: 0.0);
      } else if (widget.mapCentered && oldWidget.job == null && widget.job != null) {
        _anim.forward(from: 0.0);
      }
    } else {
      _anim.reverse();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedJob == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        if (_anim.isDismissed && widget.job == null) {
          return const SizedBox.shrink();
        }

        return IgnorePointer(
          ignoring: widget.job == null,
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _slide,
              child: ScaleTransition(
                scale: _scale,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
          ),
        );
      },
      child: JobBottomSheet(
        job: _cachedJob!,
        onClose: widget.onClose,
      ),
    );
  }
}
