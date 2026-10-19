import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'metadata_last_auto_backup_notifier.g.dart';

const String metadataLastAutoBackupAtStorageKey =
    'metadata_last_auto_backup_at_v1';

@Riverpod(keepAlive: true)
class MetadataLastAutoBackupNotifier extends _$MetadataLastAutoBackupNotifier {
  @override
  Future<DateTime?> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? millis = prefs.getInt(metadataLastAutoBackupAtStorageKey);
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> recordBackup(DateTime completedAt) async {
    state = AsyncData<DateTime?>(completedAt);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      metadataLastAutoBackupAtStorageKey,
      completedAt.millisecondsSinceEpoch,
    );
  }
}
