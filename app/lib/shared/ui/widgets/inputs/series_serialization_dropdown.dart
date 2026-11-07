import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/models/series_serialization_status.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列连载状态单选（[M3EDropdownMenu]）。
class SeriesSerializationDropdown extends StatelessWidget {
  const SeriesSerializationDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final SeriesSerializationStatus value;
  final ValueChanged<SeriesSerializationStatus> onChanged;
  final bool enabled;

  static const List<SeriesSerializationStatus> _selectable =
      <SeriesSerializationStatus>[
        SeriesSerializationStatus.ongoing,
        SeriesSerializationStatus.ended,
        SeriesSerializationStatus.hiatus,
      ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final bool hasSelection = _selectable.contains(value);

    return M3EDropdownMenu<SeriesSerializationStatus>(
      enabled: enabled,
      singleSelect: true,
      showChipAnimation: false,
      items: _selectable
          .map(
            (SeriesSerializationStatus status) => M3EDropdownItem(
              label: _label(l10n, status),
              value: status,
              selected: hasSelection && status == value,
            ),
          )
          .toList(),
      fieldStyle: M3EDropdownFieldStyle(
        hintText: l10n.formSeriesSerializationStatusLabel,
        showClearIcon: true,
        selectedTextStyle: theme.typeScale.bodyLarge.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      onSelectionChanged:
          (List<M3EDropdownItem<SeriesSerializationStatus>> items) {
            if (items.isEmpty) {
              onChanged(SeriesSerializationStatus.unknown);
              return;
            }
            onChanged(items.first.value);
          },
    );
  }

  static String _label(
    AppLocalizations l10n,
    SeriesSerializationStatus status,
  ) {
    return switch (status) {
      SeriesSerializationStatus.ongoing => l10n.serializationStatusOngoing,
      SeriesSerializationStatus.ended => l10n.serializationStatusEnded,
      SeriesSerializationStatus.hiatus => l10n.serializationStatusHiatus,
      SeriesSerializationStatus.unknown => l10n.serializationStatusUnknown,
    };
  }
}
