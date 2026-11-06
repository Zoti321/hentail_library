import 'package:flutter/widgets.dart';
import 'package:hentai_library/shared/ui/l10n/m3e_material_localizations.dart';
import 'package:material_3_expressive/components/date_pickers/components/m3e_date_picker_mode_toggle.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 带 material_ui 本地化的日期模式切换条（日 ↔ 年）。
///
/// 若已在 [materialUiLocalizationsScope] 内（如 [EmbeddableCalendarDatePicker]），
/// 可直接使用 [M3EDatePickerModeToggle]。
Widget datePickerModeToggle({
  required M3EDatePickerMode mode,
  required DateTime monthDate,
  required ValueChanged<M3EDatePickerMode> onChanged,
  Key? key,
}) {
  return materialUiLocalizationsScope(
    child: M3EDatePickerModeToggle(
      key: key,
      mode: mode,
      monthDate: monthDate,
      onChanged: onChanged,
    ),
  );
}
