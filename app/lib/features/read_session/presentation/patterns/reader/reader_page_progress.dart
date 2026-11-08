import 'package:flutter/material.dart';
import 'package:hentai_library/features/read_session/domain/auto_play_interval.dart';
import 'package:hentai_library/shared/ui/layout/reader_chrome_metrics.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_chrome_scope.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_page_copy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 阅读器底栏：页码 + [M3ESlider]（Lab 拆分组件）。
///
/// 自动翻页开启时切换为 [M3ESlider.wavy]，波长随间隔变化。
class ReaderPageProgress extends StatefulWidget {
  const ReaderPageProgress({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.autoPlayEnabled = false,
    this.autoPlayIntervalSeconds = kReaderAutoPlayIntervalDefault,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final bool autoPlayEnabled;
  final int autoPlayIntervalSeconds;

  @override
  State<ReaderPageProgress> createState() => _ReaderPageProgressState();
}

class _ReaderPageProgressState extends State<ReaderPageProgress> {
  double? _dragValue;

  int get _safeTotal => widget.totalPages < 1 ? 1 : widget.totalPages;

  int get _displayPage => (_dragValue ?? widget.currentPage.toDouble())
      .round()
      .clamp(1, _safeTotal);

  void _onChanged(double value) => setState(() => _dragValue = value);

  void _onChangeEnd(double value) {
    // M3ESlider 在 TapUp/微拖结束时可能仍传受控的旧 widget.value；
    // 优先用 onChanged 已写入的 _dragValue，否则桌面点轨不会落页。
    final double resolved = _dragValue ?? value;
    setState(() => _dragValue = null);
    widget.onPageChanged(resolved.round().clamp(1, _safeTotal));
  }

  Widget _buildProgressSlider({
    required double sliderValue,
    required double viewportWidth,
  }) {
    final double? trackThickness =
        ReaderChromeMetrics.progressSliderTrackThicknessOf(viewportWidth);
    final double? thumbLength =
        ReaderChromeMetrics.progressSliderThumbLengthOf(viewportWidth);
    String semanticLabel(double value) => ReaderPageCopy.pageProgressLabel(
      value.round().clamp(1, _safeTotal),
      _safeTotal,
    );

    if (widget.autoPlayEnabled) {
      return M3ESlider.wavy(
        value: sliderValue,
        min: 1,
        max: _safeTotal.toDouble(),
        size: M3ESliderSize.xs,
        trackThickness: trackThickness,
        thumbLength: thumbLength,
        // 覆盖主题默认 amplitudeForProgress（≤10% / ≥95% 为 0），
        // 自动翻页全程保持可见波浪。
        amplitude: 1,
        wavelength: readerAutoPlaySliderWavelength(
          widget.autoPlayIntervalSeconds,
        ),
        haptic: M3EHapticFeedback.light,
        semanticFormatterCallback: semanticLabel,
        onChanged: _onChanged,
        onChangeEnd: _onChangeEnd,
      );
    }

    return M3ESlider(
      value: sliderValue,
      min: 1,
      max: _safeTotal.toDouble(),
      size: M3ESliderSize.xs,
      trackThickness: trackThickness,
      thumbLength: thumbLength,
      haptic: M3EHapticFeedback.light,
      semanticFormatterCallback: semanticLabel,
      onChanged: _onChanged,
      onChangeEnd: _onChangeEnd,
    );
  }

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
    final double viewportWidth = MediaQuery.sizeOf(context).width;

    return Semantics(
      label: ReaderPageCopy.pageProgressLabel(_displayPage, _safeTotal),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 40,
            child: Text('$_displayPage', style: pageNumberStyle),
          ),
          Expanded(
            child: _buildProgressSlider(
              sliderValue: sliderValue,
              viewportWidth: viewportWidth,
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
