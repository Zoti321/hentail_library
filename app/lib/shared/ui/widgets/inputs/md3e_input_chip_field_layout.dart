import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Chip + 内联输入行间距。
const double kMd3eInputChipFieldGap = 6;

/// 内联输入为空时占位宽度（仅 caret，不设最小输入区）。
const double kMd3eInputChipInlineEmptyWidth = 2;

const double kMd3eInputChipInlineCaretGap = 4;

/// Input chip 展示/提交的最大字符数。
const int kMd3eInputChipMaxLabelLength = 50;

/// @deprecated 使用 [md3eInputChipInlineWidth]；保留以免外部引用断裂。
const double kMd3eInputChipFieldInlineMinWidth = kMd3eInputChipInlineEmptyWidth;

/// 相对 [M3EChipTheme.defaults.height] 的紧凑 input chip 高度。
const double kMd3eInputChipCompactHeight = 26;

M3EChipTheme md3eCompactInputChipTheme(M3EChipTheme base) {
  return base.copyWith(
    height: kMd3eInputChipCompactHeight,
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
double md3eOutlinedTextFieldMinHeight(M3ETextFieldTheme fieldTheme) {
  return fieldTheme.heightFor(fieldTheme.density);
}

/// 单行内容高度（chip 与输入行对齐）。
double md3eInputChipRowLineHeight({
  required M3EChipTheme chipTheme,
  required TextStyle inputStyle,
  required bool hasChips,
}) {
  final double inputLine = M3ETextFieldTheme.lineHeightOf(inputStyle);
  if (!hasChips) {
    return inputLine;
  }
  return math.max(md3eCompactInputChipTheme(chipTheme).height, inputLine);
}

double md3eInputChipInlineTopInset({
  required double rowLineHeight,
  required TextStyle inputStyle,
}) {
  final double inputLine = M3ETextFieldTheme.lineHeightOf(inputStyle);
  return (rowLineHeight - inputLine) / 2;
}

String md3eInputChipCommitLabel(String raw) {
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }
  if (trimmed.length <= kMd3eInputChipMaxLabelLength) {
    return trimmed;
  }
  return trimmed.substring(0, kMd3eInputChipMaxLabelLength);
}

String md3eInputChipDisplayLabel(String label) {
  if (label.length <= kMd3eInputChipMaxLabelLength) {
    return label;
  }
  return '${label.substring(0, kMd3eInputChipMaxLabelLength)}…';
}

double md3eInputChipInlineWidth({
  required TextStyle style,
  required String text,
}) {
  if (text.isEmpty) {
    return kMd3eInputChipInlineEmptyWidth;
  }
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width + kMd3eInputChipInlineCaretGap;
}

/// Chip 字段首行与 M3E trailing 槽（固定 [minFieldHeight] + Center）对齐用的上下 inset。
({double top, double bottom}) md3eInputChipFieldVerticalInsets({
  required M3ETextFieldTheme fieldTheme,
  required double rowLineHeight,
  required bool multiline,
}) {
  final double minFieldHeight = md3eOutlinedTextFieldMinHeight(fieldTheme);
  final double verticalPadding = fieldTheme.verticalPaddingFor(
    fieldTheme.density,
  );
  final double firstLineInset = (minFieldHeight - rowLineHeight) / 2;
  return (
    top: firstLineInset,
    bottom: multiline ? verticalPadding : firstLineInset,
  );
}

Widget md3eCompactInputChip({
  required BuildContext context,
  required String label,
  required VoidCallback? onPressed,
  required VoidCallback? onDeleted,
}) {
  final M3EThemeData theme = M3ETheme.of(context);
  return M3ETheme(
    data: theme.copyWith(chipTheme: md3eCompactInputChipTheme(theme.chipTheme)),
    child: M3EChip(
      label: md3eInputChipDisplayLabel(label),
      type: M3EChipType.input,
      onPressed: onPressed,
      onDeleted: onDeleted,
    ),
  );
}

/// Wrap + chip 行：自管垂直 inset，与 [Md3eOutlinedTextFieldShell.chipFirstLineLayout] 配套。
class Md3eInputChipFieldContent extends StatefulWidget {
  const Md3eInputChipFieldContent({
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
  State<Md3eInputChipFieldContent> createState() =>
      _Md3eInputChipFieldContentState();
}

class _Md3eInputChipFieldContentState extends State<Md3eInputChipFieldContent> {
  final GlobalKey _wrapKey = GlobalKey();
  bool _multiline = false;

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(covariant Md3eInputChipFieldContent oldWidget) {
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
    final double rowLineHeight = md3eInputChipRowLineHeight(
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
    final double rowLineHeight = md3eInputChipRowLineHeight(
      chipTheme: chipTheme,
      inputStyle: widget.inputStyle,
      hasChips: widget.hasChips,
    );
    final ({double top, double bottom}) insets =
        md3eInputChipFieldVerticalInsets(
          fieldTheme: widget.fieldTheme,
          rowLineHeight: rowLineHeight,
          multiline: _multiline,
        );

    final Widget wrap = Wrap(
      key: _wrapKey,
      spacing: kMd3eInputChipFieldGap,
      runSpacing: kMd3eInputChipFieldGap,
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
