import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';

import 'package:hentai_library/features/library_admin/domain/library_repository.dart';

/// Library 增删改用例：写库成功后发布目录变更事实（ADR-0039）。
///
/// presentation 只读本服务，不直接发布事件（Gate E2）。
class LibraryWriteService {
  const LibraryWriteService({required this._repository, required this._events});

  final LibraryRepository _repository;
  final DomainEventPublisher _events;

  Future<LibraryFormApplyResult> submitForm(
    LibraryForm form, {
    LocalLibrary? original,
  }) async {
    final LibraryFormApplyResult result = original == null
        ? await form.create(_repository)
        : await form.applyTo(_repository, original);
    if (result is LibraryFormApplySucceeded) {
      _publishChanged();
    }
    return result;
  }

  Future<void> deleteLibrary(String libraryId) async {
    await _repository.delete(libraryId);
    _publishChanged();
  }

  void _publishChanged() => _events.publish(
    const LibraryCatalogChanged(CatalogChangeSource.libraryAdmin),
  );
}
