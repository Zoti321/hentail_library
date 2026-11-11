import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/ui/slots/series_slots.dart';

/// 系列 UI 组合槽位 token（#493 / ADR-0042）。
///
/// 契约在 `shared/ui/slots/`，默认实现归 comic，bootstrap 组合根注入。
final Provider<SeriesCoverSlot> seriesCoverSlotProvider = injectedDi(
  'seriesCoverSlotProvider',
);

final Provider<SeriesMemberCoverSlot> seriesMemberCoverSlotProvider =
    injectedDi('seriesMemberCoverSlotProvider');

final Provider<SeriesMemberCardSlot> seriesMemberCardSlotProvider = injectedDi(
  'seriesMemberCardSlotProvider',
);

final Provider<SeriesMemberSelectionActionsSlot>
seriesMemberSelectionActionsSlotProvider = injectedDi(
  'seriesMemberSelectionActionsSlotProvider',
);

final Provider<SeriesCoverInvalidationSlot>
seriesCoverInvalidationSlotProvider = injectedDi(
  'seriesCoverInvalidationSlotProvider',
);
