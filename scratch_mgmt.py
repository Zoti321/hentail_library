import io

base = 'lib/features/library_admin/presentation/views/home_library_dashboard/patterns/'
p = base + 'home_library_management_section.dart'
s = io.open(p, encoding='utf-8').read()

tile_start = s.index('/// 库列表的一行，与设置页 [SettingsTileShell] 同款')
menu_start = s.index('class HomeLibraryRowMoreMenu extends StatelessWidget {')
tile_block = s[tile_start:menu_start].rstrip() + '\n'
menu_block = s[menu_start:].rstrip() + '\n'

s = s[:tile_start].rstrip() + '\n'

# inline _buildLibraryTile usages, then drop the helper
s = s.replace(
    """            itemBuilder: (BuildContext context, int index) =>
                _buildLibraryTile(libraries[index]),""",
    """            itemBuilder: (BuildContext context, int index) =>
                _libraryTileFor(libraries[index]),""",
)
s = s.replace(
    """              for (final HomeLibraryDashboardRow row in libraries)
                _buildLibraryTile(row),""",
    """              for (final HomeLibraryDashboardRow row in libraries)
                _libraryTileFor(row),""",
)
i = s.index('  Widget _buildLibraryTile(HomeLibraryDashboardRow row) {')
j = s.index('\n\n', s.index('  }', s.index('    );', i))) + 2
s = s[:i] + s[j:]

s = s.replace(
    "import 'home_library_row_presentation.dart';",
    """import 'home_library_dashboard_tile.dart';
import 'home_library_row_presentation.dart';

export 'home_library_dashboard_tile.dart';
export 'home_library_row_more_menu.dart';""",
)

tile_file = """import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import 'home_library_row_more_menu.dart';
import 'home_library_row_presentation.dart';

""" + tile_block
io.open(base + 'home_library_dashboard_tile.dart', 'w', encoding='utf-8', newline='\n').write(tile_file)

menu_file = """import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

""" + menu_block
io.open(base + 'home_library_row_more_menu.dart', 'w', encoding='utf-8', newline='\n').write(menu_file)

# the callbacks: extract _libraryTileFor as a widget? avoid-returning-widgets forbids it.
# Instead build tiles inline via a helper widget: replace with HomeLibraryDashboardTile(...)
s = s.replace(
    """            itemBuilder: (BuildContext context, int index) =>
                _libraryTileFor(libraries[index]),""",
    """            itemBuilder: (BuildContext context, int index) =>
                HomeLibraryDashboardTile(
                  row: libraries[index],
                  onOpen: _openFor(libraries[index].libraryId),
                  onAction: _actionFor(libraries[index].libraryId),
                ),""",
)
s = s.replace(
    """              for (final HomeLibraryDashboardRow row in libraries)
                _libraryTileFor(row),""",
    """              for (final HomeLibraryDashboardRow row in libraries)
                HomeLibraryDashboardTile(
                  row: row,
                  onOpen: _openFor(row.libraryId),
                  onAction: _actionFor(row.libraryId),
                ),""",
)
i = s.index('  @override\n  Widget build(BuildContext context) {')
s = s[:i] + """  VoidCallback? _openFor(String libraryId) {
    final ValueChanged<String>? onLibraryOpen = this.onLibraryOpen;
    return onLibraryOpen == null ? null : () => onLibraryOpen(libraryId);
  }

  ValueChanged<HomeLibraryManagementAction>? _actionFor(String libraryId) {
    final void Function(String, HomeLibraryManagementAction)? onLibraryAction =
        this.onLibraryAction;
    return onLibraryAction == null
        ? null
        : (HomeLibraryManagementAction action) =>
              onLibraryAction(libraryId, action);
  }

""" + s[i:]

io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('ok')
