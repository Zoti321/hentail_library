import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/foundation/toggle_switch.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_expand_by_series_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_filter_sort_drawer.dart';

/// Comics Tab：Expand by series 开关（排序区顶部）。
class LibraryExpandBySeriesControls extends ConsumerWidget {
  const LibraryExpandBySeriesControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final AppLocalizations l10n = context.l10n;
    final bool enabled = ref.watch(libraryComicsTabExpandBySeriesProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(libraryExpandBySeriesProvider.notifier).setEnabled(!enabled);
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
                  l10n.libraryExpandBySeries,
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
