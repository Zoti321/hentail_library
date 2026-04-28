import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/model/entity/comic/author.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/entity/comic/tag.dart';
import 'package:hentai_library/model/entity/reading_history.dart';
import 'package:hentai_library/model/enums.dart';
import 'package:hentai_library/model/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/presentation/dto/comic_cover_display_data.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_page_comics_providers.dart';
import 'package:hentai_library/presentation/providers/pages/reader/reader_page_notifier.dart';
import 'package:hentai_library/presentation/providers/pages/tag_management/tag_management_notifier.dart';
import 'package:hentai_library/presentation/providers/usecases/comic_meta.dart';
import 'package:hentai_library/presentation/providers/usecases/sync_library.dart';
import 'package:hentai_library/presentation/ui/shared/routing/reader_route_args.dart';

class MobileComicDetailPage extends ConsumerWidget {
  const MobileComicDetailPage({super.key, required this.comicId});
  final String comicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Comic>> rawData = ref.watch(
      libraryRawComicsAsyncProvider,
    );
    return rawData.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('漫画详情')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('加载失败：$error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: ref.read(libraryRefreshActionProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      data: (List<Comic> comics) {
        final Comic? comic = comics.firstWhereOrNull(
          (Comic item) => item.comicId == comicId,
        );
        if (comic == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('漫画详情')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('漫画不存在或已被移除'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go('/local'),
                    child: const Text('返回漫画库'),
                  ),
                ],
              ),
            ),
          );
        }
        return _MobileComicDetailBody(comic: comic);
      },
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
    );
  }
}

class _MobileComicDetailBody extends ConsumerWidget {
  const _MobileComicDetailBody({required this.comic});
  final Comic comic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ComicCoverDisplayData? coverData = ref
        .watch(comicCoverDisplayProvider(comicId: comic.comicId))
        .maybeWhen(
          data: (ComicCoverDisplayData? value) => value,
          orElse: () => null,
        );
    final int? computedPageCount = ref
        .watch(comicImagesProvider(comicId: comic.comicId))
        .maybeWhen(
          data: (List<ReaderPageImageData> refs) => refs.length,
          orElse: () => comic.pageCount,
        );
    final String authorsText = comic.authors.isEmpty
        ? '未知'
        : comic.authors.map((a) => a.name).join(' / ');
    final String pageText = computedPageCount == null || computedPageCount == 0
        ? '未知'
        : '$computedPageCount 页';
    final String ratingText = _resolveContentRatingLabel(comic.contentRating);
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(comic.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 110,
                      height: 160,
                      child: _buildMobileCoverImage(theme, coverData),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          comic.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text('作者：$authorsText'),
                        const SizedBox(height: 6),
                        Text('页数：$pageText'),
                        const SizedBox(height: 6),
                        Text('格式：${comic.resourceType.name.toUpperCase()}'),
                        const SizedBox(height: 6),
                        Text('分级：$ratingText'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _TagSection(tags: comic.tags),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(recordReadingProgressUseCaseProvider)
                            .call(
                              ReadingHistory(
                                comicId: comic.comicId,
                                title: comic.title,
                                lastReadTime: DateTime.now(),
                              ),
                            );
                        if (!context.mounted) {
                          return;
                        }
                        context.pushNamed(
                          ReaderRouteArgs.readerRouteName,
                          queryParameters: ReaderRouteArgs(
                            comicId: comic.comicId,
                            readType: ReaderRouteArgs.readTypeComic,
                          ).toQueryParameters(),
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('开始阅读'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext sheetContext) {
                          return _EditMetadataSheet(comic: comic);
                        },
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('编辑元数据'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCoverImage(
    ThemeData theme,
    ComicCoverDisplayData? coverData,
  ) {
    final Widget placeholder = ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.image_not_supported_outlined),
    );
    if (coverData == null) {
      return placeholder;
    }
    final Uint8List? memory = coverData.memoryBytes;
    if (memory != null) {
      return Image.memory(
        memory,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return placeholder;
            },
      );
    }
    final String? path = coverData.filePath;
    if (path == null) {
      return placeholder;
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return placeholder;
          },
    );
  }
}

class _TagSection extends StatelessWidget {
  const _TagSection({required this.tags});
  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('标签', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (tags.isEmpty) const Text('暂无标签'),
            if (tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
                    .map((Tag tag) => Chip(label: Text(tag.name)))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditMetadataSheet extends ConsumerStatefulWidget {
  const _EditMetadataSheet({required this.comic});
  final Comic comic;

  @override
  ConsumerState<_EditMetadataSheet> createState() => _EditMetadataSheetState();
}

class _EditMetadataSheetState extends ConsumerState<_EditMetadataSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _authorsController;
  final Set<String> _selectedTagNames = <String>{};
  bool _isR18 = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.comic.title);
    _authorsController = TextEditingController(
      text: widget.comic.authors.map((a) => a.name).join(', '),
    );
    _selectedTagNames.addAll(widget.comic.tags.map((Tag item) => item.name));
    _isR18 = widget.comic.contentRating == ContentRating.r18;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Tag>> allTagsAsync = ref.watch(allTagsProvider);
    final EdgeInsets insets = EdgeInsets.only(
      bottom: MediaQuery.viewInsetsOf(context).bottom,
    );
    return SafeArea(
      child: Padding(
        padding: insets,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('编辑元数据', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '标题',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _authorsController,
                  decoration: const InputDecoration(
                    labelText: '作者（使用英文逗号分隔）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isR18,
                  onChanged: (bool value) {
                    setState(() => _isR18 = value);
                  },
                  title: const Text('R18'),
                ),
                const SizedBox(height: 8),
                Text('标签', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                allTagsAsync.when(
                  data: (List<Tag> tags) {
                    if (tags.isEmpty) {
                      return const Text('暂无标签可选');
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((Tag tag) {
                        final bool selected = _selectedTagNames.contains(
                          tag.name,
                        );
                        return FilterChip(
                          label: Text(tag.name),
                          selected: selected,
                          onSelected: (bool value) {
                            setState(() {
                              if (value) {
                                _selectedTagNames.add(tag.name);
                              } else {
                                _selectedTagNames.remove(tag.name);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  ),
                  error: (Object error, StackTrace stackTrace) {
                    return Text('标签加载失败：$error');
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _saveMetadata,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('保存'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveMetadata() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      final List<Author> authors = _authorsController.text
          .split(',')
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .map((String item) => Author(name: item))
          .toList();
      final List<Tag> selectedTags = _selectedTagNames
          .map((String name) => Tag(name: name))
          .toList();
      final ComicMetadataForm form = ComicMetadataForm(
        title: title,
        isR18: _isR18,
        tags: selectedTags,
        authors: authors,
      );
      await ref
          .read(updateComicMetadataUseCaseProvider)
          .call(widget.comic.comicId, form);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('元数据已保存')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

String _resolveContentRatingLabel(ContentRating rating) {
  switch (rating) {
    case ContentRating.unknown:
      return '未知';
    case ContentRating.safe:
      return '全年龄';
    case ContentRating.r18:
      return 'R18';
  }
}
