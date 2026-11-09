import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';

final Provider<AsyncValue<List<Tag>>> libraryTagDictionaryStateProvider =
    injectedDi('libraryTagDictionaryStateProvider');

final Provider<AsyncValue<List<Author>>> libraryAuthorDictionaryStateProvider =
    injectedDi('libraryAuthorDictionaryStateProvider');
