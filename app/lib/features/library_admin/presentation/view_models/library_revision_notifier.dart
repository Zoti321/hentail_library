import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/domain_event_revisions.dart';
import 'package:hentai_library/features/library_admin/domain/library_revision_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:hentai_library/features/library_admin/domain/library_revision_state.dart';

part 'library_revision_notifier.g.dart';

/// Catalog 刷新计数（ADR-0039）：外部 `data_version` 流 + 领域事件双来源。
///
/// 事件侧经 [domainEventRevisionsProvider] 的 `catalogRevision` 投影，
/// 不在本类里再订阅事件总线。
@Riverpod(keepAlive: true)
class LibraryRevisionNotifier extends _$LibraryRevisionNotifier {
  StreamSubscription<void>? _subscription;

  @override
  LibraryRevisionState build() {
    _subscribeRevision();
    ref.listen<int>(
      domainEventRevisionsProvider.select(
        (DomainEventRevisionsState s) => s.catalogRevision,
      ),
      (int? previous, int next) {
        if (previous != null && previous != next) {
          _bumpRevision();
        }
      },
    );
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return const LibraryRevisionState();
  }

  void _subscribeRevision() {
    final port = ref.read(libraryRevisionPortProvider);
    _subscription = port.watchRevision().listen(
      (_) => _bumpRevision(),
      onError: (Object error, StackTrace stackTrace) {
        state = state.copyWith(hasReceivedFirstEmit: true, streamError: error);
      },
    );
  }

  void _bumpRevision() {
    state = state.copyWith(
      revision: state.revision + 1,
      hasReceivedFirstEmit: true,
      streamError: null,
    );
  }
}
