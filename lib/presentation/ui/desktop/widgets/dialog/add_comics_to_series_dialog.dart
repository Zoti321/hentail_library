import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/custom_toast.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/dialog/fluent_dialog_shell.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/input/custom_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AddComicsToSeriesDialog extends ConsumerStatefulWidget {
  const AddComicsToSeriesDialog({super.key, required this.series});

  final Series series;

  @override
  ConsumerState<AddComicsToSeriesDialog> createState() =>
      _AddComicsToSeriesDialogState();
}

class _AddComicsToSeriesDialogState
    extends ConsumerState<AddComicsToSeriesDialog> {
  late final ScrollController _listScrollController;
  late final TextEditingController _searchController;

  late final SeriesAddComicsDialogNotifier _addComicsNotifier;

  @override
  void initState() {
    super.initState();
    _addComicsNotifier = ref.read(seriesAddComicsDialogProvider.notifier);
    _listScrollController = ScrollController();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final LibraryPageState libraryPage = ref.read(libraryPageProvider);
      _addComicsNotifier.reset();
      _addComicsNotifier.updateSource(
        comics: libraryPage.rawList,
        existingComicIdsInSeriesOrder: _existingComicIdsInSeriesOrder(
          widget.series,
        ),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listScrollController.dispose();
    super.dispose();
    scheduleMicrotask(_addComicsNotifier.reset);
  }

  String _buildSuccessMessage(SeriesAddComicsSubmitSummary summary) {
    final List<String> parts = <String>[];
    if (summary.removedFromSeriesCount > 0) {
      parts.add('已移出系列 ${summary.removedFromSeriesCount} 本');
    }
    if (summary.orderChanged) {
      parts.add('已调整顺序');
    }
    if (summary.addedCount > 0) {
      parts.add('添加 ${summary.addedCount} 本');
    }
    if (parts.isEmpty) {
      return '已更新系列';
    }
    return parts.join('，');
  }

  Future<void> _handleSubmit() async {
    final notifier = ref.read(seriesAddComicsDialogProvider.notifier);
    try {
      final SeriesAddComicsSubmitSummary? summary = await notifier.submit(
        seriesName: widget.series.name,
        existingItems: widget.series.items,
      );
      if (!mounted) {
        return;
      }
      if (summary == null) {
        return;
      }
      if (!summary.hasAnyChange) {
        Navigator.of(context).pop();
        return;
      }
      showSuccessToast(context, _buildSuccessMessage(summary));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showErrorToast(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final libraryPage = ref.watch(libraryPageProvider);
    final notifier = ref.read(seriesAddComicsDialogProvider.notifier);
    ref.listen(libraryPageProvider, (
      LibraryPageState? previous,
      LibraryPageState next,
    ) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        notifier.updateSource(
          comics: next.rawList,
          existingComicIdsInSeriesOrder: _existingComicIdsInSeriesOrder(
            widget.series,
          ),
        );
      });
    });
    final dialogState = ref.watch(seriesAddComicsDialogProvider);
    final listHeight = (MediaQuery.of(context).size.height * 0.45).clamp(
      280.0,
      420.0,
    );

    return FluentDialogShell(
      title: '管理「${widget.series.name}」中的漫画',
      width: 520,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '已在系列中的漫画打开对话框时与「已选中」相同；点击可取消选中。勾选顺序决定排序。'
            '若全部取消选中后确认，将从系列中移出当前全部漫画。',
            style: TextStyle(fontSize: 12, color: cs.textTertiary),
          ),
          const SizedBox(height: 10),
          CustomTextField(
            hintText: '搜索漫画',
            controller: _searchController,
            onChanged: notifier.setQuery,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: listHeight,
            child: !libraryPage.hasReceivedFirstEmit
                ? const Center(child: CircularProgressIndicator())
                : dialogState.visibleComics.isEmpty
                ? Center(
                    child: Text(
                      '没有可显示的漫画',
                      style: TextStyle(color: cs.textTertiary, fontSize: 13),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Scrollbar(
                      thumbVisibility: true,
                      controller: _listScrollController,
                      child: ListView.separated(
                        controller: _listScrollController,
                        padding: const EdgeInsets.only(right: 14),
                        itemCount: dialogState.visibleComics.length,
                        separatorBuilder: (context, _) =>
                            Divider(height: 1, color: cs.borderSubtle),
                        itemBuilder: (context, index) {
                          final comic = dialogState.visibleComics[index];
                          return _ComicSelectableTile(
                            comic: comic,
                            state: dialogState,
                            onToggle: () =>
                                notifier.toggleSelected(comic.comicId),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: dialogState.submitting
              ? null
              : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: dialogState.canSubmit ? _handleSubmit : null,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: dialogState.submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('确认 (${dialogState.selectedComicIdsInOrder.length})'),
        ),
      ],
    );
  }
}

/// 与 [SeriesItem.order] 升序一致的 comicId 列表（与 notifier 中 seed 顺序一致）。
List<String> _existingComicIdsInSeriesOrder(Series series) {
  final List<SeriesItem> sorted = List<SeriesItem>.from(series.items)
    ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
  return sorted.map((SeriesItem e) => e.comicId).toList();
}

class _ComicSelectableTile extends StatelessWidget {
  const _ComicSelectableTile({
    required this.comic,
    required this.state,
    required this.onToggle,
  });

  final Comic comic;
  final SeriesAddComicsDialogState state;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final id = comic.comicId;
    final orderIndex = state.selectedComicIdsInOrder.indexOf(id);
    final isSelected = orderIndex >= 0;
    final enabled = !state.submitting;

    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: cs.primary.withAlpha(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        onTap: enabled ? onToggle : null,
        title: Text(
          comic.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: cs.textPrimary, fontSize: 13),
        ),
        subtitle: comic.authors.isEmpty
            ? null
            : Text(
                comic.authors.map((a) => a.name).join(' / '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.textTertiary, fontSize: 12),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${orderIndex + 1}',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            IconButton(
              tooltip: isSelected ? '取消选中' : '选中',
              onPressed: enabled ? onToggle : null,
              style: IconButton.styleFrom(
                minimumSize: const Size(28, 28),
                fixedSize: const Size(28, 28),
                padding: EdgeInsets.zero,
                splashFactory: NoSplash.splashFactory,
                overlayColor: cs.primary.withAlpha(14),
                highlightColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(
                isSelected ? LucideIcons.squareCheckBig : LucideIcons.square,
                size: 16,
                color: enabled
                    ? (isSelected ? cs.primary : cs.textTertiary)
                    : cs.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
