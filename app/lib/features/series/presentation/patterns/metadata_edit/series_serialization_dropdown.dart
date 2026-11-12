import 'package:hentai_library/features/series/domain/value_objects/serialization_status.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列连载状态单选（[M3EDropdownMenu]）。
class SeriesSerializationDropdown extends StatelessWidget {
  const SeriesSerializationDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final SerializationStatus value;
  final ValueChanged<SerializationStatus> onChanged;
  final bool enabled;

  static const List<SerializationStatus> _selectable = <SerializationStatus>[
    SerializationStatus.ongoing,
    SerializationStatus.ended,
    SerializationStatus.hiatus,
  ];

  void _handleSelectionChanged(
    List<M3EDropdownItem<SerializationStatus>> items,
  ) {
    if (items.isEmpty) {
      onChanged(SerializationStatus.unknown);
      return;
    }
    onChanged(items.first.value);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final bool hasSelection = _selectable.contains(value);

    return M3EDropdownMenu<SerializationStatus>(
      enabled: enabled,
      singleSelect: true,
      showChipAnimation: false,
      items: _selectable
          .map(
            (SerializationStatus status) => M3EDropdownItem(
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
      onSelectionChanged: _handleSelectionChanged,
    );
  }

  static String _label(AppLocalizations l10n, SerializationStatus status) {
    return switch (status) {
      SerializationStatus.ongoing => l10n.serializationStatusOngoing,
      SerializationStatus.ended => l10n.serializationStatusEnded,
      SerializationStatus.hiatus => l10n.serializationStatusHiatus,
      SerializationStatus.unknown => l10n.serializationStatusUnknown,
    };
  }
}
