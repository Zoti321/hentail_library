import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_value.dart';

/// Height of catalog cover read-progress strips (card + list leading).
const double kMd3eCoverReadProgressHeight = 2;

/// Whether a read-progress strip should be shown for [readProgress].
bool md3eShowsReadProgressStrip(double? readProgress) {
  return readProgress != null && readProgress > 0;
}

/// Animated full-width progress strip for catalog cover thumbnails.
class Md3eCoverReadProgressStrip extends StatelessWidget {
  const Md3eCoverReadProgressStrip({
    super.key,
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  final double progress;
  final Color activeColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '阅读进度 ${(progress.clamp(0.0, 1.0) * 100).round()}%',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double maxWidth = constraints.maxWidth;
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ColoredBox(color: trackColor),
              Md3eSpringValue(
                value: progress.clamp(0.0, 1.0),
                builder: (BuildContext context, double value) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: maxWidth * value,
                      height: kMd3eCoverReadProgressHeight,
                      child: ColoredBox(color: activeColor),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
