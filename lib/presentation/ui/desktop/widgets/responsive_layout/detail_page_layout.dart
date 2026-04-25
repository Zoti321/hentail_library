import 'dart:math' as math;

import 'package:flutter/material.dart';

class DetailPanelSize {
  const DetailPanelSize({
    required this.targetWidth,
    required this.targetHeight,
    required this.panelWidth,
    required this.panelHeight,
  });

  final double targetWidth;
  final double targetHeight;
  final double panelWidth;
  final double panelHeight;
}

class DetailResponsiveLayout extends StatelessWidget {
  const DetailResponsiveLayout({
    super.key,
    required this.header,
    required this.headerSpacing,
    required this.bodyBuilder,
  });
  static const double _kContentWidthRatio = 0.8;
  static const double _kContentHeightRatio = 0.8;
  static const double _kContentMinWidth = 980;
  static const double _kContentMaxWidth = 1320;
  static const double _kContentMinHeight = 560;
  static const double _kContentMaxHeight = 920;

  final Widget header;
  final double headerSpacing;
  final Widget Function(BuildContext context, DetailPanelSize panel) bodyBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size mediaSize = MediaQuery.sizeOf(context);
        final double parentWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mediaSize.width;
        final double parentHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mediaSize.height;
        final double targetWidth = (parentWidth * _kContentWidthRatio)
            .clamp(_kContentMinWidth, _kContentMaxWidth)
            .toDouble();
        final double targetHeight = (parentHeight * _kContentHeightRatio)
            .clamp(_kContentMinHeight, _kContentMaxHeight)
            .toDouble();
        final DetailPanelSize panel = DetailPanelSize(
          targetWidth: targetWidth,
          targetHeight: targetHeight,
          panelWidth: math.min(parentWidth, targetWidth),
          panelHeight: math.min(parentHeight, targetHeight),
        );
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: panel.panelWidth,
            height: panel.panelHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                SizedBox(height: headerSpacing),
                Expanded(child: bodyBuilder(context, panel)),
              ],
            ),
          ),
        );
      },
    );
  }
}
