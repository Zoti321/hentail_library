import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reader/domain/comic_page_source_port.dart';
import 'package:hentai_library/features/reader/domain/native_reader_port.dart';
import 'package:hentai_library/shared/di/injected_di.dart';

/// reader owner 的 Port token（#515；实现由 bootstrap 注入）。

final Provider<NativeReaderPort> nativeReaderPortProvider = injectedDi(
  'nativeReaderPortProvider',
);

final Provider<ComicPageSourcePort> comicPageSourcePortProvider = injectedDi(
  'comicPageSourcePortProvider',
);
