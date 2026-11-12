import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_adaptive_panel.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_series_volume.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab 系列目录（生产 [ReaderSeriesMenuButton] 的 M3E 面板版）。
abstract final class ReaderSeriesCatalogSheet {
  ReaderSeriesCatalogSheet._();

  static Future<void> show(
    BuildContext context, {
    required List<ReaderSeriesVolume> volumes,
    required String currentVolumeId,
    required ValueChanged<String> onVolumeSelected,
    bool useRootNavigator = false,
  }) {
    final AppLocalizations l10n = context.l10n;
    return ReaderAdaptivePanel.show<void>(
      context,
      title: l10n.readerSeriesCatalog,
      useRootNavigator: useRootNavigator,
      body: _ReaderSeriesCatalogBody(
        volumes: volumes,
        currentVolumeId: currentVolumeId,
        onVolumeSelected: onVolumeSelected,
      ),
    );
  }
}

class _ReaderSeriesCatalogBody extends StatelessWidget {
  const _ReaderSeriesCatalogBody({
    required this.volumes,
    required this.currentVolumeId,
    required this.onVolumeSelected,
  });

  final List<ReaderSeriesVolume> volumes;
  final String currentVolumeId;
  final ValueChanged<String> onVolumeSelected;

  @override
  Widget build(BuildContext context) {
    final double itemGap = M3ETheme.of(context).menuTheme.itemGap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < volumes.length; i++) ...<Widget>[
          if (i > 0 && itemGap > 0) SizedBox(height: itemGap),
          M3EMenuItem(
            label: '${i + 1}-${volumes[i].title}',
            leading: const Icon(Symbols.menu_book),
            selected: volumes[i].id == currentVolumeId,
            onTap: () => _handleVolumeTap(context, volumes[i].id),
          ),
        ],
      ],
    );
  }

  void _handleVolumeTap(BuildContext context, String id) {
    onVolumeSelected(id);
    Navigator.of(context).maybePop();
  }
}
