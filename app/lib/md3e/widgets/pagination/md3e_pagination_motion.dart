import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';

/// Motion tokens for [Md3ePagination] selection indicator & compact layout.
abstract final class Md3ePaginationMotion {
  static Duration get pageChangeDuration => Md3eMotion.durationShort;

  static Duration motionDuration(BuildContext context) {
    return Md3eMotion.motionDurationOf(context, pageChangeDuration);
  }
}
