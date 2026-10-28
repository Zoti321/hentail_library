import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_anchored_calendar_date_picker.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_docked_calendar_date_picker.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_outlined_text_field.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 发布日期：可编辑文本 + 右侧按钮打开锚定浮层日历。
class Md3ePublishedDateTextField extends StatefulWidget {
  const Md3ePublishedDateTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.initialCalendarMode = M3EDatePickerMode.year,
    this.labelTrailing,
  });

  final String label;
  final Widget? labelTrailing;
  final String value;
  final ValueChanged<String> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final M3EDatePickerMode initialCalendarMode;

  @override
  State<Md3ePublishedDateTextField> createState() =>
      _Md3ePublishedDateTextFieldState();
}

class _Md3ePublishedDateTextFieldState extends State<Md3ePublishedDateTextField> {
  final LayerLink _layerLink = LayerLink();
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);
  bool _pickerOpen = false;

  @override
  void didUpdateWidget(covariant Md3ePublishedDateTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime? _parseValue() {
    final String trimmed = widget.value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return DateTime.tryParse(trimmed);
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
    await md3eShowAnchoredCalendarDatePicker(
      context: context,
      layerLink: _layerLink,
      initialDate: _parseValue(),
      firstDate: widget.firstDate ?? kMd3ePublishedDatePickerFirstDate,
      lastDate: widget.lastDate ?? kMd3ePublishedDatePickerLastDate,
      initialCalendarMode: widget.initialCalendarMode,
      onDateChanged: _applyDate,
    );
    if (mounted) {
      setState(() => _pickerOpen = false);
    }
  }

  void _applyDate(DateTime date) {
    final String formatted = _formatDate(date);
    _controller.text = formatted;
    widget.onChanged(formatted);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Md3eOutlinedTextField(
        label: widget.label,
        controller: _controller,
        keyboardType: TextInputType.datetime,
        onChanged: widget.onChanged,
        labelTrailing: widget.labelTrailing,
        trailing: M3EIconButton(
          icon: Icon(
            _pickerOpen ? Symbols.calendar_month : Symbols.calendar_today,
            color: _pickerOpen
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
          variant: _pickerOpen
              ? M3EIconButtonVariant.tonal
              : M3EIconButtonVariant.standard,
          size: M3EIconButtonSize.sm,
          tooltip: l10n.formDatePickerHint,
          semanticLabel: l10n.formDatePickerHint,
          onPressed: _openPicker,
        ),
      ),
    );
  }
}
