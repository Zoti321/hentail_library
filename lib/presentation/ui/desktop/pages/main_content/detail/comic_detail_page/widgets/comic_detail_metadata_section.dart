import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/providers/pages/reader/reader_page_notifier.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/chip/content_rating_chip.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/chip/tag_chip.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const int kComicDetailTagsCollapsedMaxCount = 8;

class ComicDetailMetadataSection extends HookConsumerWidget {
  const ComicDetailMetadataSection({super.key, required this.comic});
  final Comic comic;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int? pageCount = ref
        .watch(comicImagesProvider(comicId: comic.comicId))
        .maybeWhen(
          data: (List<ReaderPageImageData> refs) => refs.length,
          orElse: () => comic.pageCount,
        );
    final List<String> tags = comic.tags.map((t) => t.name).toList();
    final List<String> authors = comic.authors.map((a) => a.name).toList();
    final String pageLabel = pageCount == null || pageCount == 0
        ? '未知'
        : '$pageCount 页';
    final String formatLabel = comic.resourceType.name.toUpperCase();
    final AppThemeTokens tokens = context.tokens;

    final List<Widget> statChildren = <Widget>[
      _StatRow(icon: LucideIcons.files, label: '页数', value: pageLabel),
      _StatRow(icon: LucideIcons.package, label: '资源格式', value: formatLabel),
      _StatWidgetRow(
        icon: LucideIcons.shield,
        label: '分级',
        child: ContentRatingChip(rating: comic.contentRating),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _MetadataLabeledRow(
          label: '作者',
          child: _MetaTagSection(items: authors, emptyText: '暂无作者'),
        ),
        SizedBox(height: tokens.spacing.sm + 6),
        _MetadataLabeledRow(
          label: '标签',
          child: _TagsExpandableSection(tags: tags),
        ),
        SizedBox(height: tokens.spacing.lg),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.md,
            vertical: tokens.spacing.md,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(120),
            borderRadius: BorderRadius.circular(tokens.radius.md + 2),
            border: Border.all(color: cs.borderSubtle.withAlpha(180)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < statChildren.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i < statChildren.length - 1 ? tokens.spacing.sm : 0,
                  ),
                  child: statChildren[i],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  static const double kStatLabelWidth = 72;
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 17, color: cs.iconSecondary),
        SizedBox(width: tokens.spacing.sm),
        SizedBox(
          width: kStatLabelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontSize: tokens.text.labelXs,
              color: cs.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: tokens.text.bodySm,
              color: cs.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatWidgetRow extends StatelessWidget {
  const _StatWidgetRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  static const double kStatLabelWidth = 72;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 17, color: cs.iconSecondary),
        SizedBox(width: tokens.spacing.sm),
        SizedBox(
          width: kStatLabelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontSize: tokens.text.labelXs,
              color: cs.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ],
    );
  }
}

class _MetadataLabeledRow extends StatelessWidget {
  const _MetadataLabeledRow({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: tokens.text.labelXs,
            color: cs.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: tokens.spacing.sm - 2),
        child,
      ],
    );
  }
}

class _TagsExpandableSection extends HookWidget {
  const _TagsExpandableSection({required this.tags});
  final List<String> tags;
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final expanded = useState<bool>(false);
    final AppThemeTokens tokens = context.tokens;
    if (tags.isEmpty) {
      return Text(
        '暂无标签',
        style: TextStyle(fontSize: tokens.text.labelXs, color: cs.textTertiary),
      );
    }
    final bool needsToggle = tags.length > kComicDetailTagsCollapsedMaxCount;
    final List<String> shown = needsToggle && !expanded.value
        ? tags.take(kComicDetailTagsCollapsedMaxCount).toList()
        : tags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: tokens.spacing.sm + 2,
          runSpacing: tokens.spacing.sm + 2,
          children: shown.map((String e) => TagChip(text: e)).toList(),
        ),
        if (needsToggle) ...<Widget>[
          SizedBox(height: tokens.spacing.sm + 2),
          TextButton.icon(
            onPressed: () => expanded.value = !expanded.value,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacing.sm,
                vertical: tokens.spacing.md,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: cs.primary,
            ),
            icon: Icon(
              expanded.value ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 14,
            ),
            label: Text(
              expanded.value ? '收起' : '显示全部',
              style: TextStyle(
                fontSize: tokens.text.labelXs,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaTagSection extends StatelessWidget {
  const _MetaTagSection({required this.items, required this.emptyText});

  final List<String> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    if (items.isEmpty) {
      return Text(
        emptyText,
        style: TextStyle(fontSize: tokens.text.labelXs, color: cs.textTertiary),
      );
    }
    return Wrap(
      spacing: tokens.spacing.sm + 2,
      runSpacing: tokens.spacing.sm + 2,
      children: items.map((String item) => TagChip(text: item)).toList(),
    );
  }
}
