import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Chip + 内联输入行间距。
const double kInputChipFieldGap = 6;

/// 内联输入为空时占位宽度（仅 caret，不设最小输入区）。
const double kInputChipInlineEmptyWidth = 2;

const double kInputChipInlineCaretGap = 4;

/// Input chip 展示/提交的最大字符数。
const int kInputChipMaxLabelLength = 50;

/// @deprecated 使用 [inputChipInlineWidth]；保留以免外部引用断裂。
const double kInputChipFieldInlineMinWidth = kInputChipInlineEmptyWidth;

/// 相对 [M3EChipTheme.defaults.height] 的紧凑 input chip 高度。
const double kInputChipCompactHeight = 26;

M3EChipTheme compactInputChipTheme(M3EChipTheme base) {
  return base.copyWith(
    height: kInputChipCompactHeight,
    iconSize: 16,
    labelStartPadding: 10,
    inputStartPadding: 8,
    endPadding: 8,
    trailingEndPadding: 4,
    iconLabelGap: 4,
    cornerRadius: 6,
  );
}

/// Outlined 字段最小高度（与 [M3ETextField] 一致）。
double outlinedTextFieldMinHeight(M3ETextFieldTheme fieldTheme) {
  return fieldTheme.heightFor(fieldTheme.density);
}

/// 单行内容高度（chip 与输入行对齐）。
double inputChipRowLineHeight({
  required M3EChipTheme chipTheme,
  required TextStyle inputStyle,
  required bool hasChips,
}) {
  final double inputLine = M3ETextFieldTheme.lineHeightOf(inputStyle);
  if (!hasChips) {
    return inputLine;
  }
  return math.max(compactInputChipTheme(chipTheme).height, inputLine);
}

double inputChipInlineTopInset({
  required double rowLineHeight,
  required TextStyle inputStyle,
}) {
  final double inputLine = M3ETextFieldTheme.lineHeightOf(inputStyle);
  return (rowLineHeight - inputLine) / 2;
}

String inputChipCommitLabel(String raw) {
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }
  if (trimmed.length <= kInputChipMaxLabelLength) {
    return trimmed;
  }
  return trimmed.substring(0, kInputChipMaxLabelLength);
}

String inputChipDisplayLabel(String label) {
  if (label.length <= kInputChipMaxLabelLength) {
    return label;
  }
  return '${label.substring(0, kInputChipMaxLabelLength)}…';
}

double inputChipInlineWidth({required TextStyle style, required String text}) {
  if (text.isEmpty) {
    return kInputChipInlineEmptyWidth;
  }
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width + kInputChipInlineCaretGap;
}

/// chip 行 + 内联输入所需的全部布局算术（行高 / 文本上 inset / 内联宽度）。
///
/// [NamedFacetMultiSelectField] 与 [TagInputField] 共用，避免两处各算一遍。
({double rowLineHeight, double textTopInset, double inlineWidth})
resolveInputChipInlineMetrics({
  required M3EChipTheme chipTheme,
  required TextStyle inputStyle,
  required String text,
  required bool hasChips,
}) {
  final double rowLineHeight = inputChipRowLineHeight(
    chipTheme: chipTheme,
    inputStyle: inputStyle,
    hasChips: hasChips,
  );
  return (
    rowLineHeight: rowLineHeight,
    textTopInset: hasChips
        ? inputChipInlineTopInset(
            rowLineHeight: rowLineHeight,
            inputStyle: inputStyle,
          )
        : 0,
    inlineWidth: inputChipInlineWidth(style: inputStyle, text: text),
  );
}

/// Chip 字段首行与 M3E trailing 槽（固定 [minFieldHeight] + Center）对齐用的上下 inset。
({double top, double bottom}) inputChipFieldVerticalInsets({
  required M3ETextFieldTheme fieldTheme,
  required double rowLineHeight,
  required bool multiline,
}) {
  final double minFieldHeight = outlinedTextFieldMinHeight(fieldTheme);
  final double verticalPadding = fieldTheme.verticalPaddingFor(
    fieldTheme.density,
  );
  final double firstLineInset = (minFieldHeight - rowLineHeight) / 2;
  return (
    top: firstLineInset,
    bottom: multiline ? verticalPadding : firstLineInset,
  );
}

Widget compactInputChip({
  required BuildContext context,
  required String label,
  required VoidCallback? onPressed,
  required VoidCallback? onDeleted,
}) {
  final M3EThemeData theme = M3ETheme.of(context);
  return M3ETheme(
    data: theme.copyWith(chipTheme: compactInputChipTheme(theme.chipTheme)),
    child: M3EChip(
      label: inputChipDisplayLabel(label),
      type: M3EChipType.input,
      onPressed: onPressed,
      onDeleted: onDeleted,
    ),
  );
}

/// Wrap + chip 行：自管垂直 inset，与 [OutlinedTextFieldShell.chipFirstLineLayout] 配套。
class InputChipFieldContent extends StatefulWidget {
  const InputChipFieldContent({
    super.key,
    required this.fieldTheme,
    required this.inputStyle,
    required this.hasChips,
    required this.chips,
    required this.inlineField,
    this.onTap,
  });

  final M3ETextFieldTheme fieldTheme;
  final TextStyle inputStyle;
  final bool hasChips;
  final List<Widget> chips;
  final Widget inlineField;
  final VoidCallback? onTap;

  @override
  State<InputChipFieldContent> createState() => _InputChipFieldContentState();
}

class _InputChipFieldContentState extends State<InputChipFieldContent> {
  final GlobalKey _wrapKey = GlobalKey();
  bool _multiline = false;

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(covariant InputChipFieldContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chips.length != widget.chips.length ||
        oldWidget.hasChips != widget.hasChips) {
      _scheduleMeasure();
    }
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureWrap());
  }

  void _measureWrap() {
    if (!mounted) {
      return;
    }
    final RenderObject? renderObject = _wrapKey.currentContext
        ?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }
    final M3EChipTheme chipTheme = M3ETheme.of(context).chipTheme;
    final double rowLineHeight = inputChipRowLineHeight(
      chipTheme: chipTheme,
      inputStyle: widget.inputStyle,
      hasChips: widget.hasChips,
    );
    final bool multiline = renderObject.size.height > rowLineHeight + 1;
    if (multiline != _multiline) {
      setState(() => _multiline = multiline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final M3EChipTheme chipTheme = M3ETheme.of(context).chipTheme;
    final double rowLineHeight = inputChipRowLineHeight(
      chipTheme: chipTheme,
      inputStyle: widget.inputStyle,
      hasChips: widget.hasChips,
    );
    final ({double top, double bottom}) insets = inputChipFieldVerticalInsets(
      fieldTheme: widget.fieldTheme,
      rowLineHeight: rowLineHeight,
      multiline: _multiline,
    );

    final Widget wrap = Wrap(
      key: _wrapKey,
      spacing: kInputChipFieldGap,
      runSpacing: kInputChipFieldGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[...widget.chips, widget.inlineField],
    );

    return Padding(
      padding: EdgeInsets.only(top: insets.top, bottom: insets.bottom),
      child: widget.onTap == null
          ? wrap
          : GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.onTap,
              child: wrap,
            ),
    );
  }
}
