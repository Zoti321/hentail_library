import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_repository.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_set_cover_providers.g.dart';

/// Soft cap for keep-alive JPEG bytes retained after cover providers dispose.
const int kImageSetCoverThumbnailCacheMaxEntries = 80;

typedef ImageSetCoverKey = ({String libraryId, String imageSetId});

typedef ImageSetEnsureCoverQuery =
    Future<Uint8List?> Function({
      required String libraryId,
      required String imageSetId,
      required ThumbnailPriority priority,
    });

typedef ImageSetFindCoverQuery = Future<Uint8List?> Function(String imageSetId);

final Provider<ImageSetEnsureCoverQuery> imageSetEnsureCoverQueryProvider =
    requiredProvider('imageSetEnsureCoverQueryProvider');

final Provider<ImageSetFindCoverQuery> imageSetFindCoverQueryProvider =
    requiredProvider('imageSetFindCoverQueryProvider');

@Riverpod(keepAlive: true)
class ImageSetCoverThumbnailLru extends _$ImageSetCoverThumbnailLru {
  final LinkedHashSet<String> _order = LinkedHashSet<String>();

  @override
  void build() {}

  void touch(String imageSetId) {
    _order.remove(imageSetId);
    _order.add(imageSetId);
    _evictOverflow();
  }

  void remove(String imageSetId) {
    _order.remove(imageSetId);
  }

  void _evictOverflow() {
    while (_order.length > kImageSetCoverThumbnailCacheMaxEntries) {
      final String? oldest = _order.isEmpty ? null : _order.first;
      if (oldest == null) {
        return;
      }
      _order.remove(oldest);
      ref
          .read(imageSetCoverThumbnailCacheProvider(oldest).notifier)
          .clear(notifyLru: false);
    }
  }
}

@Riverpod(keepAlive: true)
class ImageSetCoverThumbnailCache extends _$ImageSetCoverThumbnailCache {
  @override
  Uint8List? build(String imageSetId) => null;

  void set(Uint8List bytes) {
    state = bytes;
    ref.read(imageSetCoverThumbnailLruProvider.notifier).touch(imageSetId);
  }

  void clear({bool notifyLru = true}) {
    state = null;
    if (notifyLru) {
      ref.read(imageSetCoverThumbnailLruProvider.notifier).remove(imageSetId);
    }
  }
}

/// Catalog cover bytes for one Image set (ensure + session LRU).
final imageSetCoverBytesProvider = FutureProvider.autoDispose
    .family<Uint8List?, ImageSetCoverKey>((Ref ref, ImageSetCoverKey key) async {
      final Uint8List? cached = ref.read(
        imageSetCoverThumbnailCacheProvider(key.imageSetId),
      );
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      final Uint8List? ensured = await ref.read(imageSetEnsureCoverQueryProvider)(
        libraryId: key.libraryId,
        imageSetId: key.imageSetId,
        priority: ThumbnailPriority.high,
      );
      if (ensured != null && ensured.isNotEmpty) {
        ref
            .read(imageSetCoverThumbnailCacheProvider(key.imageSetId).notifier)
            .set(ensured);
        return ensured;
      }
      // Non-critical ensure may return null while queued; brief poll via find.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final Uint8List? found = await ref.read(imageSetFindCoverQueryProvider)(
        key.imageSetId,
      );
      if (found != null && found.isNotEmpty) {
        ref
            .read(imageSetCoverThumbnailCacheProvider(key.imageSetId).notifier)
            .set(found);
      }
      return found;
    });

/// Binds cover ensure/find to [ImageSetRepository].
ImageSetEnsureCoverQuery bindImageSetEnsureCover(ImageSetRepository repository) {
  return ({
    required String libraryId,
    required String imageSetId,
    required ThumbnailPriority priority,
  }) => repository.ensureCover(
    libraryId: libraryId,
    imageSetId: imageSetId,
    priority: priority,
  );
}

ImageSetFindCoverQuery bindImageSetFindCover(ImageSetRepository repository) {
  return repository.findCover;
}
