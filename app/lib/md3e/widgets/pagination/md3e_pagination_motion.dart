import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';

/// Motion tokens for [Md3ePagination] (aligned with production page indicator).
abstract final class Md3ePaginationMotion {
  static Duration get pageChangeDuration => Md3eMotion.durationMedium;

  static const Offset compactSummarySlideBegin = Offset(0, 0.18);

  static Curve pageChangeCurve({required bool reduceMotion}) {
    return reduceMotion ? Curves.linear : Md3eMotion.curveEmphasizedDecelerate;
  }

  static Curve pageChangeExitCurve({required bool reduceMotion}) {
    return reduceMotion ? Curves.linear : Md3eMotion.curveEmphasizedAccelerate;
  }

  static Duration motionDuration(BuildContext context) {
    return Md3eMotion.motionDurationOf(context, pageChangeDuration);
  }
}
