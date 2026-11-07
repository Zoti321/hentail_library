import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:widgetbook/widgetbook.dart';

/// M3 five-tier [ViewportAddon] presets for Widgetbook (whole catalog).
List<ViewportData> buildMd3eWidgetbookViewports() {
  return <ViewportData>[
    ViewportData(
      name: 'Compact (<600dp)',
      width: Breakpoints.previewWidthCompact,
      height: 844,
      pixelRatio: 1,
      platform: TargetPlatform.android,
    ),
    ViewportData(
      name: 'Medium (600–839dp)',
      width: Breakpoints.previewWidthMedium,
      height: 900,
      pixelRatio: 1,
      platform: TargetPlatform.android,
    ),
    ViewportData(
      name: 'Expanded (840–1199dp)',
      width: Breakpoints.previewWidthExpanded,
      height: 800,
      pixelRatio: 1,
      platform: TargetPlatform.windows,
    ),
    ViewportData(
      name: 'Large (1200–1599dp)',
      width: Breakpoints.previewWidthLarge,
      height: 900,
      pixelRatio: 1,
      platform: TargetPlatform.windows,
    ),
    ViewportData(
      name: 'Extra large (≥1600dp)',
      width: Breakpoints.previewWidthExtraLarge,
      height: 900,
      pixelRatio: 1,
      platform: TargetPlatform.windows,
    ),
  ];
}
