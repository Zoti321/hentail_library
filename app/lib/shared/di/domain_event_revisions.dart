import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/event_bus_providers.dart';
import 'package:hentai_library/shared/domain/events/events.dart';

/// 事件 → Riverpod 状态的唯一投影（ADR-0039）。
///
/// `ref.watch` 需要「当前值」，事件本身没有；因此所有 rebuild 语义集中在此。
/// 消费者只 `select` 版本号，不再各自 `ref.listen` 事件。
class DomainEventRevisionsState {
  const DomainEventRevisionsState({
    this.dictionaryRevision = 0,
    this.metadataSaveRevision = 0,
  });

  final int dictionaryRevision;
  final int metadataSaveRevision;

  DomainEventRevisionsState copyWith({
    int? dictionaryRevision,
    int? metadataSaveRevision,
  }) {
    return DomainEventRevisionsState(
      dictionaryRevision: dictionaryRevision ?? this.dictionaryRevision,
      metadataSaveRevision: metadataSaveRevision ?? this.metadataSaveRevision,
    );
  }
}

final NotifierProvider<DomainEventRevisions, DomainEventRevisionsState>
domainEventRevisionsProvider =
    NotifierProvider<DomainEventRevisions, DomainEventRevisionsState>(
      DomainEventRevisions.new,
    );

class DomainEventRevisions extends Notifier<DomainEventRevisionsState> {
  @override
  DomainEventRevisionsState build() {
    final StreamSubscription<DomainEvent> subscription = ref
        .read(appEventBusProvider)
        .on<DomainEvent>()
        .listen(_reduce);
    ref.onDispose(subscription.cancel);
    return const DomainEventRevisionsState();
  }

  /// 每个事件必须显式归类（sealed switch 强制穷尽），新增事件会编译失败提醒归位。
  void _reduce(DomainEvent event) {
    switch (event) {
      case ComicMetadataPersisted(:final dictionariesWritten):
        state = state.copyWith(
          dictionaryRevision:
              state.dictionaryRevision + (dictionariesWritten ? 1 : 0),
          metadataSaveRevision: state.metadataSaveRevision + 1,
        );
    }
  }
}
