import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/shell/shell_navigation.dart';

/// Production-controlled inputs for [Md3eDesktopShell] (built in features layer).
typedef Md3eAppShellNavigationSlot = ({
  List<Md3eShellRailDestination> railDestinations,
  List<Md3eHomeLibraryDashboardRow> libraries,
  String selectedNavId,
  String selectedLibraryId,
  ValueChanged<String> onNavIdSelected,
  ValueChanged<String> onLibrarySelected,
  Md3eDesktopShellSurfaceRoles? surfaceRoles,
});

typedef Md3eAppShellNavigationSlotBuilder = Md3eAppShellNavigationSlot Function(
  BuildContext context,
);
