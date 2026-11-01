import 'package:flutter/animation.dart';
import 'package:motor/motor.dart';

/// 把 motor 的 [Motion]（弹簧）按给定时长采样成 [Curve]。
///
/// 进度 `t`（0..1）换算为秒后取弹簧位置，因此弹簧的回弹在整个时长内完成，
/// 而不是被压缩到 1 秒内。
class Md3eSpringCurve extends Curve {
  Md3eSpringCurve({required Motion motion, required Duration duration})
    : _simulation = motion.createSimulation(),
      _seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;

  final Simulation _simulation;
  final double _seconds;

  @override
  double transform(double t) => _simulation.x(t * _seconds);
}
