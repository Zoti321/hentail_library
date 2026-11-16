import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_preferences_provider.dart';

part 'metadata_last_auto_backup_notifier.g.dart';

@Riverpod(keepAlive: true)
class MetadataLastAutoBackupNotifier extends _$MetadataLastAutoBackupNotifier {
  @override
  Future<DateTime?> build() =>
      ref.read(metadataBackupPreferencesRepositoryProvider).loadLastBackupAt();
}
