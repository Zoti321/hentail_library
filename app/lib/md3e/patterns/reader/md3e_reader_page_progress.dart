import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_chrome_scope.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_page_copy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 阅读器底栏：页码 + [M3ESlider]（Lab 拆分组件）。
class Md3eReaderPageProgress extends StatefulWidget {
  const Md3eReaderPageProgress({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  State<Md3eReaderPageProgress> createState() => _Md3eReaderPageProgressState();
}

class _Md3eReaderPageProgressState extends State<Md3eReaderPageProgress> {
  double? _dragValue;

  int get _safeTotal => widget.totalPages < 1 ? 1 : widget.totalPages;

  int get _displayPage =>
      (_dragValue ?? widget.currentPage.toDouble()).round().clamp(1, _safeTotal);

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final Md3eReaderChromeScope? chrome = Md3eReaderChromeScope.maybeOf(context);
    final Color pageNumberColor = chrome?.onChrome ?? scheme.onSurface;
    final TextStyle pageNumberStyle = type.labelLarge.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      color: pageNumberColor,
    );
    final double sliderValue =
        (_dragValue ?? widget.currentPage.toDouble())
            .clamp(1.0, _safeTotal.toDouble());

    return Semantics(
      label: Md3eReaderPageCopy.pageProgressLabel(_displayPage, _safeTotal),
      child: Row(
        children: <Widget>[
        SizedBox(
          width: 40,
          child: Text(
            '$_displayPage',
            style: pageNumberStyle,
          ),
        ),
        Expanded(
          child: M3ESlider(
            value: sliderValue,
            min: 1,
            max: _safeTotal.toDouble(),
            size: M3ESliderSize.xs,
            onChanged: (double value) => setState(() => _dragValue = value),
            onChangeEnd: (double value) {
              setState(() => _dragValue = null);
              widget.onPageChanged(value.round());
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
