import 'package:flutter/material.dart';

/// Inputs the layout [ResponsiveAppShell] supplies when mounting the sidebar slot.
typedef AppShellSidebarSlot = ({
  String activeNavId,
  bool isExpanded,
  bool showCollapseToggle,
  bool applyDrawerTopInset,
  bool allowLibraryReorder,
  VoidCallback? onLibrariesNavigate,
  VoidCallback onToggleExpanded,
  ValueChanged<String> onDestinationSelected,
});

/// Pluggable sidebar implementation (feature composition injects a concrete widget).
typedef AppShellSidebarBuilder = Widget Function(AppShellSidebarSlot slot);
