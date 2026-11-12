import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/reader/presentation/l10n/reading_preference_l10n.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_adaptive_panel.dart';
import 'package:hentai_library/shared/ui/widgets/settings/content_section.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hentai_library/features/reader/domain/auto_play_mode.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab 阅读设置（自适应 bottom / side sheet；不绑 Riverpod / FRB）。
class ReaderSettingsLabState {
  const ReaderSettingsLabState({
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

  ReaderSettingsLabState copyWith({
    bool? autoPlayEnabled,
    String? pagedLayoutLabel,
    AutoPlayMode? autoPlayMode,
    int? autoPlayIntervalSeconds,
  }) {
    return ReaderSettingsLabState(
      autoPlayEnabled: autoPlayEnabled ?? this.autoPlayEnabled,
      pagedLayoutLabel: pagedLayoutLabel ?? this.pagedLayoutLabel,
      autoPlayMode: autoPlayMode ?? this.autoPlayMode,
      autoPlayIntervalSeconds:
          (autoPlayIntervalSeconds ?? this.autoPlayIntervalSeconds).clamp(
            autoPlayIntervalMin,
            autoPlayIntervalMax,
          ),
    );
  }
}

abstract final class ReaderSettingsSideSheet {
  ReaderSettingsSideSheet._();

  static Future<void> show(
    BuildContext context, {
    required ReaderSettingsLabState state,
    required ValueChanged<ReaderSettingsLabState> onStateChanged,
    bool useRootNavigator = false,
  }) {
    final AppLocalizations l10n = context.l10n;
    return ReaderAdaptivePanel.show<void>(
      context,
      title: l10n.readerSettingsTitle,
      useRootNavigator: useRootNavigator,
      body: _ReaderSettingsSideSheetBody(
        initialState: state,
        onStateChanged: onStateChanged,
      ),
    );
  }
}

class _ReaderSettingsSideSheetBody extends StatefulWidget {
  const _ReaderSettingsSideSheetBody({
    required this.initialState,
    required this.onStateChanged,
  });

  final ReaderSettingsLabState initialState;
  final ValueChanged<ReaderSettingsLabState> onStateChanged;

  @override
  State<_ReaderSettingsSideSheetBody> createState() =>
      _ReaderSettingsSideSheetBodyState();
}

class _ReaderSettingsSideSheetBodyState
    extends State<_ReaderSettingsSideSheetBody> {
  late ReaderSettingsLabState _state = widget.initialState;

  void _apply(ReaderSettingsLabState next) {
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
        ContentSection.group(
          title: l10n.readerSettingsGeneral,
          children: <Widget>[
            SettingsSwitchTile(
              leading: Symbols.play_circle,
              title: Text(l10n.readerSettingsAutoPlay),
              value: _state.autoPlayEnabled,
              onChanged: (bool value) =>
                  _apply(_state.copyWith(autoPlayEnabled: value)),
            ),
            SettingsNavigationTile(
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
            SettingsNavigationTile(
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
        ContentSection.group(
          title: l10n.readerSettingsPagedOptions,
          children: <Widget>[
            SettingsNavigationTile(
              leading: Symbols.view_day,
              title: Text(l10n.readerSettingsPageLayout),
              value: Text(_state.pagedLayoutLabel),
              onTap: _handleTogglePagedLayout,
            ),
          ],
        ),
      ],
    );
  }

  void _handleTogglePagedLayout() {
    _apply(
      _state.copyWith(
        pagedLayoutLabel: _state.pagedLayoutLabel == '单页' ? '双页' : '单页',
      ),
    );
  }
}
