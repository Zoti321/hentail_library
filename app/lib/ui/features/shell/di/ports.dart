import 'package:hentai_library/data/adapters/comic_library_scan_adapter.dart';
import 'package:hentai_library/data/adapters/comic_page_source_frb_adapter.dart';
import 'package:hentai_library/data/adapters/reader_session_frb_adapter.dart';
import 'package:hentai_library/domain/ports/comic_page_source_port.dart';
import 'package:hentai_library/domain/ports/library_scan_port.dart';
import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:hentai_library/ui/features/shell/di/services.dart';
import 'package:hentai_library/ui/features/shell/di/tools.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ports.g.dart';

@Riverpod(keepAlive: true)
LibraryScanPort libraryScanPort(Ref ref) => ComicLibraryScanAdapter(
  scanParseService: ref.read(comicScanParseServiceProvider),
  comicMapper: ref.read(libraryComicMapperProvider),
);

@Riverpod(keepAlive: true)
ReaderSessionPort readerSessionPort(Ref ref) => const ReaderSessionFrbAdapter();

@Riverpod(keepAlive: true)
ComicPageSourcePort comicPageSourcePort(Ref ref) =>
    const ComicPageSourceFrbAdapter();
