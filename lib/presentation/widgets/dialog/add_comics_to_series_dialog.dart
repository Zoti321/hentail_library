import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/dialog/fluent_dialog_shell.dart';
import 'package:hentai_library/presentation/widgets/input/custom_text_field.dart';
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

  /// Cached in [initState] so [dispose] can reset the notifier without using [ref]
  /// after unmount (Riverpod forbids [Ref] in/after [State.dispose]).
  late final SeriesAddComicsDialogNotifier _addComicsNotifier;

  @override
  void initState() {
    super.initState();
    _addComicsNotifier = ref.read(seriesAddComicsDialogProvider.notifier);
    _listScrollController = ScrollController();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _addComicsNotifier.reset();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listScrollController.dispose();
    super.dispose();
    scheduleMicrotask(_addComicsNotifier.reset);
  }

  Future<void> _handleSubmit() async {
    final notifier = ref.read(seriesAddComicsDialogProvider.notifier);
    try {
      final added = await notifier.submit(
        seriesName: widget.series.name,
        existingOrders: widget.series.items.map((e) => e.order).toList(),
      );
      if (!mounted || added <= 0) return;
      Navigator.of(context).pop();
      showSuccessSnackBar(context, '已添加 $added 本漫画');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final libraryPage = ref.watch(libraryPageProvider);
    final notifier = ref.read(seriesAddComicsDialogProvider.notifier);
    final existingComicIds = widget.series.items.map((e) => e.comicId).toSet();
    Future<void>(() {
      if (!mounted) return;
      notifier.updateSource(
        comics: libraryPage.rawList,
        existingComicIds: existingComicIds,
      );
    });
    final dialogState = ref.watch(seriesAddComicsDialogProvider);
    final listHeight = (MediaQuery.of(context).size.height * 0.45).clamp(
      280.0,
      420.0,
    );

    return FluentDialogShell(
      title: '向「${widget.series.name}」添加漫画',
      width: 520,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              : Text('确认添加 (${dialogState.selectedComicIdsInOrder.length})'),
        ),
      ],
    );
  }
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
    final inSeries = state.existingComicIds.contains(id);
    final enabled = !inSeries && !state.submitting;

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
                comic.authors.join(' / '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.textTertiary, fontSize: 12),
              ),
        trailing: inSeries
            ? Text(
                '已在系列中',
                style: TextStyle(color: cs.textTertiary, fontSize: 12),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
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
                      isSelected
                          ? LucideIcons.squareCheckBig
                          : LucideIcons.square,
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
