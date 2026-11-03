/// 跨 feature 只读类型（真源仍在 owner `domain/`，此处 re-export，ADR-0034）。
library;

export 'package:hentai_library/features/comic_trash/domain/comic_purge_policy.dart';
export 'package:hentai_library/features/comic_trash/domain/comic_trash_repository.dart';
export 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
