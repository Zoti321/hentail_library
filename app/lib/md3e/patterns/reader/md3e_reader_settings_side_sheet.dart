import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_adaptive_panel.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_content_section.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_tile.dart';
import 'package:hentai_library/shared/domain/reading/auto_play_mode.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab 阅读设置（自适应 bottom / side sheet；不绑 Riverpod / FRB）。
class Md3eReaderSettingsLabState {
  const Md3eReaderSettingsLabState({
    this.autoPlayEnabled = false,
    this.pagedLayoutLabel = '单页',
    this.autoPlayMode = AutoPlayMode.comicOnce,
    this.autoPlayIntervalSeconds = 5,
  });

  /// 与生产 `readerAutoPlayIntervalSeconds` 同范围。
  static const int autoPlayIntervalMin = 1;
  static const int autoPlayIntervalMax = 60;

  final bool autoPlayEnabled;
  final String pagedLayoutLabel;
  final AutoPlayMode autoPlayMode;
  final int autoPlayIntervalSeconds;

  Md3eReaderSettingsLabState copyWith({
    bool? autoPlayEnabled,
    String? pagedLayoutLabel,
    AutoPlayMode? autoPlayMode,
    int? autoPlayIntervalSeconds,
  }) {
    return Md3eReaderSettingsLabState(
      autoPlayEnabled: autoPlayEnabled ?? this.autoPlayEnabled,
      pagedLayoutLabel: pagedLayoutLabel ?? this.pagedLayoutLabel,
      autoPlayMode: autoPlayMode ?? this.autoPlayMode,
      autoPlayIntervalSeconds:
          (autoPlayIntervalSeconds ?? this.autoPlayIntervalSeconds)
              .clamp(autoPlayIntervalMin, autoPlayIntervalMax),
    );
  }
}

abstract final class Md3eReaderSettingsSideSheet {
  Md3eReaderSettingsSideSheet._();

  static Future<void> show(
    BuildContext context, {
    required Md3eReaderSettingsLabState state,
    required ValueChanged<Md3eReaderSettingsLabState> onStateChanged,
    bool useRootNavigator = false,
  }) {
    final AppLocalizations l10n = context.l10n;
    return Md3eReaderAdaptivePanel.show<void>(
      context,
      title: l10n.readerSettingsTitle,
      useRootNavigator: useRootNavigator,
      body: _Md3eReaderSettingsSideSheetBody(
        initialState: state,
        onStateChanged: onStateChanged,
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

  /// 与生产 Dialog 的枚举顺序一致，循环切换。
  static AutoPlayMode _nextAutoPlayMode(AutoPlayMode current) {
    final List<AutoPlayMode> modes = AutoPlayMode.values;
    return modes[(modes.indexOf(current) + 1) % modes.length];
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
            Md3eSettingsNavigationTile(
              key: const Key('reader_settings_auto_play_mode'),
              leading: Symbols.repeat,
              title: Text(l10n.readerSettingsAutoPlayMode),
              value: Text(l10n.autoPlayModeLabel(_state.autoPlayMode)),
              onTap: () => _apply(
                _state.copyWith(
                  autoPlayMode: _nextAutoPlayMode(_state.autoPlayMode),
                ),
              ),
            ),
            Md3eSettingsNavigationTile(
              leading: Symbols.timer,
              title: Text(l10n.readerSettingsPlayInterval),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    key: const Key('reader_settings_interval_minus'),
                    icon: const Icon(Symbols.remove),
                    onPressed: () => _apply(
                      _state.copyWith(
                        autoPlayIntervalSeconds:
                            _state.autoPlayIntervalSeconds - 1,
                      ),
                    ),
                  ),
                  Text(
                    '${_state.autoPlayIntervalSeconds} '
                    '${l10n.readerSettingsSecondsSuffix}',
                  ),
                  IconButton(
                    key: const Key('reader_settings_interval_plus'),
                    icon: const Icon(Symbols.add),
                    onPressed: () => _apply(
                      _state.copyWith(
                        autoPlayIntervalSeconds:
                            _state.autoPlayIntervalSeconds + 1,
                      ),
                    ),
                  ),
                ],
              ),
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
