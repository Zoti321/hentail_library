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

const MetadataPanelHeightConfig kMetadataPanelHeightDefaultConfig =
    MetadataPanelHeightConfig(
      minHeight: 240,
      maxHeight: 640,
      heightFactor: 0.78,
      headerHeight: 52,
      estimatedRowHeight: 52,
    );

double metadataPanelCardHeight({
  required BoxConstraints constraints,
  required int itemCount,
  MetadataPanelHeightConfig config = kMetadataPanelHeightDefaultConfig,
}) {
  final double maxCardHeight = (constraints.maxHeight * config.heightFactor)
      .clamp(config.minHeight, config.maxHeight)
      .toDouble();
  final double estimatedHeight =
      config.headerHeight + (itemCount * config.estimatedRowHeight);
  return estimatedHeight.clamp(config.minHeight, maxCardHeight).toDouble();
}
