import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/presentation/dto/comic_cover_display_data.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ComicMergeDialog extends StatefulHookConsumerWidget {
  const ComicMergeDialog({
    super.key,
    required this.currentComic,
    required this.onConfirm,
  });

  final Comic currentComic;
  final Function(List<String>) onConfirm;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ComicMergeDialogState();
}

class _ComicMergeDialogState extends ConsumerState<ComicMergeDialog> {
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = context.tokens;

    return Dialog(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
      ),
      elevation: 0,
      insetPadding: const .all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.lg + 4),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.45,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: cs.cardHover,
            borderRadius: BorderRadius.circular(tokens.radius.lg + 4),
            border: Border.all(color: cs.borderSubtle, width: 1),
            boxShadow: [
              BoxShadow(
                color: cs.cardShadowHover,
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: cs.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: 12,
            children: [
              _DialogHeader(),
              _DialogBody(
                comicId: widget.currentComic.comicId,
                selectedIds: _selectedIds,
                toggleSelection: _toggleSelection,
              ),
              _DialogFooter(
                selectedIds: _selectedIds,
                onConfirm: widget.onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends HookConsumerWidget {
  const _DialogHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const .symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.borderSubtle)),
        color: cs.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 16,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(
                "从库中添加章节",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.textPrimary,
                  fontFamily: 'Segoe UI',
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(LucideIcons.x, color: cs.iconSecondary, size: 20),
                ),
              ),
            ],
          ),
          // 搜索框
          TextField(
            onChanged: (value) =>
                ref.read(libraryPageProvider.notifier).updateMergeSearch(value),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: "搜索库...",
              hintStyle: TextStyle(color: cs.textPlaceholder, fontSize: 14),
              prefixIcon: Icon(Icons.search, size: 20, color: cs.iconSecondary),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              isDense: true,
              filled: true,
              fillColor: cs.inputBackground,
              hoverColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cs.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cs.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogBody extends HookConsumerWidget {
  const _DialogBody({
    required this.comicId,
    required this.selectedIds,
    required this.toggleSelection,
  });

  final String comicId;
  final Set<String> selectedIds;
  final void Function(String id) toggleSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final items = ref.watch(filteredMergeComicsProvider(comicId: comicId));

    return items.when(
      data: (items) => Expanded(
        child: items.isEmpty
            ? Center(
                child: Text(
                  "未找到匹配的漫画",
                  style: TextStyle(color: cs.textSecondary, fontSize: 14),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(8),
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedIds.contains(item.comicId);

                  return _MergeComicTile(
                    key: Key(item.comicId),
                    toggleSelection: toggleSelection,
                    item: item,
                    isSelected: isSelected,
                    theme: theme,
                  );
                },
              ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text('Error: $error'),
      skipLoadingOnReload: true,
    );
  }
}

class _DialogFooter extends HookConsumerWidget {
  const _DialogFooter({required this.selectedIds, required this.onConfirm});

  final Set<String> selectedIds;
  final Function(List<String>) onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasConfirmed = useState(false);

    return Container(
      padding: const .all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.borderSubtle)),
        color: cs.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisAlignment: .end,
        spacing: 8,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("取消"),
          ),
          FilledButton(
            onPressed: selectedIds.isEmpty || hasConfirmed.value
                ? null
                : () {
                    hasConfirmed.value = true;
                    onConfirm(selectedIds.toList());
                    Navigator.of(context).pop();
                  },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              disabledBackgroundColor: theme.colorScheme.primary.withAlpha(50),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0, // Fluent 设计通常是扁平或轻微投影
            ),
            child: Text(
              "添加 ${selectedIds.length} 项为章节",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _MergeComicTile extends HookConsumerWidget {
  const _MergeComicTile({
    super.key,
    required this.toggleSelection,
    required this.item,
    required this.isSelected,
    required this.theme,
  });

  final void Function(String id) toggleSelection;
  final Comic item;
  final bool isSelected;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ComicCoverDisplayData? coverData = ref
        .watch(comicCoverDisplayProvider(comicId: item.comicId))
        .maybeWhen(data: (ComicCoverDisplayData? v) => v, orElse: () => null);
    final pageCount = ref
        .watch(comicImagesProvider(comicId: item.comicId))
        .maybeWhen(data: (f) => f.length, orElse: () => 0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => toggleSelection(item.comicId),
        borderRadius: BorderRadius.circular(8),
        hoverColor: theme.colorScheme.hoverBackground,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 自定义复选框
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.borderMedium,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
              // 封面图 (Cover)
              Container(
                width: 40, // w-10
                height: 56, // h-14
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                  image: _mergeDialogCoverDecoration(coverData),
                ),
              ),
              // 信息文本
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${item.resourceType.name} • $pageCount 页",
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

DecorationImage? _mergeDialogCoverDecoration(ComicCoverDisplayData? data) {
  if (data == null) {
    return null;
  }
  final Uint8List? memory = data.memoryBytes;
  if (memory != null) {
    return DecorationImage(image: MemoryImage(memory), fit: BoxFit.cover);
  }
  final String? path = data.filePath;
  if (path != null) {
    return DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover);
  }
  return null;
}
