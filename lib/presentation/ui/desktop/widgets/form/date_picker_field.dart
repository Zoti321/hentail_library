import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/date_picker.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/fluent_text_field.dart';

class FluentDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final String? hintText;
  final Function(DateTime?) onChanged;
  final String? labelText;

  const FluentDatePicker({
    super.key,
    this.initialDate,
    this.hintText,
    required this.onChanged,
    this.labelText,
  });

  @override
  State<FluentDatePicker> createState() => _FluentDatePickerState();
}

class _FluentDatePickerState extends State<FluentDatePicker> {
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialDate != null
        ? DateFormat('yyyy-MM-dd').format(widget.initialDate!)
        : '';
  }

  void _onChange(String value) {
    setState(() => _value = value);
    final date = value.isEmpty ? null : DateFormat('yyyy-MM-dd').parse(value);
    widget.onChanged(date);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          FormLabel(widget.labelText!),
          const SizedBox(height: 6),
        ],
        DatePicker(value: _value, onChange: _onChange),
      ],
    );
  }
}
