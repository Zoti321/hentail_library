import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:material_3_expressive/components/text_fields/components/m3e_text_field_affordance.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../calendar/anchored_calendar_date_picker.dart';
import '../calendar/calendar_date_input.dart';
import '../calendar/docked_calendar_date_picker.dart';
import 'outlined_text_field.dart';

/// 发布日期：可编辑文本 + M3E trailing 日历 + clear。
class PublishedDateTextField extends StatefulWidget {
  const PublishedDateTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.firstDate,
    this.lastDate,
    this.initialCalendarMode = M3EDatePickerMode.day,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final M3EDatePickerMode initialCalendarMode;

  @override
  State<PublishedDateTextField> createState() => _PublishedDateTextFieldState();
}

class _PublishedDateTextFieldState extends State<PublishedDateTextField> {
  final LayerLink _layerLink = LayerLink();
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focusNode = FocusNode();
  bool _pickerOpen = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
  }

  void _handleFocus() {
    if (!_focusNode.hasFocus) _normalizeInput();
  }

  void _normalizeInput() {
    final date = _parseValue();
    if (date != null && _controller.text != _formatDate(date)) _applyDate(date);
  }

  bool _applyingDate = false;

  @override
  void didUpdateWidget(covariant PublishedDateTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  DateTime? _parseValue() {
    final String trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return parseCalendarDate(trimmed, MaterialLocalizations.of(context));
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _openPicker() async {
    if (_pickerOpen) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _pickerOpen = true);
    await showAnchoredCalendarDatePicker(
      context: context,
      layerLink: _layerLink,
      initialDate: _parseValue(),
      firstDate: widget.firstDate ?? kPublishedDatePickerFirstDate,
      lastDate: widget.lastDate ?? kPublishedDatePickerLastDate,
      initialCalendarMode: widget.initialCalendarMode,
      onDateChanged: _applyDate,
    );
    if (mounted) {
      setState(() => _pickerOpen = false);
    }
  }

  void _applyDate(DateTime date) {
    final String formatted = _formatDate(date);
    _applyingDate = true;
    _controller.text = formatted;
    _applyingDate = false;
    widget.onChanged(formatted);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETextFieldTheme fieldTheme = theme.textFieldTheme;
    final double iconSize = fieldTheme.iconSize;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedTextField(
            label: widget.label,
            controller: _controller,
            focusNode: _focusNode,
            hintText: 'yyyy-MM-dd',
            onSubmitted: (_) => _normalizeInput(),
            keyboardType: TextInputType.datetime,
            onChanged: (value) {
              if (!_applyingDate) widget.onChanged(value);
            },
            errorText: widget.errorText,
            showClearButton: true,
            clearButtonSemanticsLabel: MaterialLocalizations.of(context)
                .clearButtonTooltip,
            trailing: M3ETextFieldAffordance(
              icon: _pickerOpen
                  ? Symbols.calendar_month
                  : Symbols.calendar_today,
              color: _pickerOpen
                  ? scheme.onSecondaryContainer
                  : scheme.onSurfaceVariant,
              iconSize: iconSize,
              semanticLabel: MaterialLocalizations.of(context)
                  .datePickerHelpText,
              onPressed: _openPicker,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, top: 4),
            child: Text(
              'yyyy-MM-dd',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
