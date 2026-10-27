import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_entry.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列连载状态单选（[M3EDropdownMenu]）。
class Md3eSeriesSerializationDropdown extends StatelessWidget {
  const Md3eSeriesSerializationDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final Md3eSeriesSerializationStatus value;
  final ValueChanged<Md3eSeriesSerializationStatus> onChanged;
  final bool enabled;

  static const List<Md3eSeriesSerializationStatus> _selectable =
      <Md3eSeriesSerializationStatus>[
        Md3eSeriesSerializationStatus.ongoing,
        Md3eSeriesSerializationStatus.ended,
        Md3eSeriesSerializationStatus.hiatus,
      ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final Md3eSeriesSerializationStatus resolved = _selectable.contains(value)
        ? value
        : Md3eSeriesSerializationStatus.ongoing;

    return M3EDropdownMenu<Md3eSeriesSerializationStatus>(
      key: ValueKey<Md3eSeriesSerializationStatus>(resolved),
      enabled: enabled,
      singleSelect: true,
      showChipAnimation: false,
      items: _selectable
          .map(
            (Md3eSeriesSerializationStatus status) => M3EDropdownItem(
              label: _label(l10n, status),
              value: status,
              selected: status == resolved,
            ),
          )
          .toList(),
      fieldStyle: M3EDropdownFieldStyle(
        hintText: l10n.formSeriesSerializationStatusLabel,
        selectedTextStyle: theme.typeScale.bodyLarge.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      onSelectionChanged: (List<M3EDropdownItem<Md3eSeriesSerializationStatus>> items) {
        if (items.isEmpty) {
          return;
        }
        onChanged(items.first.value);
      },
    );
  }

  static String _label(
    AppLocalizations l10n,
    Md3eSeriesSerializationStatus status,
  ) {
    return switch (status) {
      Md3eSeriesSerializationStatus.ongoing => l10n.serializationStatusOngoing,
      Md3eSeriesSerializationStatus.ended => l10n.serializationStatusEnded,
      Md3eSeriesSerializationStatus.hiatus => l10n.serializationStatusHiatus,
      Md3eSeriesSerializationStatus.unknown => l10n.serializationStatusUnknown,
    };
  }
}
