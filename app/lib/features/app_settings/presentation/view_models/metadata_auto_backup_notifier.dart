import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'metadata_auto_backup_notifier.g.dart';

const String metadataAutoBackupStorageKey = 'metadata_auto_backup_enabled_v1';

@Riverpod(keepAlive: true)
class MetadataAutoBackupNotifier extends _$MetadataAutoBackupNotifier {
  @override
  Future<bool> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(metadataAutoBackupStorageKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData<bool>(enabled);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(metadataAutoBackupStorageKey, enabled);
  }
}
