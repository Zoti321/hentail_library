import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Fluent 风格单选字段：`FormLabel` + 描边容器 + 主题化 [DropdownButtonFormField]。
///
/// 内部实现可替换；调用方仅依赖 [value] / [items] / [itemLabel] / [onChanged]。
class FluentSelectField<T> extends StatefulWidget {
  const FluentSelectField({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.labelText,
    this.errorText,
    this.enabled = true,
  });

  final T value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? labelText;
  final String? errorText;
  final bool enabled;

  @override
  State<FluentSelectField<T>> createState() => _FluentSelectFieldState<T>();
}

class _FluentSelectFieldState<T> extends State<FluentSelectField<T>> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _handleChanged(T? value) {
    widget.onChanged(value);
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool hasError =
        widget.errorText != null && widget.errorText!.isNotEmpty;
    final bool showActiveBorder = widget.enabled && _isFocused && !hasError;
    final Color borderColor = hasError
        ? cs.error
        : showActiveBorder
        ? cs.hentai.inputBorderActive
        : cs.hentai.inputBorder;
    final Color textColor = widget.enabled
        ? cs.hentai.textPrimary
        : cs.hentai.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.labelText != null) ...[
          FormLabel(widget.labelText!),
          SizedBox(height: tokens.spacing.sm - 2),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: cs.hentai.inputBackground,
            borderRadius: BorderRadius.circular(tokens.radius.md),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: showActiveBorder
                ? <BoxShadow>[
                    BoxShadow(
                      color: cs.primary.withOpacity(0.2),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<T>(
              value: widget.value,
              focusNode: _focusNode,
              isExpanded: true,
              icon: Icon(
                LucideIcons.chevronDown,
                size: 16,
                color: widget.enabled
                    ? cs.onSurfaceVariant
                    : cs.hentai.textTertiary,
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: tokens.spacing.md,
                  vertical: tokens.spacing.sm,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
              ),
              dropdownColor: cs.hentai.inputBackground,
              style: TextStyle(
                fontSize: tokens.text.bodyMd,
                color: textColor,
                height: 1.4,
              ),
              items: widget.items
                  .map(
                    (T item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(widget.itemLabel(item)),
                    ),
                  )
                  .toList(),
              onChanged: widget.enabled ? _handleChanged : null,
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: tokens.spacing.xs),
          Text(
            widget.errorText!,
            style: TextStyle(
              fontSize: tokens.text.labelXs,
              color: cs.error,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}
