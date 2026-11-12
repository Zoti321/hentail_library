import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';

class DeleteLibraryUseCase {
  const DeleteLibraryUseCase(this.repository, this.events);
  final LibraryRepository repository;
  final DomainEventPublisher events;
  Future<void> call(String libraryId) async {
    await repository.delete(libraryId);
    events.publish(
      const LibraryCatalogChanged(CatalogChangeSource.libraryAdmin),
    );
  }
}
