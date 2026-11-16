import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';
import 'package:hentai_library/shared/ui/slots/series_slots.dart';

/// 系列 UI 组合槽位 token（#493 / ADR-0042）。
///
/// 契约在 `shared/ui/slots/`，默认实现归 comic，bootstrap 组合根注入。
final Provider<SeriesCoverSlot> seriesCoverSlotProvider = requiredProvider(
  'seriesCoverSlotProvider',
);

final Provider<SeriesMemberCoverSlot> seriesMemberCoverSlotProvider =
    requiredProvider('seriesMemberCoverSlotProvider');

final Provider<SeriesMemberCardSlot> seriesMemberCardSlotProvider =
    requiredProvider('seriesMemberCardSlotProvider');

final Provider<SeriesMemberSelectionActionsSlot>
seriesMemberSelectionActionsSlotProvider = requiredProvider(
  'seriesMemberSelectionActionsSlotProvider',
);

final Provider<SeriesCoverInvalidationSlot>
seriesCoverInvalidationSlotProvider = requiredProvider(
  'seriesCoverInvalidationSlotProvider',
);
