import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_content_section.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_tile.dart';
import 'package:hentai_library/md3e/widgets/sheets/md3e_overlay_route_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab 阅读设置（[M3ESideSheet]；不绑 Riverpod / FRB）。
class Md3eReaderSettingsLabState {
  const Md3eReaderSettingsLabState({
    this.autoPlayEnabled = false,
    this.pagedLayoutLabel = '单页',
  });

  final bool autoPlayEnabled;
  final String pagedLayoutLabel;

  Md3eReaderSettingsLabState copyWith({
    bool? autoPlayEnabled,
    String? pagedLayoutLabel,
  }) {
    return Md3eReaderSettingsLabState(
      autoPlayEnabled: autoPlayEnabled ?? this.autoPlayEnabled,
      pagedLayoutLabel: pagedLayoutLabel ?? this.pagedLayoutLabel,
    );
  }
}

abstract final class Md3eReaderSettingsSideSheet {
  Md3eReaderSettingsSideSheet._();

  static const double _width = 400;

  static M3ESideSheetTheme _sheetTheme(BuildContext context) {
    final M3EThemeData m3e = M3ETheme.of(context);
    return m3e.sideSheetTheme.copyWith(
      horizontalPadding: 16,
      topElementsGap: 8,
    );
  }

  static Future<void> show(
    BuildContext context, {
    required Md3eReaderSettingsLabState state,
    required ValueChanged<Md3eReaderSettingsLabState> onStateChanged,
    bool useRootNavigator = true,
  }) {
    final AppLocalizations l10n = context.l10n;
    return M3ESideSheet.show<void>(
      context,
      title: l10n.readerSettingsTitle,
      width: _width,
      detached: MediaQuery.sizeOf(context).width >= 840,
      theme: _sheetTheme(context),
      scrollable: true,
      useRootNavigator: useRootNavigator,
      body: md3eOverlayRouteScope(
        anchorContext: context,
        child: _Md3eReaderSettingsSideSheetBody(
          initialState: state,
          onStateChanged: onStateChanged,
        ),
      ),
    );
  }
}

class _Md3eReaderSettingsSideSheetBody extends StatefulWidget {
  const _Md3eReaderSettingsSideSheetBody({
    required this.initialState,
    required this.onStateChanged,
  });

  final Md3eReaderSettingsLabState initialState;
  final ValueChanged<Md3eReaderSettingsLabState> onStateChanged;

  @override
  State<_Md3eReaderSettingsSideSheetBody> createState() =>
      _Md3eReaderSettingsSideSheetBodyState();
}

class _Md3eReaderSettingsSideSheetBodyState
    extends State<_Md3eReaderSettingsSideSheetBody> {
  late Md3eReaderSettingsLabState _state = widget.initialState;

  void _apply(Md3eReaderSettingsLabState next) {
    setState(() => _state = next);
    widget.onStateChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Md3eContentSection.group(
          title: l10n.readerSettingsGeneral,
          children: <Widget>[
            Md3eSettingsSwitchTile(
              leading: Symbols.play_circle,
              title: Text(l10n.readerSettingsAutoPlay),
              value: _state.autoPlayEnabled,
              onChanged: (bool value) =>
                  _apply(_state.copyWith(autoPlayEnabled: value)),
            ),
          ],
        ),
        Md3eContentSection.group(
          title: l10n.readerSettingsPagedOptions,
          children: <Widget>[
            Md3eSettingsNavigationTile(
              leading: Symbols.view_day,
              title: Text(l10n.readerSettingsPageLayout),
              value: Text(_state.pagedLayoutLabel),
              onTap: () {
                _apply(
                  _state.copyWith(
                    pagedLayoutLabel: _state.pagedLayoutLabel == '单页'
                        ? '双页'
                        : '单页',
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
