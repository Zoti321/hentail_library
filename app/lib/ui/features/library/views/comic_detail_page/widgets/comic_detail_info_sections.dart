import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/core/layout/detail_meta_chip_row_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/foundation/horizontal_wheel_scroll_listener.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/r18_rating_chip.dart';
import 'package:hentai_library/ui/features/library/view_models/library_search_query_parser.dart';
import 'package:hentai_library/ui/features/reader/reader.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

/// 容纳最长 meta label 的固定宽度。
const double kComicDetailMetaLabelWidth = 88;

class ComicDetailSummaryMetaRow extends ConsumerWidget {
  const ComicDetailSummaryMetaRow({super.key, required this.comic});

  final Comic comic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;
    final int? pageCount = ref
        .watch(comicImagesProvider(comicId: comic.comicId))
        .maybeWhen(
          data: (List<ReaderPageImageData> refs) => refs.length,
          orElse: () => comic.pageCount,
        );
    final String? pageLabel = pageCount == 0 || pageCount == null
        ? null
        : l10n.comicDetailPageCount(pageCount);
    final bool showR18 = comic.contentRating == ContentRating.r18;
    final String? publishedLabel = formatComicPublishedDate(
      context,
      comic.publishedAt,
    );
    final bool hasLanguages = comic.languages.isNotEmpty;

    if (pageLabel == null &&
        !showR18 &&
        publishedLabel == null &&
        !hasLanguages) {
      return const SizedBox.shrink();
    }

    final List<Widget> statSegments = <Widget>[];
    if (pageLabel != null) {
      statSegments.add(
        Text(
          pageLabel,
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            color: cs.hentai.textSecondary,
          ),
        ),
      );
    }
    if (publishedLabel != null) {
      statSegments.add(
        Text(
          publishedLabel,
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            color: cs.hentai.textSecondary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.xs,
      children: <Widget>[
        // Stack: Language → age-restriction → page count (published date nearby).
        if (hasLanguages) ComicLanguageSegments(languages: comic.languages),
        SizedBox(
          height: kDetailMetaChipRowHeight,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: showR18 ? const R18RatingChip() : const SizedBox.shrink(),
          ),
        ),
        if (statSegments.isNotEmpty)
          Wrap(
            spacing: tokens.spacing.sm,
            runSpacing: tokens.spacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: statSegments,
          ),
      ],
    );
  }
}

/// Cover-right Language 分段文案；点击跳转搜索结果（与 Tag/Author 相同的精确元数据查询）。
class ComicLanguageSegments extends StatelessWidget {
  const ComicLanguageSegments({super.key, required this.languages});

  final List<String> languages;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < languages.length; i++) {
      if (i > 0) {
        children.add(
          Text(
            '|',
            style: TextStyle(
              fontSize: tokens.text.bodySm,
              color: cs.hentai.textSecondary,
            ),
          ),
        );
      }
      final String canonical = languages[i];
      children.add(
        _ComicLanguageSegmentLink(
          label: l10n.comicLanguageLabel(canonical),
          onTap: () {
            final String query = formatLibrarySearchExactMetaQuery(canonical);
            final String encoded = Uri.encodeQueryComponent(query);
            appRouter.push('/searched?q=$encoded');
          },
        ),
      );
    }
    return Wrap(
      spacing: 0,
      runSpacing: tokens.spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class _ComicLanguageSegmentLink extends HookWidget {
  const _ComicLanguageSegmentLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ValueNotifier<bool> hovered = useState(false);
    final Color color = hovered.value
        ? cs.primary
        : cs.hentai.textSecondary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => hovered.value = true,
      onExit: (_) => hovered.value = false,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            color: color,
            decoration: hovered.value
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: color,
          ),
        ),
      ),
    );
  }
}

/// 主信息区概要：无标签纯文本，最多 4 行。
class ComicDetailDescription extends StatelessWidget {
  const ComicDetailDescription({super.key, required this.comic});

  final Comic comic;

  @override
  Widget build(BuildContext context) {
    final String? text = comic.description?.trim();
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Text(
      text,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: tokens.text.bodySm,
        color: cs.hentai.textSecondary,
        height: 1.45,
      ),
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
    final AppLocalizations l10n = context.l10n;
    final List<String> authors = comic.authors.map((a) => a.name).toList();
    final List<String> tags = comic.tags.map((t) => t.name).toList();
    final List<Widget> rows = <Widget>[];
    // Order: Parody → Author → Character → Tag.
    if (comic.parodies.isNotEmpty) {
      rows.add(
        LabeledMetaChipRow(
          label: l10n.comicDetailParodies,
          items: comic.parodies,
        ),
      );
    }
    if (authors.isNotEmpty) {
      rows.add(
        LabeledMetaChipRow(label: l10n.comicDetailAuthors, items: authors),
      );
    }
    if (comic.characters.isNotEmpty) {
      rows.add(
        LabeledMetaChipRow(
          label: l10n.comicDetailCharacters,
          items: comic.characters,
        ),
      );
    }
    if (tags.isNotEmpty) {
      rows.add(LabeledMetaChipRow(label: l10n.comicDetailTags, items: tags));
    }
    rows.add(
      ComicDetailInfoRow(
        label: l10n.comicDetailResourceFormat,
        value: comic.resourceType.name.toUpperCase(),
      ),
    );
    rows.add(
      ComicDetailInfoRow(
        label: l10n.comicDetailResourceSize,
        value: formatComicResourceSize(comic.resourceSize),
      ),
    );
    rows.add(
      ComicDetailInfoRow(
        label: l10n.comicDetailResourcePath,
        value: comic.path,
        tooltip: comic.path,
      ),
    );
    final String? createdLabel = formatComicDetailDateTime(
      context,
      comic.createdAt,
    );
    if (createdLabel != null) {
      rows.add(
        ComicDetailInfoRow(label: l10n.comicDetailAddedAt, value: createdLabel),
      );
    }
    final String? updatedLabel = formatComicDetailDateTime(
      context,
      comic.lastUpdatedAt,
    );
    if (updatedLabel != null) {
      rows.add(
        ComicDetailInfoRow(
          label: l10n.comicDetailUpdatedAt,
          value: updatedLabel,
        ),
      );
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

class LabeledMetaChipRow extends HookWidget {
  const LabeledMetaChipRow({
    super.key,
    required this.label,
    required this.items,
    this.onItemTap,
  });

  final String label;
  final List<String> items;

  /// 为 null 时走库页精确元数据搜索（Author/Tag/Parody/Character）；非 null 时由调用方处理。
  final ValueChanged<String>? onItemTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final ScrollController scrollController = useScrollController();
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
          child: HorizontalWheelScrollListener(
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: tokens.spacing.sm,
                children: items
                    .map(
                      (String item) => OutlinedMetaChip(
                        text: item,
                        onTap: () {
                          final ValueChanged<String>? custom = onItemTap;
                          if (custom != null) {
                            custom(item);
                            return;
                          }
                          final String query =
                              formatLibrarySearchExactMetaQuery(item);
                          final String encoded = Uri.encodeQueryComponent(
                            query,
                          );
                          appRouter.push('/searched?q=$encoded');
                        },
                      ),
                    )
                    .toList(),
              ),
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

String? formatComicPublishedDate(BuildContext context, DateTime? date) {
  if (date == null) {
    return null;
  }
  final String locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).format(date.toLocal());
}

String? formatComicDetailDateTime(BuildContext context, DateTime? date) {
  if (date == null) {
    return null;
  }
  final String locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).add_Hm().format(date.toLocal());
}
