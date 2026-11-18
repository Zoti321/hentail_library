import 'package:hentai_library/features/reader/domain/read_session_capabilities.dart';
import 'package:hentai_library/features/reader/domain/read_session_page.dart';
import 'package:hentai_library/features/reader/domain/read_session_source.dart';
import 'package:hentai_library/features/reader/domain/read_session_subject.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';

/// Opened Read session application read model.
class OpenedReadSession {
  const OpenedReadSession({
    required this.subject,
    required this.source,
    required this.capabilities,
    required this.pages,
    required this.resumePageIndex,
    this.comic,
  });

  final ReadSessionSubject subject;
  final ReadSessionSource source;
  final ReadSessionCapabilities capabilities;
  final List<ReadSessionPage> pages;

  /// UI 1-based page index.
  final int resumePageIndex;

  /// Comic-only narrow model for native IO / progress entity; null for Image set.
  final ReaderComicRef? comic;

  int get totalPages => pages.length;

  String get sessionKey => subject.sessionKey;
}
