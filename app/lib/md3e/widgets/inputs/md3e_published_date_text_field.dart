import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_anchored_calendar_date_picker.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_docked_calendar_date_picker.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_outlined_text_field.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
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
  });

  final String label;
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
  final GlobalKey _anchorKey = GlobalKey();
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
    final BuildContext? anchorContext = _anchorKey.currentContext;
    if (anchorContext == null) {
      return;
    }
    final Rect? anchor = md3eMenuAnchorRectFor(anchorContext);
    if (anchor == null) {
      return;
    }
    setState(() => _pickerOpen = true);
    await md3eShowAnchoredCalendarDatePicker(
      context: anchorContext,
      anchor: anchor,
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

    return KeyedSubtree(
      key: _anchorKey,
      child: Md3eOutlinedTextField(
        label: widget.label,
        controller: _controller,
        keyboardType: TextInputType.datetime,
        onChanged: widget.onChanged,
        trailing: M3EIconButton(
          icon: Icon(
            _pickerOpen ? Symbols.calendar_month : Symbols.calendar_today,
            color: scheme.onSurfaceVariant,
          ),
          variant: M3EIconButtonVariant.standard,
          size: M3EIconButtonSize.sm,
          tooltip: l10n.formDatePickerHint,
          semanticLabel: l10n.formDatePickerHint,
          onPressed: _openPicker,
        ),
      ),
    );
  }
}
