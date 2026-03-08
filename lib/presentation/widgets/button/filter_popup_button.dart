import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/domain/entity/comic/category_tag.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
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

    final resultCount = ref
        .watch(processLibraryComicsProvider)
        .when(
          data: (data) => data.length,
          error: (_, _) => 0,
          loading: () => 0,
          skipLoadingOnRefresh: true,
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
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: ref.watch(comicFilterProvider).showR18,
                  onChanged: (val) {
                    ref.read(comicFilterProvider.notifier).toggleR18(val);
                  },
                  activeColor: Colors.white,
                  activeTrackColor: Colors.red,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  trackOutlineColor: MaterialStateProperty.all(
                    Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
          _BuildTagFilterSection(menuController: menuController),
          _BuildChapterCountSection(),
          _BuildFileFormateSection(),

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
                  ref.read(comicFilterProvider.notifier).reset();
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
    final filter = ref.read(comicFilterProvider);
    final initialAnd = filter.tags?.toSet() ?? <CategoryTag>{};
    final initialAny = filter.tagsAny?.toSet() ?? <CategoryTag>{};
    final initialExclude = filter.tagsExclude?.toSet() ?? <CategoryTag>{};
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
              ref.read(comicFilterProvider.notifier).updateTagFilter(
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
    final filter = ref.watch(comicFilterProvider);
    final tags = filter.tags ?? <CategoryTag>{};
    final tagsAny = filter.tagsAny ?? <CategoryTag>{};
    final tagsExclude = filter.tagsExclude ?? <CategoryTag>{};
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
              Icon(LucideIcons.tag, size: 16, color: colorScheme.onSurfaceVariant),
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

  final Set<CategoryTag> initialAnd;
  final Set<CategoryTag> initialAny;
  final Set<CategoryTag> initialExclude;
  final ScrollController scrollController;
  final void Function(
    Set<CategoryTag> tags,
    Set<CategoryTag> tagsAny,
    Set<CategoryTag> tagsExclude,
  ) onConfirm;

  static const List<CategoryTagType> _typeOrder = [
    CategoryTagType.author,
    CategoryTagType.series,
    CategoryTagType.character,
    CategoryTagType.tag,
  ];

  @override
  ConsumerState<_TagFilterSheetContent> createState() =>
      _TagFilterSheetContentState();
}

class _TagFilterSheetContentState extends ConsumerState<_TagFilterSheetContent> {
  late Set<CategoryTag> _selectedAnd;
  late Set<CategoryTag> _selectedAny;
  late Set<CategoryTag> _selectedExclude;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedAnd = Set<CategoryTag>.from(widget.initialAnd);
    _selectedAny = Set<CategoryTag>.from(widget.initialAny);
    _selectedExclude = Set<CategoryTag>.from(widget.initialExclude);
  }

  List<CategoryTag> _filterByQuery(List<CategoryTag> tags) {
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
    final tagsAsync = ref.watch(libraryTagsByTypeProvider);

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
                  icon: Icon(LucideIcons.x, size: 20, color: colorScheme.onSurfaceVariant),
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
                prefixIcon: Icon(LucideIcons.search, size: 18, color: colorScheme.onSurfaceVariant),
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.borderSubtle),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          Divider(height: 1, color: colorScheme.borderSubtle),
          // 三块区域：同时具有 / 包含其一 / 排除
          Expanded(
            child: tagsAsync.when(
              data: (tagsByType) {
                final hasAny = tagsByType.values.any((list) => list.isNotEmpty);
                if (!hasAny) {
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
                      tagsByType,
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
                      tagsByType,
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
                      tagsByType,
                      colorScheme,
                    ),
                  ],
                );
              },
              loading: () => Center(
                child: Text(
                  "加载中…",
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              error: (_, __) => Center(
                child: Text(
                  "加载失败",
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
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
    Set<CategoryTag> selected,
    ValueChanged<CategoryTag> onToggle,
    Map<CategoryTagType, List<CategoryTag>> tagsByType,
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
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ..._TagFilterSheetContent._typeOrder.map((type) {
            final list = _filterByQuery(tagsByType[type] ?? []);
            if (list.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TagTypeBlock(
                type: type,
                tags: list,
                selectedTags: selected,
                onToggle: onToggle,
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 按类型分组的标签块（Chip 列表），供弹窗与底部面板复用。
class _TagTypeBlock extends StatelessWidget {
  const _TagTypeBlock({
    required this.type,
    required this.tags,
    required this.selectedTags,
    required this.onToggle,
  });

  final CategoryTagType type;
  final List<CategoryTag> tags;
  final Set<CategoryTag> selectedTags;
  final ValueChanged<CategoryTag> onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Text(
          type.displayName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final selected = selectedTags.contains(tag);
            return FilterChip(
              label: Text(
                tag.name,
                style: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
              selected: selected,
              onSelected: (_) => onToggle(tag),
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.primary,
              side: BorderSide(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BuildChapterCountSection extends ConsumerWidget {
  const _BuildChapterCountSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      spacing: 6,
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        Text(
          "# 章节数量",
          style: TextStyle(
            fontSize: 11,
            fontWeight: .w500,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        _FilterNumberInput(),
      ],
    );
  }
}

class _BuildFileFormateSection extends ConsumerWidget {
  const _BuildFileFormateSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      spacing: 6,
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        Text(
          "文件格式",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        ListView(
          shrinkWrap: true,
          children: <Widget>[
            ImageSourceFormatOption(
              label: "CBZ/CBR",
              isActive: true,
              onTap: () {},
            ),
            ImageSourceFormatOption(
              label: "ZIP",
              isActive: false,
              onTap: () {},
            ),
            ImageSourceFormatOption(
              label: "EPUB",
              isActive: true,
              onTap: () {},
            ),
            ImageSourceFormatOption(label: "文件夹", isActive: true, onTap: () {}),
          ],
        ),
      ],
    );
  }
}

class ImageSourceFormatOption extends HookWidget {
  const ImageSourceFormatOption({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidFunction onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isHover = useState<bool>(false);

    return MouseRegion(
      onEnter: (_) => isHover.value = true,
      onExit: (_) => isHover.value = false,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const .symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: .circular(8),
            color: isHover.value ? Colors.grey.shade100 : Colors.transparent,
          ),
          child: Row(
            spacing: 8,
            children: [
              Icon(
                isActive ? LucideIcons.squareCheckBig : LucideIcons.square,
                color: isActive
                    ? theme.colorScheme.primary
                    : Colors.grey.shade400,
                size: 14,
              ),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: .normal,
                    color: isActive
                        ? theme.colorScheme.primary
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterNumberInput extends HookWidget {
  const _FilterNumberInput();

  @override
  Widget build(BuildContext context) {
    final useNumber = useState<int>(1);

    return Container(
      padding: const .all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Padding(
            padding: .only(left: 4),
            child: Text(
              "最少章节",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
          Row(
            mainAxisSize: .min,
            spacing: 16,
            children: [
              _buildNumberOprationBtn(context, LucideIcons.minus, () {
                if (useNumber.value > 1) {
                  useNumber.value--;
                }
              }),
              SizedBox(
                width: 24,
                child: Text(
                  useNumber.value.toString(),
                  textAlign: .center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              _buildNumberOprationBtn(context, LucideIcons.plus, () {
                useNumber.value++;
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberOprationBtn(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          padding: .all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: .circular(6),
            border: Border.all(width: 1, color: Colors.grey.shade200),
          ),
          child: Icon(icon, size: 12, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}
