import 'package:hentai_library/features/home/domain/home_page_read_models.dart';

typedef HomeAlertDismissEntry = ({int dismissedAtMs, String fingerprint});

List<HomeLibraryAlert> filterDismissedHomeAlerts({
  required List<HomeLibraryAlert> alerts,
  required Map<String, HomeAlertDismissEntry> dismissed,
}) {
  if (dismissed.isEmpty) {
    return alerts;
  }
  return alerts
      .where((HomeLibraryAlert alert) {
        final HomeAlertDismissEntry? entry = dismissed[alert.dismissKey()];
        if (entry == null) {
          return true;
        }
        if (entry.fingerprint.isEmpty) {
          return false;
        }
        return entry.fingerprint != alert.dismissFingerprint();
      })
      .toList(growable: false);
}
