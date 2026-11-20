import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';

/// Persists Image set library browse preferences (keys distinct from Comic/Series).
abstract interface class ImageSetBrowsePreferencesRepository {
  Future<ImageSetBrowsePreferences> load();

  Future<void> save(ImageSetBrowsePreferences preferences);

  Future<void> reset();
}
