import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/shared/domain/library/scan_interval.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Scan interval 单选（[M3EDropdownMenu]）。
class Md3eScanIntervalDropdown extends StatelessWidget {
  const Md3eScanIntervalDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final ScanInterval value;
  final ValueChanged<ScanInterval> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);

    return M3EDropdownMenu<ScanInterval>(
      enabled: enabled,
      singleSelect: true,
      showChipAnimation: false,
      items: ScanInterval.values
          .map(
            (ScanInterval interval) => M3EDropdownItem(
              label: l10n.scanIntervalLabel(interval),
              value: interval,
              selected: interval == value,
            ),
          )
          .toList(),
      fieldStyle: M3EDropdownFieldStyle(
        hintText: l10n.formLibraryScanIntervalLabel,
        showClearIcon: false,
        selectedTextStyle: theme.typeScale.bodyLarge.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      onSelectionChanged: (List<M3EDropdownItem<ScanInterval>> items) {
        if (items.isEmpty) {
          return;
        }
        onChanged(items.first.value);
      },
    );
  }
}
