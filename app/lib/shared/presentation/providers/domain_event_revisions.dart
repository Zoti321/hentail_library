import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_bus_providers.dart';
import 'package:hentai_library/shared/domain/events/events.dart';

/// 事件 → Riverpod 状态的唯一投影（ADR-0039）。
///
/// `ref.watch` 需要「当前值」，事件本身没有；因此所有 rebuild 语义集中在此。
/// 消费者只 `select` 版本号，不再各自 `ref.listen` 事件。
class DomainEventRevisionsState {
  const DomainEventRevisionsState({
    this.dictionaryRevision = 0,
    this.metadataSaveRevision = 0,
    this.catalogRevision = 0,
  });

  /// 全局 Tag / Author / Parody / Character 字典可能变化。
  final int dictionaryRevision;

  /// Comic 元数据已保存（自动备份等低频副作用用）。
  final int metadataSaveRevision;

  /// 库 / 漫画集合可能变化（catalog 重读用）。
  final int catalogRevision;

  DomainEventRevisionsState copyWith({
    int? dictionaryRevision,
    int? metadataSaveRevision,
    int? catalogRevision,
  }) {
    return DomainEventRevisionsState(
      dictionaryRevision: dictionaryRevision ?? this.dictionaryRevision,
      metadataSaveRevision: metadataSaveRevision ?? this.metadataSaveRevision,
      catalogRevision: catalogRevision ?? this.catalogRevision,
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
        .read(domainEventBusProvider)
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
          catalogRevision: state.catalogRevision + 1,
        );
      case LibraryCatalogChanged():
      case ComicsTrashed():
      case ComicsRestored():
        state = state.copyWith(catalogRevision: state.catalogRevision + 1);
    }
  }
}
