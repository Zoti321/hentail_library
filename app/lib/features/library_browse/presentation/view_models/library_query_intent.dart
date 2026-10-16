import 'package:hentai_library/domain/models/enums.dart';

/// Intent 层：只表达「用户想看什么」，不处理数据源订阅与派生计算。
class LibraryQueryIntent {
  LibraryQueryIntent({
    this.keyword = '',
    this.displayTarget = LibraryDisplayTarget.comics,
  });

  final String keyword;
  final LibraryDisplayTarget displayTarget;

  LibraryQueryIntent copyWith({
    String? keyword,
    LibraryDisplayTarget? displayTarget,
  }) {
    return LibraryQueryIntent(
      keyword: keyword ?? this.keyword,
      displayTarget: displayTarget ?? this.displayTarget,
    );
  }
}
