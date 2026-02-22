import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart';
import 'package:hentai_library/domain/entity/entities.dart' as entity;
import 'package:drift/drift.dart';

// 聚合模型与领域实体之间的映射
extension ComicWithChaptersAndTagsMapper on ComicWithChaptersAndTags {
  entity.Comic toEntity() {
    return entity.Comic(
      id: comic.comicId,
      title: comic.title,
      coverUrl: comic.coverUrl,
      chapters: chapters
          .map(
            (c) => entity.Chapter(
              id: c.chapterId,
              imageDir: c.imageDir ?? '',
              pageCount: c.pageCount ?? 0,
            ),
          )
          .toList(),
      tags: tags
          .map(
            (t) => entity.CategoryTag(
              name: t.name,
              isR18: t.isR18,
              type: t.type,
            ),
          )
          .toList(),
      isR18: comic.isR18,
      description: comic.description,
      status: comic.status,
      firstPublishedAt: comic.firstPublishedAt,
      lastUpdatedAt: comic.lastUpdatedAt,
      totalViews: comic.totalViews,
    );
  }
}

// 阅读历史 Row <-> Entity 映射
extension ReadingHistoryRowToEntity on ReadingHistory {
  entity.ReadingHistory toEntity() {
    return entity.ReadingHistory(
      comicId: comicId,
      title: title,
      coverUrl: coverUrl,
      lastReadTime: lastReadTime,
      chapterId: chapterId,
      pageIndex: pageIndex,
    );
  }
}

extension ReadingHistoryEntityToCompanion on entity.ReadingHistory {
  ReadingHistoriesCompanion toCompanion() {
    return ReadingHistoriesCompanion.insert(
      comicId: comicId,
      title: title,
      coverUrl: Value.absentIfNull(coverUrl),
      lastReadTime: lastReadTime,
      chapterId: Value.absentIfNull(chapterId),
      pageIndex: Value.absentIfNull(pageIndex),
    );
  }
}

// 阅读会话 Row <-> Entity 映射（Drift ReadingSession 来自 database.dart）
extension ReadingSessionRowToEntity on ReadingSession {
  entity.ReadingSession toEntity() {
    return entity.ReadingSession(
      comicId: comicId,
      date: date,
      durationSeconds: durationSeconds,
    );
  }
}

extension ReadingSessionEntityToCompanion on entity.ReadingSession {
  ReadingSessionsCompanion toCompanion() {
    return ReadingSessionsCompanion.insert(
      comicId: comicId,
      date: date,
      durationSeconds: durationSeconds,
    );
  }
}

