import 'package:hentai_library/l10n/app_localizations.dart';

extension HomeL10nX on AppLocalizations {
  String homeGreetingPhraseForHour(int hour) {
    if (hour < 5) {
      return homeGreetingLateNight;
    }

    if (hour < 9) {
      return homeGreetingEarlyMorning;
    }

    if (hour < 12) {
      return homeGreetingMorning;
    }

    if (hour < 14) {
      return homeGreetingNoon;
    }

    if (hour < 18) {
      return homeGreetingAfternoon;
    }

    if (hour < 23) {
      return homeGreetingEvening;
    }

    return homeGreetingLate;
  }
}
