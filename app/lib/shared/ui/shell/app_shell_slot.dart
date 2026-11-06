import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/shell/shell_navigation.dart';

/// Production-controlled inputs for [DesktopShell] (built in features layer).
typedef AppShellNavigationSlot = ({
  List<ShellRailDestination> railDestinations,
  List<HomeLibraryDashboardRow> libraries,
  String selectedNavId,
  String selectedLibraryId,
  ValueChanged<String> onNavIdSelected,
  ValueChanged<String> onLibrarySelected,
  DesktopShellSurfaceRoles? surfaceRoles,
});

typedef AppShellNavigationSlotBuilder = AppShellNavigationSlot Function(
  BuildContext context,
);
