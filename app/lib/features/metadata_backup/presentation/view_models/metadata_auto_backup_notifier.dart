import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_preferences_provider.dart';

part 'metadata_auto_backup_notifier.g.dart';

@Riverpod(keepAlive: true)
class MetadataAutoBackupNotifier extends _$MetadataAutoBackupNotifier {
  @override
  Future<bool> build() =>
      ref.read(metadataBackupPreferencesRepositoryProvider).loadEnabled();

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData<bool>(enabled);
    await ref
        .read(metadataBackupPreferencesRepositoryProvider)
        .saveEnabled(enabled);
  }
}
