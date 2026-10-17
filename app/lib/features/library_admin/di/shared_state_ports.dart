import 'package:hentai_library/features/library_admin/presentation/view_models/current_library_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_reorder_mode_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:hentai_library/shared/domain/library/current_library_port.dart';
import 'package:hentai_library/shared/domain/library/library_reorder_mode_port.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_signal_port.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// library_admin 对共享状态端口的实现（#260 步骤0）。
///
/// 仅委托到现有 Notifier，不改变其行为；消费方在后续 slice 中改为依赖端口。
class _CurrentLibraryAdapter implements CurrentLibraryPort {
  _CurrentLibraryAdapter(this._ref);

  final Ref _ref;

  @override
  Future<String?> currentId() async {
    final CurrentLibraryState state = await _ref.read(
      currentLibraryProvider.future,
    );
    return state.currentId;
  }

  @override
  Future<void> select(String libraryId) =>
      _ref.read(currentLibraryProvider.notifier).select(libraryId);

  @override
  Future<void> clear() => _ref.read(currentLibraryProvider.notifier).clear();

  @override
  Future<void> deleteLibrary(String libraryId) =>
      _ref.read(currentLibraryProvider.notifier).deleteLibrary(libraryId);
}

class _LibraryReorderModeAdapter implements LibraryReorderModePort {
  _LibraryReorderModeAdapter(this._ref);

  final Ref _ref;

  @override
  bool get isActive => _ref.read(libraryReorderModeProvider);

  @override
  void enter() => _ref.read(libraryReorderModeProvider.notifier).enter();

  @override
  void exit() => _ref.read(libraryReorderModeProvider.notifier).exit();
}

class _LibraryRevisionSignalAdapter implements LibraryRevisionSignalPort {
  _LibraryRevisionSignalAdapter(this._ref);

  final Ref _ref;

  @override
  void notifyExternalChange() =>
      _ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
}

final Provider<CurrentLibraryPort> currentLibraryPortProvider =
    Provider<CurrentLibraryPort>((Ref ref) => _CurrentLibraryAdapter(ref));

final Provider<LibraryReorderModePort> libraryReorderModePortProvider =
    Provider<LibraryReorderModePort>(
      (Ref ref) => _LibraryReorderModeAdapter(ref),
    );

final Provider<LibraryRevisionSignalPort> libraryRevisionSignalPortProvider =
    Provider<LibraryRevisionSignalPort>(
      (Ref ref) => _LibraryRevisionSignalAdapter(ref),
    );
