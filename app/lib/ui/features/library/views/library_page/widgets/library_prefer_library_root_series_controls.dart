import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/foundation/toggle_switch.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_prefer_library_root_series_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_filter_sort_drawer.dart';

/// Series Tab：Prefer library root series 开关（排序区附近）。
class LibraryPreferLibraryRootSeriesControls extends ConsumerWidget {
  const LibraryPreferLibraryRootSeriesControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.series) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final AppLocalizations l10n = context.l10n;
    final bool enabled = ref.watch(
      librarySeriesTabPreferLibraryRootSeriesProvider,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref
              .read(libraryPreferLibraryRootSeriesProvider.notifier)
              .setEnabled(!enabled);
        },
        hoverColor: theme.hoverColor,
        splashColor: theme.splashColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            kLibraryFilterSortDrawerContentInset,
            10,
            kLibraryFilterSortDrawerContentInset,
            10,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.libraryPreferLibraryRootSeries,
                  style: TextStyle(
                    fontSize: tokens.text.bodySm,
                    fontWeight: FontWeight.w500,
                    color: cs.hentai.textPrimary,
                  ),
                ),
              ),
              IgnorePointer(child: ToggleSwitch(checked: enabled)),
            ],
          ),
        ),
      ),
    );
  }
}
