import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:widgetbook/widgetbook.dart';

/// M3 five-tier [ViewportAddon] presets for Widgetbook (whole catalog).
List<ViewportData> buildMd3eWidgetbookViewports() {
  return <ViewportData>[
    ViewportData(
      name: 'Compact (<600dp)',
      width: Md3eBreakpoints.previewWidthCompact,
      height: 844,
      pixelRatio: 1,
      platform: TargetPlatform.android,
    ),
    ViewportData(
      name: 'Medium (600–839dp)',
      width: Md3eBreakpoints.previewWidthMedium,
      height: 900,
      pixelRatio: 1,
      platform: TargetPlatform.android,
    ),
    ViewportData(
      name: 'Expanded (840–1199dp)',
      width: Md3eBreakpoints.previewWidthExpanded,
      height: 800,
      pixelRatio: 1,
      platform: TargetPlatform.windows,
    ),
    ViewportData(
      name: 'Large (1200–1599dp)',
      width: Md3eBreakpoints.previewWidthLarge,
      height: 900,
      pixelRatio: 1,
      platform: TargetPlatform.windows,
    ),
    ViewportData(
      name: 'Extra large (≥1600dp)',
      width: Md3eBreakpoints.previewWidthExtraLarge,
      height: 900,
      pixelRatio: 1,
      platform: TargetPlatform.windows,
    ),
  ];
}
