import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/md3e/pages/md3e_reader_page.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_page_preview_data.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_series_catalog_sheet.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_settings_side_sheet.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_tap_zone.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列边界提示方向（与生产 `SeriesBoundaryPrompt` 语义一致，Lab 不依赖 read_session）。
enum _SeriesBoundaryPrompt { none, advance, retreat }

/// Widgetbook / Lab：本地维护页码与 chrome 显隐。
class Md3eReaderPageLabHost extends StatefulWidget {
  const Md3eReaderPageLabHost({
    super.key,
    this.preview = const Md3eReaderPagePreviewData(
      title: '第 01 卷',
      subtitle: '葬送的芙莉莲',
      totalPages: 24,
      initialPage: 3,
    ),
    this.onBack,
    this.useRootNavigator = false,
  });

  final Md3eReaderPagePreviewData preview;
  final VoidCallback? onBack;

  /// Widgetbook 预览区宜为 `false`，避免 sheet 挂到整窗 overlay。
  final bool useRootNavigator;

  @override
  State<Md3eReaderPageLabHost> createState() => _Md3eReaderPageLabHostState();
}

class _Md3eReaderPageLabHostState extends State<Md3eReaderPageLabHost> {
  static const Duration _boundaryMessageDuration = Duration(seconds: 4);

  late int _page = widget.preview.initialPage;
  late String _volumeId = widget.preview.currentVolumeId;
  late String _volumeTitle = widget.preview.title;
  _SeriesBoundaryPrompt _boundaryPrompt = _SeriesBoundaryPrompt.none;
  String? _boundaryMessage;
  Timer? _boundaryMessageTimer;
  bool _chromeVisible = true;
  bool _fullscreen = false;
  late Md3eReaderSettingsLabState _settings = Md3eReaderSettingsLabState(
    autoPlayEnabled: false,
  );

  @override
  void dispose() {
    _boundaryMessageTimer?.cancel();
    super.dispose();
  }

  int get _total =>
      widget.preview.totalPages < 1 ? 1 : widget.preview.totalPages;

  /// 边界提示挂在阅读页自身的 Stack 内（不用根 Overlay），仅在本画布上显示。
  void _showBoundaryMessage(String message) {
    _boundaryMessageTimer?.cancel();
    setState(() => _boundaryMessage = message);
    _boundaryMessageTimer = Timer(
      _boundaryMessageDuration,
      _dismissBoundaryMessage,
    );
  }

  void _dismissBoundaryMessage() {
    _boundaryMessageTimer?.cancel();
    _boundaryMessageTimer = null;
    if (_boundaryMessage == null || !mounted) {
      return;
    }
    setState(() => _boundaryMessage = null);
  }

  int get _volumeIndex => widget.preview.seriesVolumes.indexWhere(
    (Md3eReaderSeriesVolumePreview volume) => volume.id == _volumeId,
  );

  void _setPage(int page) {
    final bool hadPrompt = _boundaryPrompt != _SeriesBoundaryPrompt.none;
    setState(() {
      _page = page.clamp(1, _total);
      _boundaryPrompt = _SeriesBoundaryPrompt.none;
    });
    if (hadPrompt) {
      _dismissBoundaryMessage();
    }
  }

  /// 逐页翻页；越过本卷首/末页时进入边界确认（同卷内两次翻页才跨卷）。
  void _stepPage(int delta) {
    final int target = _page + delta;
    if (target >= 1 && target <= _total) {
      _setPage(target);
      return;
    }
    _requestSeriesBoundary(
      delta > 0 ? _SeriesBoundaryPrompt.advance : _SeriesBoundaryPrompt.retreat,
    );
  }

