import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/pages/md3e_reader_page.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_page_preview_data.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_settings_side_sheet.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_tap_zone.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

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
  });

  final Md3eReaderPagePreviewData preview;
  final VoidCallback? onBack;

  @override
  State<Md3eReaderPageLabHost> createState() => _Md3eReaderPageLabHostState();
}

class _Md3eReaderPageLabHostState extends State<Md3eReaderPageLabHost> {
  late int _page = widget.preview.initialPage;
  bool _chromeVisible = true;
  bool _fullscreen = false;
  late Md3eReaderSettingsLabState _settings = Md3eReaderSettingsLabState(
    autoPlayEnabled: false,
  );

  int get _total =>
      widget.preview.totalPages < 1 ? 1 : widget.preview.totalPages;

  void _setPage(int page) {
    setState(() => _page = page.clamp(1, _total));
  }

  void _handleTapZone(Md3eReaderTapZone zone) {
    if (_chromeVisible) {
      setState(() => _chromeVisible = false);
      return;
    }
    switch (zone) {
      case Md3eReaderTapZone.left:
        _setPage(_page - 1);
      case Md3eReaderTapZone.right:
        _setPage(_page + 1);
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
      onStateChanged: (Md3eReaderSettingsLabState next) {
        setState(() {
          _settings = next;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Md3eReaderPage(
      title: widget.preview.title,
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
      onToggleFullscreen: () => setState(() => _fullscreen = !_fullscreen),
      onPageChanged: _setPage,
      onPreviousPage: () => _setPage(_page - 1),
      onNextPage: () => _setPage(_page + 1),
      onAutoPlayChanged: (bool value) {
        setState(() => _settings = _settings.copyWith(autoPlayEnabled: value));
      },
      moreMenuEntries: const <M3EMenuNode>[
        M3EMenuEntry(label: 'Lab · 分享'),
      ],
    );
  }
}
