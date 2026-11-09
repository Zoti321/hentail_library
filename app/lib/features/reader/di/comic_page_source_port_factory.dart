import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/read_session/data/adapters/comic_page_source_frb_adapter.dart';
import 'package:hentai_library/features/read_session/domain/comic_page_source_port.dart';

/// Bootstrap / 测试注入用工厂（跨 feature 仍读 `shared/di` token）。
ComicPageSourcePort createComicPageSourcePort(Ref ref) =>
    const ComicPageSourceFrbAdapter();
