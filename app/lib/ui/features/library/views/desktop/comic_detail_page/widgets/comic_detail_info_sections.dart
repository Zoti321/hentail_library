import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/r18_rating_chip.dart';
import 'package:hentai_library/ui/features/reader/reader.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

/// 容纳「最后修改时间」等最长 label。
const double kComicDetailMetaLabelWidth = 88;

final DateFormat _comicDetailDateTimeFormat = DateFormat('yyyy年MM月dd日 HH:mm');

class ComicDetailSummaryMetaRow extends ConsumerWidget {
  const ComicDetailSummaryMetaRow({super.key, required this.comic});

  final Comic comic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int? pageCount = ref
        .watch(comicImagesProvider(comicId: comic.comicId))
        .maybeWhen(
          data: (List<ReaderPageImageData> refs) => refs.length,
          orElse: () => comic.pageCount,
        );
    final String? pageLabel = pageCount == 0 ? null : '$pageCount 页';
    final bool showR18 = comic.contentRating == ContentRating.r18;
    final String? publishedLabel = formatComicPublishedDate(comic.publishedAt);

    if (pageLabel == null && !showR18 && publishedLabel == null) {
      return const SizedBox.shrink();
    }

    final List<Widget> segments = <Widget>[];
    if (pageLabel != null) {
      segments.add(
        Text(
          pageLabel,
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            color: cs.hentai.textSecondary,
          ),
        ),
      );
    }
    if (showR18) {
      segments.add(const R18RatingChip());
    }
    if (publishedLabel != null) {
      segments.add(
        Text(
          publishedLabel,
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            color: cs.hentai.textSecondary,
          ),
        ),
      );
    }

    return Wrap(
      spacing: tokens.spacing.sm,
      runSpacing: tokens.spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: segments,
    );
  }
}

/// 作者、标签与资源信息统一信息区。
class ComicDetailMetadataBlock extends StatelessWidget {
  const ComicDetailMetadataBlock({super.key, required this.comic});

  final Comic comic;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final List<String> authors = comic.authors.map((a) => a.name).toList();
    final List<String> tags = comic.tags.map((t) => t.name).toList();
    final List<Widget> rows = <Widget>[];
    if (authors.isNotEmpty) {
      rows.add(LabeledMetaChipRow(label: '作者', items: authors));
    }
    if (tags.isNotEmpty) {
      rows.add(LabeledMetaChipRow(label: '标签', items: tags));
    }
    if (comic.description != null && comic.description!.trim().isNotEmpty) {
      rows.add(
        ComicDetailInfoRow(label: '概要', value: comic.description!.trim()),
      );
    }
    rows.add(
      ComicDetailInfoRow(
        label: '资源格式',
        value: comic.resourceType.name.toUpperCase(),
      ),
    );
    rows.add(
      ComicDetailInfoRow(
        label: '资源大小',
        value: formatComicResourceSize(comic.resourceSize),
      ),
    );
    rows.add(
      ComicDetailInfoRow(
        label: '资源路径',
        value: comic.path,
        tooltip: comic.path,
      ),
    );
    final String? createdLabel = formatComicDetailDateTime(comic.createdAt);
    if (createdLabel != null) {
      rows.add(ComicDetailInfoRow(label: '添加时间', value: createdLabel));
    }
    final String? updatedLabel = formatComicDetailDateTime(comic.lastUpdatedAt);
    if (updatedLabel != null) {
      rows.add(ComicDetailInfoRow(label: '更新时间', value: updatedLabel));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spacing.md,
      children: rows,
    );
  }
}


String formatComicResourceSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

class LabeledMetaChipRow extends StatelessWidget {
  const LabeledMetaChipRow({super.key, required this.label, required this.items});

  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: kComicDetailMetaLabelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontSize: tokens.text.bodySm,
              color: cs.hentai.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: tokens.spacing.lg),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: tokens.spacing.sm,
              children: items
                  .map((String item) => OutlinedMetaChip(text: item))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class ComicDetailInfoRow extends StatelessWidget {
  const ComicDetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.tooltip,
  });

  final String label;
  final String value;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    Widget valueWidget = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: tokens.text.bodySm,
        color: cs.hentai.textSecondary,
      ),
    );
    final String? tip = tooltip ?? (value.length > 48 ? value : null);
    if (tip != null && tip.isNotEmpty) {
      valueWidget = Tooltip(
        message: tip,
        waitDuration: const Duration(milliseconds: 500),
        child: valueWidget,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: kComicDetailMetaLabelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontSize: tokens.text.bodySm,
              color: cs.hentai.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: tokens.spacing.lg),
        Expanded(child: valueWidget),
      ],
    );
  }
}

String? formatComicPublishedDate(DateTime? date) {
  if (date == null) {
    return null;
  }
  return DateFormat('yyyy年MM月dd日').format(date.toLocal());
}

String? formatComicDetailDateTime(DateTime? date) {
  if (date == null) {
    return null;
  }
  return _comicDetailDateTimeFormat.format(date.toLocal());
}
