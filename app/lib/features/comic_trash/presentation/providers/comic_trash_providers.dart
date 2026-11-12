import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_trash_reader_session_port.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_trash_repository.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

/// Trash / purge 前关闭阅读会话的读口 token（实现由 bootstrap 注入）。
final Provider<ComicTrashNativeReaderPort> comicTrashNativeReaderPortProvider =
    requiredProvider('comicTrashNativeReaderPortProvider');

final Provider<ComicTrashRepository> comicTrashRepositoryProvider =
    requiredProvider('comicTrashRepositoryProvider');
