import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_preferences_repository.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<MetadataBackupPreferencesRepository>
metadataBackupPreferencesRepositoryProvider = requiredProvider(
  'metadataBackupPreferencesRepositoryProvider',
);
