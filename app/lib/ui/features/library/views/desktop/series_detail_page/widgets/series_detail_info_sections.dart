import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/r18_rating_chip.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/features/library/views/desktop/comic_detail_page/widgets/comic_detail_info_sections.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/series_aggregate_notifier.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 连载状态 chip；[status] 为空时不渲染。
class SeriesSerializationChip extends StatelessWidget {
  const SeriesSerializationChip({super.key, this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final String? label = status?.trim();
    if (label == null || label.isEmpty) {
      return const SizedBox.shrink();
    }
    return OutlinedMetaChip(text: label);
  }
}

class SeriesDetailSummaryMetaRow extends StatelessWidget {
  const SeriesDetailSummaryMetaRow({
    super.key,
    required this.series,
    required this.comicsById,
  });

  final Series series;
  final Map<String, Comic> comicsById;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int count = series.items.length;
    final bool showR18 = series.hasR18Comic(comicsById: comicsById);
    final String? progressLabel = series.progressLabel;
    final List<Widget> segments = <Widget>[
      Text(
        progressLabel == null ? '$count 本' : '$count 本 · $progressLabel',
        style: TextStyle(
          fontSize: tokens.text.bodySm,
          color: cs.hentai.textSecondary,
        ),
      ),
      SeriesSerializationChip(status: series.serializationStatus.label),
    ];
    if (showR18) {
      segments.add(const R18RatingChip());
    }

    return Wrap(
      spacing: tokens.spacing.sm,
      runSpacing: tokens.spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: segments,
    );
  }
}

class SeriesDetailUserMetaEditor extends ConsumerStatefulWidget {
  const SeriesDetailUserMetaEditor({super.key, required this.series});

  final Series series;

  @override
  ConsumerState<SeriesDetailUserMetaEditor> createState() =>
      _SeriesDetailUserMetaEditorState();
}

class _SeriesDetailUserMetaEditorState
    extends ConsumerState<SeriesDetailUserMetaEditor> {
  late SerializationStatus _serializationStatus;
  late TextEditingController _totalCountController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _serializationStatus = widget.series.serializationStatus;
    _totalCountController = TextEditingController(
      text: widget.series.totalCount?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant SeriesDetailUserMetaEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series.id != widget.series.id) {
      _serializationStatus = widget.series.serializationStatus;
      _totalCountController.text = widget.series.totalCount?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _totalCountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    final String rawTotal = _totalCountController.text.trim();
    int? totalCount;
    var clearTotalCount = false;
    if (rawTotal.isEmpty) {
      clearTotalCount = widget.series.totalCount != null;
    } else {
      totalCount = int.tryParse(rawTotal);
      if (totalCount == null || totalCount <= 0) {
        if (mounted) {
          showInfoToast(context, '计划总卷数须为正整数，留空表示不设置');
        }
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await ref.read(librarySeriesRepoProvider).updateUserMeta(
            seriesId: widget.series.id,
            serializationStatus: _serializationStatus,
            totalCount: totalCount,
            clearTotalCount: clearTotalCount,
          );
      ref.read(seriesAggregateProvider.notifier).refreshAllSeries();
      if (mounted) {
        showSuccessToast(context, '系列信息已保存');
      }
    } catch (error) {
      if (mounted) {
        showErrorToast(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spacing.sm,
      children: <Widget>[
        Text(
          '连载信息',
          style: TextStyle(
            fontSize: tokens.text.bodySm,
            fontWeight: FontWeight.w600,
            color: cs.hentai.textSecondary,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.md,
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<SerializationStatus>(
                value: _serializationStatus,
                decoration: const InputDecoration(
                  labelText: '连载状态',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: SerializationStatus.values
                    .map(
                      (SerializationStatus status) =>
                          DropdownMenuItem<SerializationStatus>(
                        value: status,
                        child: Text(status.label),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (SerializationStatus? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _serializationStatus = value);
                      },
              ),
            ),
            Expanded(
              child: TextField(
                controller: _totalCountController,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '计划总卷数',
                  hintText: '留空表示未知',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
          ],
        ),
        if (widget.series.folderPath.isNotEmpty)
          Text(
            '文件夹：${widget.series.folderPath}',
            style: TextStyle(
              fontSize: tokens.text.labelXs,
              color: cs.hentai.textTertiary,
            ),
          ),
      ],
    );
  }
}

bool seriesDetailHasMetadataBlock(
  List<SeriesItem> sortedItems,
  Map<String, Comic> comicsById,
) {
  return _aggregateAuthors(sortedItems, comicsById).isNotEmpty ||
      _aggregateTags(sortedItems, comicsById).isNotEmpty;
}

class SeriesDetailMetadataBlock extends StatelessWidget {
  const SeriesDetailMetadataBlock({
    super.key,
    required this.sortedItems,
    required this.comicsById,
  });

  final List<SeriesItem> sortedItems;
  final Map<String, Comic> comicsById;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final List<String> authors = _aggregateAuthors(sortedItems, comicsById);
    final List<String> tags = _aggregateTags(sortedItems, comicsById);
    final List<Widget> rows = <Widget>[];
    if (authors.isNotEmpty) {
      rows.add(LabeledMetaChipRow(label: '作者', items: authors));
    }
    if (tags.isNotEmpty) {
      rows.add(LabeledMetaChipRow(label: '标签', items: tags));
    }
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.spacing.md,
      children: rows,
    );
  }
}

List<String> _aggregateAuthors(
  List<SeriesItem> sortedItems,
  Map<String, Comic> comicsById,
) {
  final Set<String> seen = <String>{};
  final List<String> authors = <String>[];
  for (final SeriesItem item in sortedItems) {
    final Comic? comic = comicsById[item.comicId];
    if (comic == null) {
      continue;
    }
    for (final author in comic.authors) {
      if (seen.add(author.name)) {
        authors.add(author.name);
      }
    }
  }
  return authors;
}

List<String> _aggregateTags(
  List<SeriesItem> sortedItems,
  Map<String, Comic> comicsById,
) {
  final Set<String> seen = <String>{};
  final List<String> tags = <String>[];
  for (final SeriesItem item in sortedItems) {
    final Comic? comic = comicsById[item.comicId];
    if (comic == null) {
      continue;
    }
    for (final tag in comic.tags) {
      if (seen.add(tag.name)) {
        tags.add(tag.name);
      }
    }
  }
  return tags;
}

Map<String, Comic> comicsByIdFromList(List<Comic> comics) {
  return <String, Comic>{
    for (final Comic comic in comics) comic.comicId: comic,
  };
}
