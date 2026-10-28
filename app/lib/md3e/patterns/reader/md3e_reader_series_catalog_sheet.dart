import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_adaptive_panel.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_page_preview_data.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_tile.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab 系列目录（生产 [ReaderSeriesMenuButton] 的 M3E 面板版）。
abstract final class Md3eReaderSeriesCatalogSheet {
  Md3eReaderSeriesCatalogSheet._();

  static Future<void> show(
    BuildContext context, {
    required List<Md3eReaderSeriesVolumePreview> volumes,
    required String currentVolumeId,
    required ValueChanged<String> onVolumeSelected,
    bool useRootNavigator = false,
  }) {
    final AppLocalizations l10n = context.l10n;
    return Md3eReaderAdaptivePanel.show<void>(
      context,
      title: l10n.readerSeriesCatalog,
      useRootNavigator: useRootNavigator,
      body: _Md3eReaderSeriesCatalogBody(
        volumes: volumes,
        currentVolumeId: currentVolumeId,
        onVolumeSelected: onVolumeSelected,
      ),
    );
  }
}

class _Md3eReaderSeriesCatalogBody extends StatelessWidget {
  const _Md3eReaderSeriesCatalogBody({
    required this.volumes,
    required this.currentVolumeId,
    required this.onVolumeSelected,
  });

  final List<Md3eReaderSeriesVolumePreview> volumes;
  final String currentVolumeId;
  final ValueChanged<String> onVolumeSelected;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < volumes.length; i++)
          Md3eSettingsNavigationTile(
            leading: Symbols.menu_book,
            title: Text('${i + 1}-${volumes[i].title}'),
            onTap: () {
              onVolumeSelected(volumes[i].id);
              Navigator.of(context).maybePop();
            },
            value: volumes[i].id == currentVolumeId
                ? Icon(
                    Symbols.check,
                    size: 20,
                    color: scheme.primary,
                  )
                : null,
          ),
      ],
    );
  }
}
