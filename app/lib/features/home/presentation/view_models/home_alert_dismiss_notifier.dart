import 'package:hentai_library/features/home/domain/home_alert_dismissal.dart';
import 'package:hentai_library/features/home/domain/home_page_read_models.dart';
import 'package:hentai_library/features/home/presentation/providers/home_alert_dismiss_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_alert_dismiss_notifier.g.dart';

@Riverpod(keepAlive: true)
class HomeAlertDismissStore extends _$HomeAlertDismissStore {
  @override
  Future<Map<String, HomeAlertDismissEntry>> build() =>
      ref.read(homeAlertDismissRepositoryProvider).load();

  Future<void> dismiss(HomeLibraryAlert alert) async {
    await ref
        .read(homeAlertDismissRepositoryProvider)
        .dismiss(alert, DateTime.now());
    ref.invalidateSelf();
  }

  Future<void> clearDismissAfterAlertSync(String libraryId) async {
    await ref
        .read(homeAlertDismissRepositoryProvider)
        .clearForLibrary(libraryId);
    ref.invalidateSelf();
  }
}