  void _requestSeriesBoundary(_SeriesBoundaryPrompt direction) {
    final List<Md3eReaderSeriesVolumePreview> volumes =
        widget.preview.seriesVolumes;
    final int current = _volumeIndex;
    final int neighbor =
        current + (direction == _SeriesBoundaryPrompt.advance ? 1 : -1);
    // 无相邻卷（或当前卷不在系列内）时保持原地，不提示。
    if (current < 0 || neighbor < 0 || neighbor >= volumes.length) {
      return;
    }

    if (_boundaryPrompt != direction) {
      setState(() => _boundaryPrompt = direction);
      final AppLocalizations l10n = context.l10n;
      final String message = switch (direction) {
        _SeriesBoundaryPrompt.advance => l10n.readerSeriesAdvancePrompt,
        _SeriesBoundaryPrompt.retreat => l10n.readerSeriesRetreatPrompt,
        _SeriesBoundaryPrompt.none => '',
      };
      _showBoundaryMessage(message);
      return;
    }

    final Md3eReaderSeriesVolumePreview target = volumes[neighbor];
    setState(() {
      _volumeId = target.id;
      _volumeTitle = target.title;
      _page = 1;
      _boundaryPrompt = _SeriesBoundaryPrompt.none;
    });
    _dismissBoundaryMessage();
  }

  void _handleTapZone(Md3eReaderTapZone zone) {
    if (_chromeVisible) {
      setState(() => _chromeVisible = false);
      return;
    }
    switch (zone) {
      case Md3eReaderTapZone.left:
        _stepPage(-1);
      case Md3eReaderTapZone.right:
        _stepPage(1);
      case Md3eReaderTapZone.center:
        setState(() => _chromeVisible = true);
    }
  }

  void _toggleChromeFromKeyboard() {
    setState(() => _chromeVisible = !_chromeVisible);
  }

  Future<void> _openSettings() async {
    await Md3eReaderSettingsSideSheet.show(
      context,
      state: _settings,
      useRootNavigator: widget.useRootNavigator,
      onStateChanged: (Md3eReaderSettingsLabState next) {
        setState(() {
          _settings = next;
        });
      },
    );
  }

  Future<void> _openSeriesCatalog() async {
    if (widget.preview.seriesVolumes.isEmpty) {
      return;
    }
    await Md3eReaderSeriesCatalogSheet.show(
      context,
      volumes: widget.preview.seriesVolumes,
      currentVolumeId: _volumeId,
      useRootNavigator: widget.useRootNavigator,
      onVolumeSelected: (String id) {
        for (final Md3eReaderSeriesVolumePreview volume
            in widget.preview.seriesVolumes) {
          if (volume.id != id) {
            continue;
          }
          setState(() {
            _volumeId = volume.id;
            _volumeTitle = volume.title;
            _page = 1;
            _boundaryPrompt = _SeriesBoundaryPrompt.none;
          });
          return;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? boundaryMessage = _boundaryMessage;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Md3eReaderPage(
          title: _volumeTitle,
          subtitle: widget.preview.subtitle,
          currentPage: _page,
          totalPages: _total,
          chromeVisible: _chromeVisible,
          isFullscreen: _fullscreen,
          autoPlayEnabled: _settings.autoPlayEnabled,
          onTapZone: _handleTapZone,
          onToggleChromeFromKeyboard: _toggleChromeFromKeyboard,
          onBack: widget.onBack,
          onOpenSettings: _openSettings,
          onOpenSeriesCatalog: widget.preview.seriesVolumes.isEmpty
              ? null
              : _openSeriesCatalog,
          onToggleFullscreen: () => setState(() => _fullscreen = !_fullscreen),
          onPageChanged: _setPage,
          onPreviousPage: () => _stepPage(-1),
          onNextPage: () => _stepPage(1),
          onAutoPlayChanged: (bool value) {
            setState(
              () => _settings = _settings.copyWith(autoPlayEnabled: value),
            );
          },
          moreMenuEntries: const <M3EMenuNode>[
            M3EMenuEntry(label: 'Lab · 查看封面'),
            M3EMenuEntry(label: 'Lab · 分享'),
          ],
        ),
        if (boundaryMessage != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: IgnorePointer(
              child: Center(
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: kMd3eAppFontFamily),
                  child: M3EComponentTheme(
                    builder: (BuildContext context) =>
                        M3ESnackbar(message: boundaryMessage),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
