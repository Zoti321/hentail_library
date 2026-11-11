import 'package:hentai_library/features/comic_trash/application/comic_trash_service.dart';
import 'package:hentai_library/features/comic_trash/public/di/comic_trash_providers.dart';
import 'package:hentai_library/shared/di/domain_event_bus_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_trash.g.dart';

@Riverpod(keepAlive: true)
ComicTrashService comicTrashService(Ref ref) => ComicTrashService(
  comicRepository: ref.read(comicTrashRepositoryProvider),
  readerSessionPort: ref.read(comicTrashNativeReaderPortProvider),
  events: ref.read(domainEventBusProvider),
);
