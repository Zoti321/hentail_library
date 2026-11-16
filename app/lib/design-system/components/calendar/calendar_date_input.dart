import 'package:flutter/material.dart';

/// Accept separators after editing; reject DateTime's overflow normalization.
DateTime? parseCalendarDate(String text, MaterialLocalizations l10n) {
  final value = text.trim();
  final parts = value.split(RegExp(r'[-/.\s]+'));
  if (parts.length == 3 && parts.first.length == 4) {
    final year = int.tryParse(parts.first);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }
  return l10n.parseCompactDate(value.replaceAll(RegExp(r'[-.\s]+'), '/'));
}
