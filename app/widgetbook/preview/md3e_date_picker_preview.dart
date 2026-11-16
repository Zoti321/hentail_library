import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hentai_library/design-system/design_system.dart';

/// Standalone Lab coverage for all single-date presentation variants.
class Md3eDatePickerPreview extends StatefulWidget {
  const Md3eDatePickerPreview({
    this.modal = false,
    this.input = false,
    super.key,
  });
  final bool modal;
  final bool input;
  @override
  State<Md3eDatePickerPreview> createState() => _Md3eDatePickerPreviewState();
}

class _Md3eDatePickerPreviewState extends State<Md3eDatePickerPreview> {
  Locale _locale = const Locale('en');
  String _result = '';
  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: _locale,
      delegates: GlobalMaterialLocalizations.delegates,
      child: Builder(
        builder: (context) => Directionality(
          textDirection: _locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButton<Locale>(
                  value: _locale,
                  items: const [
                    DropdownMenuItem(
                      value: Locale('en'),
                      child: Text('English'),
                    ),
                    DropdownMenuItem(value: Locale('zh'), child: Text('简体中文')),
                    DropdownMenuItem(
                      value: Locale('fr'),
                      child: Text('Français'),
                    ),
                    DropdownMenuItem(
                      value: Locale('ar'),
                      child: Text('العربية'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _locale = value);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 360,
                  child: CalendarDatePickerSurface(
                    key: ValueKey((_locale, widget.modal, widget.input)),
                    initialDate: DateTime(2025, 8, 17),
                    firstDate: DateTime(1970),
                    lastDate: DateTime(2030, 12, 31),
                    modal: widget.modal,
                    initialEntryMode: widget.input
                        ? DatePickerEntryMode.input
                        : DatePickerEntryMode.calendar,
                    onConfirmed: (date) => setState(
                      () => _result = date.toIso8601String().split('T').first,
                    ),
                    onCancel: () => setState(() => _result = '—'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_result),
                const SizedBox(height: 24),
                SizedBox(
                  width: 360,
                  child: PublishedDateTextField(
                    label: MaterialLocalizations.of(context).dateInputLabel,
                    value: _result == '—' ? '' : _result,
                    onChanged: (value) => setState(() => _result = value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
