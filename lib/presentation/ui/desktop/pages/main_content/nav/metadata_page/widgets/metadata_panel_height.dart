import 'package:flutter/material.dart';

class MetadataPanelHeightConfig {
  const MetadataPanelHeightConfig({
    required this.minHeight,
    required this.maxHeight,
    required this.heightFactor,
    required this.headerHeight,
    required this.estimatedRowHeight,
  });
  final double minHeight;
  final double maxHeight;
  final double heightFactor;
  final double headerHeight;
  final double estimatedRowHeight;
}

class MetadataPanelHeightCalculator {
  const MetadataPanelHeightCalculator._();
  static const MetadataPanelHeightConfig defaultConfig = MetadataPanelHeightConfig(
    minHeight: 240,
    maxHeight: 640,
    heightFactor: 0.78,
    headerHeight: 52,
    estimatedRowHeight: 52,
  );
  static double calculateCardHeight({
    required BoxConstraints constraints,
    required int itemCount,
    required MetadataPanelHeightConfig config,
  }) {
    final double maxCardHeight = (constraints.maxHeight * config.heightFactor)
        .clamp(config.minHeight, config.maxHeight)
        .toDouble();
    final double estimatedHeight =
        config.headerHeight + (itemCount * config.estimatedRowHeight);
    return estimatedHeight.clamp(config.minHeight, maxCardHeight).toDouble();
  }
}
