import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/l10n/app_localizations_en.dart';
import 'package:hentai_library/domain/reading/read_session_exceptions.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_open_error_message.dart';

void main() {
  final AppLocalizationsEn l10n = AppLocalizationsEn();

  test('maps failure kinds to localized open messages', () {
    expect(
      readSessionOpenFailureMessageFor(
        l10n,
        ReadSessionPageLoadException.comicNotFound('c1'),
      ),
      l10n.readerOpenResourceNotFound,
    );
    expect(
      readSessionOpenFailureMessageFor(
        l10n,
        ReadSessionPageLoadException.timedOut(comicId: 'c1', path: '/x'),
      ),
      l10n.readerOpenTimedOut,
    );
    expect(
      readSessionOpenFailureMessageFor(
        l10n,
        ReadSessionPageLoadException.emptyPages(comicId: 'c1', path: '/x'),
      ),
      l10n.readerOpenInvalidContent,
    );
    expect(
      readSessionOpenFailureMessageFor(
        l10n,
        ReadSessionPageLoadException.loadFailed(
          comicId: 'c1',
          path: '/x',
          cause: StateError('x'),
          kind: ReadSessionFailureKind.remoteAuthFailed,
        ),
      ),
      l10n.readerOpenRemoteAuthFailed,
    );
  });
}
