import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_bottom_bar.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_overlay.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_top_bar.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 顶/底 chrome 组合（overlay + bars）。显隐由外层驱动；滚动隐藏待接视口后改用 [M3EAppBarController]。
class Md3eReaderChrome extends StatelessWidget {
  const Md3eReaderChrome({
    super.key,
    required this.visible,
    required this.title,
    required this.currentPage,
    required this.totalPages,
    this.subtitle,
    this.isFullscreen = false,
    this.autoPlayEnabled = false,
    this.onBack,
    this.onOpenSettings,
    this.onToggleFullscreen,
    this.onOpenSeriesCatalog,
    this.onPageChanged,
    this.onPreviousPage,
    this.onNextPage,
    this.onAutoPlayChanged,
    this.moreMenuEntries = const <M3EMenuNode>[],
  });

  final bool visible;
  final String title;
  final String? subtitle;
  final int currentPage;
  final int totalPages;
  final bool isFullscreen;
  final bool autoPlayEnabled;
  final VoidCallback? onBack;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onOpenSeriesCatalog;
  final ValueChanged<int>? onPageChanged;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<bool>? onAutoPlayChanged;
  final List<M3EMenuNode> moreMenuEntries;

  @override
  Widget build(BuildContext context) {
    return Md3eReaderChromeOverlay(
      visible: visible,
      topBar: Md3eReaderTopBar(
        title: title,
        subtitle: subtitle,
        onBack: onBack,
        onOpenSettings: onOpenSettings,
        onToggleFullscreen: onToggleFullscreen,
        onOpenSeriesCatalog: onOpenSeriesCatalog,
        isFullscreen: isFullscreen,
        moreMenuEntries: moreMenuEntries,
      ),
      bottomBar: Md3eReaderBottomBar(
        currentPage: currentPage,
        totalPages: totalPages,
        onPageChanged: onPageChanged ?? (_) {},
        onPreviousPage: onPreviousPage,
        onNextPage: onNextPage,
        autoPlayEnabled: autoPlayEnabled,
        onAutoPlayChanged: onAutoPlayChanged,
      ),
    );
  }
}
