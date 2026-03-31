import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/domain/value_objects/library_tag_pick.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/my_toggle_switch.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FilterPopupButton extends ConsumerStatefulWidget {
  const FilterPopupButton({super.key});

  @override
  ConsumerState<FilterPopupButton> createState() => _FilterPopupButtonState();
}

class _FilterPopupButtonState extends ConsumerState<FilterPopupButton> {
  final CustomPopupMenuController controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    return CustomPopupMenu(
      controller: controller,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -16,
      menuBuilder: () => _FilterMenu(menuController: controller),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.toggleMenu(),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(LucideIcons.funnel, size: 16, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}

class _FilterMenu extends HookConsumerWidget {
  const _FilterMenu({required this.menuController});

  final CustomPopupMenuController menuController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final resultCount = ref.watch(
      libraryPageProvider.select((s) => s.displayedComics.length),
    );

    return Container(
      width: 256,
      padding: const .all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        spacing: 16,
        children: [
          // header 菜单标题栏
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              const Text(
                "高级筛选",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                onPressed: () {
                  menuController.hideMenu();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(LucideIcons.x, size: 14),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: Colors.grey.shade400,
                ),
              ),
            ],
          ),

          // body
          Row(
            spacing: 8,
            children: [
              Icon(LucideIcons.funnel, size: 16, color: Colors.grey.shade400),
              Text(
                "显示 R18 内容",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: .w400,
                  color: Colors.black87,
                ),
              ),
              Spacer(),
              MyToggleSwitch(
                checked: ref.watch(
                  libraryPageProvider.select((s) => s.effectiveFilter.showR18),
                ),
                onChange: () =>
                    ref.read(libraryPageProvider.notifier).toggleR18(),
              ),
            ],
          ),
          _BuildTagFilterSection(menuController: menuController),

          Divider(thickness: 1, color: colorScheme.borderSubtle),
          // footer 底部操作栏
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(
                "$resultCount 个结果",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(libraryPageProvider.notifier).resetFilter();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: colorScheme.primary,
                  disabledForegroundColor: colorScheme.primary.withOpacity(0.5),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text("重置所有"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 按标签筛选入口：弹窗内仅显示一行，点击后打开底部面板进行多选。
class _BuildTagFilterSection extends ConsumerWidget {
  const _BuildTagFilterSection({required this.menuController});

  final CustomPopupMenuController menuController;

  void _openTagFilterSheet(BuildContext context, WidgetRef ref) {
    menuController.hideMenu();
    final filter = ref.read(libraryPageProvider).effectiveFilter;
    final initialAnd = filter.tagsAll?.toSet() ?? <LibraryTagPick>{};
    final initialAny = filter.tagsAny?.toSet() ?? <LibraryTagPick>{};
    final initialExclude = filter.tagsExclude?.toSet() ?? <LibraryTagPick>{};
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Consumer(
          builder: (_, ref, __) => _TagFilterSheetContent(
            initialAnd: initialAnd,
            initialAny: initialAny,
            initialExclude: initialExclude,
            scrollController: scrollController,
            onConfirm: (tags, tagsAny, tagsExclude) {
              ref
                  .read(libraryPageProvider.notifier)
                  .updateTagFilter(
                    tags: tags,
                    tagsAny: tagsAny,
                    tagsExclude: tagsExclude,
                  );
              Navigator.pop(sheetContext);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final filter = ref.watch(
      libraryPageProvider.select((s) => s.effectiveFilter),
    );
    final tags = filter.tagsAll ?? <LibraryTagPick>{};
    final tagsAny = filter.tagsAny ?? <LibraryTagPick>{};
    final tagsExclude = filter.tagsExclude ?? <LibraryTagPick>{};
    final count = tags.length + tagsAny.length + tagsExclude.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openTagFilterSheet(context, ref),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(
                LucideIcons.tag,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                "按标签筛选",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                count > 0 ? "已选 $count 项" : "选择",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部面板内容：三块区域（同时具有 / 包含其一 / 排除）、搜索、清除/确定。
class _TagFilterSheetContent extends ConsumerStatefulWidget {
  const _TagFilterSheetContent({
    required this.initialAnd,
    required this.initialAny,
    required this.initialExclude,
    required this.scrollController,
    required this.onConfirm,
  });

  final Set<LibraryTagPick> initialAnd;
  final Set<LibraryTagPick> initialAny;
  final Set<LibraryTagPick> initialExclude;
  final ScrollController scrollController;
  final void Function(
    Set<LibraryTagPick> tags,
    Set<LibraryTagPick> tagsAny,
    Set<LibraryTagPick> tagsExclude,
  )
  onConfirm;

  @override
  ConsumerState<_TagFilterSheetContent> createState() =>
      _TagFilterSheetContentState();
}

class _TagFilterSheetContentState
    extends ConsumerState<_TagFilterSheetContent> {
  late Set<LibraryTagPick> _selectedAnd;
  late Set<LibraryTagPick> _selectedAny;
  late Set<LibraryTagPick> _selectedExclude;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedAnd = Set<LibraryTagPick>.from(widget.initialAnd);
    _selectedAny = Set<LibraryTagPick>.from(widget.initialAny);
    _selectedExclude = Set<LibraryTagPick>.from(widget.initialExclude);
  }

  List<LibraryTagPick> _filterByQuery(List<LibraryTagPick> tags) {
    if (_searchQuery.trim().isEmpty) return tags;
    final q = _searchQuery.trim().toLowerCase();
    return tags.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  bool get _hasAnySelection =>
      _selectedAnd.isNotEmpty ||
      _selectedAny.isNotEmpty ||
      _selectedExclude.isNotEmpty;

  void _clearAll() {
    setState(() {
      _selectedAnd = {};
      _selectedAny = {};
      _selectedExclude = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tags = ref.watch(
      libraryPageProvider.select((s) => s.libraryTagsForFilter),
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: colorScheme.borderSubtle),
          left: BorderSide(color: colorScheme.borderSubtle),
          right: BorderSide(color: colorScheme.borderSubtle),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部：标题 + 关闭
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Text(
                  "按标签筛选",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    LucideIcons.x,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          // 搜索框
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: '搜索标签名称',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.borderSubtle),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: colorScheme.borderSubtle),
          // 三块区域：同时具有 / 包含其一 / 排除
          Expanded(
            child: Builder(
              builder: (context) {
                final visibleTags = _filterByQuery(tags);
                if (visibleTags.isEmpty) {
                  return Center(
                    child: Text(
                      "书库暂无标签",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  );
                }
                return ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    _buildSection(
                      "同时具有",
                      "漫画须包含以下全部标签",
                      _selectedAnd,
                      (tag) {
                        setState(() {
                          if (_selectedAnd.contains(tag)) {
                            _selectedAnd.remove(tag);
                          } else {
                            _selectedAnd.add(tag);
                          }
                        });
                      },
                      visibleTags,
                      colorScheme,
                    ),
                    _buildSection(
                      "包含其一",
                      "漫画须包含以下至少一个标签",
                      _selectedAny,
                      (tag) {
                        setState(() {
                          if (_selectedAny.contains(tag)) {
                            _selectedAny.remove(tag);
                          } else {
                            _selectedAny.add(tag);
                          }
                        });
                      },
                      visibleTags,
                      colorScheme,
                    ),
                    _buildSection(
                      "排除",
                      "漫画不得包含以下任一标签",
                      _selectedExclude,
                      (tag) {
                        setState(() {
                          if (_selectedExclude.contains(tag)) {
                            _selectedExclude.remove(tag);
                          } else {
                            _selectedExclude.add(tag);
                          }
                        });
                      },
                      visibleTags,
                      colorScheme,
                    ),
                  ],
                );
              },
            ),
          ),
          // 底部：清除选择 + 确定
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                spacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: _hasAnySelection ? _clearAll : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      side: BorderSide(color: colorScheme.borderSubtle),
                    ),
                    child: const Text("清除选择"),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => widget.onConfirm(
                        _selectedAnd,
                        _selectedAny,
                        _selectedExclude,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: const Text("确定"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    String subtitle,
    Set<LibraryTagPick> selected,
    ValueChanged<LibraryTagPick> onToggle,
    List<LibraryTagPick> tags,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              final isSelected = selected.contains(tag);
              return FilterChip(
                label: Text(tag.name),
                selected: isSelected,
                onSelected: (_) => onToggle(tag),
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.primary,
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
