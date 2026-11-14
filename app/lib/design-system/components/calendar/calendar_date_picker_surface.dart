import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../motion/motion.dart';
import 'calendar_date_input.dart';
import 'calendar_size_transition.dart';
import 'embeddable_calendar_date_picker.dart';

/// Owns the draft shared by calendar/input modes and both presentation variants.
class CalendarDatePickerSurface extends StatefulWidget {
  const CalendarDatePickerSurface({
    required this.firstDate,
    required this.lastDate,
    required this.onConfirmed,
    required this.onCancel,
    this.initialDate,
    this.currentDate,
    this.initialCalendarMode = M3EDatePickerMode.day,
    this.modal = false,
    this.fullscreen = false,
    this.initialEntryMode = DatePickerEntryMode.calendar,
    super.key,
  });
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDate;
  final DateTime? currentDate;
  final M3EDatePickerMode initialCalendarMode;
  final ValueChanged<DateTime> onConfirmed;
  final VoidCallback onCancel;
  final bool modal;
  final bool fullscreen;
  final DatePickerEntryMode initialEntryMode;
  @override
  State<CalendarDatePickerSurface> createState() =>
      _CalendarDatePickerSurfaceState();
}

class _CalendarDatePickerSurfaceState extends State<CalendarDatePickerSurface> {
  final _form = GlobalKey<FormState>();
  final _input = TextEditingController();
  DateTime? _pending;
  bool _inputMode = false;
  bool _initialized = false;
  bool _valid(DateTime day) =>
      !day.isBefore(DateUtils.dateOnly(widget.firstDate)) &&
      !day.isAfter(DateUtils.dateOnly(widget.lastDate));
  @override
  void initState() {
    super.initState();
    _inputMode = widget.initialEntryMode == DatePickerEntryMode.input;
    final date = widget.initialDate;
    if (date != null && _valid(DateUtils.dateOnly(date))) {
      _pending = DateUtils.dateOnly(date);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _input.text = _pending == null
          ? ''
          : MaterialLocalizations.of(context).formatCompactDate(_pending!);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_inputMode) {
      if (!(_form.currentState?.validate() ?? false)) return;
      _pending = parseCalendarDate(
        _input.text,
        MaterialLocalizations.of(context),
      );
    }
    final date = _pending;
    if (date != null && _valid(date)) widget.onConfirmed(date);
  }

  void _toggleInput() {
    final l10n = MaterialLocalizations.of(context);
    if (_inputMode) {
      final date = parseCalendarDate(_input.text, l10n);
      if (date != null && _valid(date)) _pending = date;
    } else {
      _input.text = _pending == null ? '' : l10n.formatCompactDate(_pending!);
    }
    setState(() => _inputMode = !_inputMode);
  }

  String? _validate(String? text) {
    final l10n = MaterialLocalizations.of(context);
    final date = parseCalendarDate(text ?? '', l10n);
    if (date == null) return l10n.invalidDateFormatLabel;
    return _valid(date) ? null : l10n.dateOutOfRangeLabel;
  }

  void _submit(DateTime date) {
    _pending = date;
    _confirm();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MaterialLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final duration = LabMotion.motionDurationOf(
      context,
      LabMotion.durationShort,
    );
    return Material(
      key: const ValueKey('calendar-surface'),
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(
        widget.fullscreen
            ? 0
            : widget.modal
            ? 28
            : 16,
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.fullscreen)
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.closeButtonTooltip,
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _inputMode || _pending != null ? _confirm : null,
                    child: Text(l10n.saveButtonLabel),
                  ),
                ],
              ),
            if (widget.modal) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _inputMode
                          ? l10n.dateInputLabel
                          : l10n.datePickerHelpText,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _pending == null
                                  ? l10n.datePickerHelpText
                                  : l10n.formatMediumDate(_pending!),
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(color: colors.onSurface),
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('calendar-input-toggle'),
                          tooltip: _inputMode
                              ? l10n.calendarModeButtonLabel
                              : l10n.inputDateModeButtonLabel,
                          onPressed: _toggleInput,
                          icon: Icon(
                            _inputMode
                                ? Icons.calendar_today
                                : Icons.edit_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),
            ],
            CalendarSizeTransition(
              duration: duration,
              alignment: Alignment.topCenter,
              curve: LabMotion.curveEmphasized,
              child: _inputMode
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _form,
                        child: TextFormField(
                          key: const ValueKey('calendar-date-input'),
                          controller: _input,
                          autofocus: true,
                          keyboardType: TextInputType.datetime,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: l10n.dateInputLabel,
                            hintText: l10n.dateHelpText,
                            helperText: l10n.dateHelpText,
                          ),
                          validator: _validate,
                          onFieldSubmitted: (_) => _confirm(),
                        ),
                      ),
                    )
                  : EmbeddableCalendarDatePicker(
                      initialDate: _pending,
                      currentDate: widget.currentDate,
                      firstDate: widget.firstDate,
                      lastDate: widget.lastDate,
                      initialCalendarMode: widget.initialCalendarMode,
                      modal: widget.modal,
                      expandToFit: true,
                      onDateChanged: (date) => setState(() => _pending = date),
                      onDateSubmitted: _submit,
                    ),
            ),
            if (!widget.fullscreen)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: widget.onCancel,
                      child: Text(l10n.cancelButtonLabel),
                    ),
                    TextButton(
                      key: const ValueKey('calendar-confirm'),
                      onPressed: _inputMode || _pending != null
                          ? _confirm
                          : null,
                      child: Text(l10n.okButtonLabel),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
