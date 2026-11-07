import 'package:flutter/material.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_chrome_scope.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_page_copy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 阅读器底栏：页码 + [M3ESlider]（Lab 拆分组件）。
class ReaderPageProgress extends StatefulWidget {
  const ReaderPageProgress({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  State<ReaderPageProgress> createState() => _ReaderPageProgressState();
}

class _ReaderPageProgressState extends State<ReaderPageProgress> {
  double? _dragValue;

  int get _safeTotal => widget.totalPages < 1 ? 1 : widget.totalPages;

  int get _displayPage => (_dragValue ?? widget.currentPage.toDouble())
      .round()
      .clamp(1, _safeTotal);

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final ReaderChromeScope? chrome = ReaderChromeScope.maybeOf(context);
    final Color pageNumberColor = chrome?.onChrome ?? scheme.onSurface;
    final TextStyle pageNumberStyle = type.labelLarge.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      color: pageNumberColor,
    );
    final double sliderValue = (_dragValue ?? widget.currentPage.toDouble())
        .clamp(1.0, _safeTotal.toDouble());

    return Semantics(
      label: ReaderPageCopy.pageProgressLabel(_displayPage, _safeTotal),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 40,
            child: Text('$_displayPage', style: pageNumberStyle),
          ),
          Expanded(
            child: M3ESlider(
              value: sliderValue,
              min: 1,
              max: _safeTotal.toDouble(),
              size: M3ESliderSize.xs,
              haptic: M3EHapticFeedback.light,
              semanticFormatterCallback: (double value) =>
                  ReaderPageCopy.pageProgressLabel(
                    value.round().clamp(1, _safeTotal),
                    _safeTotal,
                  ),
              onChanged: (double value) => setState(() => _dragValue = value),
              onChangeEnd: (double value) {
                // M3ESlider 在 TapUp/微拖结束时可能仍传受控的旧 widget.value；
                // 优先用 onChanged 已写入的 _dragValue，否则桌面点轨不会落页。
                final double resolved = _dragValue ?? value;
                setState(() => _dragValue = null);
                widget.onPageChanged(
                  resolved.round().clamp(1, _safeTotal),
                );
              },
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$_safeTotal',
              textAlign: TextAlign.end,
              style: pageNumberStyle,
            ),
          ),
        ],
      ),
    );
  }
}
