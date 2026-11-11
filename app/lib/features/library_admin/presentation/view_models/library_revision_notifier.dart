import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/domain_event_revisions.dart';
import 'package:hentai_library/shared/domain/library/library_revision_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:hentai_library/shared/domain/library/library_revision_state.dart';

part 'library_revision_notifier.g.dart';

/// Catalog 刷新计数（ADR-0039）：唯一来源是领域事件。
///
/// 经 [domainEventRevisionsProvider] 的 `catalogRevision` 投影，
/// 不在本类里再订阅事件总线或 Rust 数据流。
@Riverpod(keepAlive: true)
class LibraryRevisionNotifier extends _$LibraryRevisionNotifier {
  @override
  LibraryRevisionState build() {
    ref.listen<int>(
      domainEventRevisionsProvider.select(
        (DomainEventRevisionsState s) => s.catalogRevision,
      ),
      (int? previous, int next) {
        if (previous != null && previous != next) {
          state = state.copyWith(
            revision: state.revision + 1,
            hasReceivedFirstEmit: true,
            streamError: null,
          );
        }
      },
    );
    return const LibraryRevisionState();
  }
}
