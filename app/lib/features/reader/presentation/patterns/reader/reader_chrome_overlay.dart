import 'package:flutter/material.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_chrome_reveal.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_chrome_scope.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'reader_chrome_reveal.dart';

/// 顶/底 chrome 的显隐与 safe-area 定位（全宽 scrim，非浮岛）。
class ReaderChromeOverlay extends StatelessWidget {
  const ReaderChromeOverlay({
    super.key,
    required this.visible,
    required this.topBar,
    required this.bottomBar,
  });

  final bool visible;
  final Widget topBar;
  final Widget bottomBar;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return ReaderChromeScope(
      onChrome: ReaderImmersiveColors.onChrome(scheme),
      onChromeVariant: ReaderImmersiveColors.onChromeVariant(scheme),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: ReaderChromeReveal(
              visible: visible,
              top: true,
              child: topBar,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ReaderChromeReveal(
              visible: visible,
              top: false,
              child: bottomBar,
            ),
          ),
        ],
      ),
    );
  }
}
