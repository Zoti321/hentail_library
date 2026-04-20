import 'dart:math' as math;

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/fluent_text_field.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show ProviderListenable;
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kMultiSelectMenuPanelWidth = 288;
const double _kMultiSelectMenuMaxHeightCap = 320;
const double _kMultiSelectMenuScreenHeightFraction = 0.45;
/// 为顶部搜索区预留高度，用于从面板总高中划出列表 [ConstrainedBox] 的 `maxHeight`。
const double _kMultiSelectSearchReserveHeight = 96;

/// 漫画元数据「全库关联」多选：作者 / 标签等场景复用；差异在 [MultiSelectCopy] 与数据源。
class MultiSelectCopy {
  const MultiSelectCopy({
    required this.selectPrompt,
    required this.listLoadFailed,
    required this.filterHint,
    required this.emptyCatalog,
  });

  final String selectPrompt;
  final String listLoadFailed;
  final String filterHint;
  final String emptyCatalog;
}

class _MultiSelectDropdownListStyles {
  const _MultiSelectDropdownListStyles._();

  static const EdgeInsets rowPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  );

  static const double iconButtonRadius = 7;
  static const Size iconButtonSize = Size(26, 26);

  /// 与 [_MultiSelectDropdownRow] 单行一致：上下 padding + 左侧图标区高度。
  static double get listRowHeight => rowPadding.vertical + iconButtonSize.height;
}

/// 图书馆实体多选：一行「标签 + 下拉」，触发条展示已选数量；浮层内为搜索区 + 虚拟化列表。
class MultiSelect<T> extends ConsumerStatefulWidget {
  const MultiSelect({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedNames,
    required this.onAdd,
    required this.onRemove,
    required this.itemsProvider,
    required this.onRetry,
    required this.resolveName,
    required this.copy,
    this.compactTrigger = false,
  });

  final String label;
  final IconData icon;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final ProviderListenable<AsyncValue<List<T>>> itemsProvider;
  final VoidCallback onRetry;
  final String Function(T item) resolveName;
  final MultiSelectCopy copy;
  final bool compactTrigger;

  @override
  ConsumerState<MultiSelect<T>> createState() => _MultiSelectState<T>();
}

class _MultiSelectState<T> extends ConsumerState<MultiSelect<T>> {
  final CustomPopupMenuController _menuController = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final AsyncValue<List<T>> itemsAsync = ref.watch(widget.itemsProvider);
    final int n = widget.selectedNames.length;
    final double triggerVerticalPadding = widget.compactTrigger
        ? tokens.spacing.xs + 1
        : tokens.spacing.sm + 2;
    final double triggerMinHeight = widget.compactTrigger ? 32 : 38;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 14, color: cs.textTertiary),
            SizedBox(width: tokens.spacing.sm),
            FormLabel(widget.label),
            SizedBox(width: tokens.spacing.md),
            Expanded(
              child: CustomPopupMenu(
                controller: _menuController,
                barrierColor: Colors.transparent,
                pressType: PressType.singleClick,
                showArrow: false,
                verticalMargin: 4,
                menuBuilder: () => _MultiSelectMenuPanel<T>(
                  key: ValueKey<String>(widget.selectedNames.join('|')),
                  itemsProvider: widget.itemsProvider,
                  selectedNames: widget.selectedNames,
                  onAdd: widget.onAdd,
                  onRemove: widget.onRemove,
                  onRetry: widget.onRetry,
                  resolveName: widget.resolveName,
                  copy: widget.copy,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: itemsAsync.isLoading
                        ? null
                        : () => _menuController.toggleMenu(),
                    borderRadius: BorderRadius.circular(tokens.radius.md),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spacing.md,
                        vertical: triggerVerticalPadding,
                      ),
                      constraints: BoxConstraints(minHeight: triggerMinHeight),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(tokens.radius.md),
                        border: Border.all(color: cs.borderSubtle, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow,
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              n == 0 ? widget.copy.selectPrompt : '已选 $n 个',
                              style: TextStyle(
                                fontSize: tokens.text.bodySm,
                                color: n == 0
                                    ? cs.textPlaceholder
                                    : cs.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ),
                          if (itemsAsync.isLoading)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            )
                          else
                            Icon(
                              LucideIcons.chevronsUpDown,
                              size: 15,
                              color: cs.iconSecondary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (itemsAsync.hasError)
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.sm),
            child: Row(
              children: [
                Icon(LucideIcons.circleAlert, size: 14, color: cs.warning),
                SizedBox(width: tokens.spacing.sm),
                Text(
                  widget.copy.listLoadFailed,
                  style: TextStyle(
                    fontSize: tokens.text.labelXs,
                    color: cs.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: widget.onRetry,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spacing.sm,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MultiSelectMenuPanel<T> extends ConsumerWidget {
  const _MultiSelectMenuPanel({
    super.key,
    required this.itemsProvider,
    required this.selectedNames,
    required this.onAdd,
    required this.onRemove,
    required this.onRetry,
    required this.resolveName,
    required this.copy,
  });

  final ProviderListenable<AsyncValue<List<T>>> itemsProvider;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final VoidCallback onRetry;
  final String Function(T item) resolveName;
  final MultiSelectCopy copy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<T>> asyncItems = ref.watch(itemsProvider);
    return asyncItems.when(
      loading: () => _MultiSelectMenuSizedShell(
        maxHeight: 108,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (Object err, StackTrace? st) => _MultiSelectMenuSizedShell(
        maxHeight: 148,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '加载失败',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ),
        ),
      ),
      data: (List<T> items) => _MultiSelectMenuWithFilter<T>(
        items: items,
        selectedNames: selectedNames,
        onAdd: onAdd,
        onRemove: onRemove,
        resolveName: resolveName,
        copy: copy,
      ),
    );
  }
}

class _MultiSelectMenuSizedShell extends StatelessWidget {
  const _MultiSelectMenuSizedShell({
    required this.maxHeight,
    required this.child,
  });

  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Container(
      width: _kMultiSelectMenuPanelWidth,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: cs.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: cs.cardShadowHover,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        child: child,
      ),
    );
  }
}

class _MultiSelectMenuWithFilter<T> extends StatefulWidget {
  const _MultiSelectMenuWithFilter({
    required this.items,
    required this.selectedNames,
    required this.onAdd,
    required this.onRemove,
    required this.resolveName,
    required this.copy,
  });

  final List<T> items;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final String Function(T item) resolveName;
  final MultiSelectCopy copy;

  @override
  State<_MultiSelectMenuWithFilter<T>> createState() =>
      _MultiSelectMenuWithFilterState<T>();
}

class _MultiSelectMenuWithFilterState<T>
    extends State<_MultiSelectMenuWithFilter<T>> {
  final TextEditingController _filterController = TextEditingController();

  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.selectedNames);
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _toggleItem(T item) {
    final String name = widget.resolveName(item);
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
        widget.onRemove(name);
      } else {
        _selected.add(name);
        widget.onAdd(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final double screenH = MediaQuery.sizeOf(context).height;
    final double maxPanelHeight = math.min(
      _kMultiSelectMenuMaxHeightCap,
      screenH * _kMultiSelectMenuScreenHeightFraction,
    );
    final String query = _filterController.text.trim().toLowerCase();
    final List<T> filtered = widget.items.where((T item) {
      final String name = widget.resolveName(item);
      return query.isEmpty || name.toLowerCase().contains(query);
    }).toList();
    final double listMaxHeight = math.max(
      64,
      maxPanelHeight - _kMultiSelectSearchReserveHeight,
    );
    return SizedBox(
      width: _kMultiSelectMenuPanelWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(tokens.radius.lg),
          border: Border.all(color: cs.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: cs.cardShadowHover,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radius.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.spacing.sm,
                  tokens.spacing.md + 2,
                  tokens.spacing.sm,
                  tokens.spacing.sm,
                ),
                child: _MultiSelectSearchField(
                  controller: _filterController,
                  filterHint: widget.copy.filterHint,
                  onQueryChanged: (_) => setState(() {}),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: listMaxHeight),
                child: _MultiSelectVirtualizedList<T>(
                  filteredItems: filtered,
                  allItemsEmpty: widget.items.isEmpty,
                  query: query,
                  selected: _selected,
                  resolveName: widget.resolveName,
                  emptyCatalogLabel: widget.copy.emptyCatalog,
                  onToggle: _toggleItem,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultiSelectSearchField extends StatelessWidget {
  const _MultiSelectSearchField({
    required this.controller,
    required this.filterHint,
    required this.onQueryChanged,
  });

  final TextEditingController controller;
  final String filterHint;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final double rowH = _MultiSelectDropdownListStyles.listRowHeight;
    const double borderWidth = 1;
    final double innerH = rowH - borderWidth * 2;
    final double textLineH = tokens.text.bodySm * 1.3;
    final double vPad = (innerH - textLineH) / 2;
    return SizedBox(
      height: rowH,
      child: TextField(
        controller: controller,
        onChanged: onQueryChanged,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontSize: tokens.text.bodySm,
          height: 1.3,
          color: cs.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: filterHint,
          hintStyle: TextStyle(
            fontSize: tokens.text.bodySm,
            height: 1.3,
            color: cs.textPlaceholder,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: tokens.spacing.xs),
            child: Icon(LucideIcons.search, size: 14, color: cs.iconSecondary),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: 30,
            minHeight: _MultiSelectDropdownListStyles.iconButtonSize.height,
            maxHeight: _MultiSelectDropdownListStyles.iconButtonSize.height,
          ),
          contentPadding: EdgeInsets.fromLTRB(
            0,
            vPad,
            tokens.spacing.sm + 2,
            vPad,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radius.md),
            borderSide: BorderSide(color: cs.borderSubtle, width: borderWidth),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radius.md),
            borderSide: BorderSide(color: cs.borderSubtle, width: borderWidth),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radius.md),
            borderSide: BorderSide(color: cs.primary, width: borderWidth),
          ),
        ),
      ),
    );
  }
}

class _MultiSelectVirtualizedList<T> extends StatelessWidget {
  const _MultiSelectVirtualizedList({
    required this.filteredItems,
    required this.allItemsEmpty,
    required this.query,
    required this.selected,
    required this.resolveName,
    required this.emptyCatalogLabel,
    required this.onToggle,
  });

  final List<T> filteredItems;
  final bool allItemsEmpty;
  final String query;
  final Set<String> selected;
  final String Function(T item) resolveName;
  final String emptyCatalogLabel;
  final ValueChanged<T> onToggle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    if (filteredItems.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.lg,
            vertical: 0,
          ),
          child: Text(
            allItemsEmpty
                ? emptyCatalogLabel
                : (query.isEmpty ? emptyCatalogLabel : '无匹配项'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: tokens.text.bodySm,
              color: cs.textTertiary,
            ),
          ),
        ),
      );
    }
    final int rowCount = filteredItems.length;
    final int itemCount = rowCount * 2 - 1;
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        top: tokens.spacing.sm,
        bottom: tokens.spacing.md + 2,
      ),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) {
        if (index.isOdd) {
          return Divider(height: 1, color: cs.borderSubtle);
        }
        final int rowIndex = index ~/ 2;
        final T item = filteredItems[rowIndex];
        final String name = resolveName(item);
        final bool isSelected = selected.contains(name);
        return _MultiSelectDropdownRow(
          displayName: name,
          isSelected: isSelected,
          onToggle: () => onToggle(item),
        );
      },
    );
  }
}

class _MultiSelectDropdownRow extends StatelessWidget {
  const _MultiSelectDropdownRow({
    required this.displayName,
    required this.isSelected,
    required this.onToggle,
  });

  final String displayName;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final ButtonStyle iconButtonStyle = IconButton.styleFrom(
      minimumSize: _MultiSelectDropdownListStyles.iconButtonSize,
      fixedSize: _MultiSelectDropdownListStyles.iconButtonSize,
      padding: EdgeInsets.zero,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      overlayColor: cs.primary.withAlpha(14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          _MultiSelectDropdownListStyles.iconButtonRadius,
        ),
      ),
    );

    return Theme(
      data: theme.copyWith(
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: cs.primary.withAlpha(10),
      ),
      child: Material(
        color: cs.surface,
        child: InkWell(
          onTap: onToggle,
          child: Padding(
            padding: _MultiSelectDropdownListStyles.rowPadding,
            child: Row(
              spacing: 10,
              children: [
                IconButton(
                  tooltip: isSelected ? '取消选择' : '选择',
                  onPressed: onToggle,
                  style: iconButtonStyle,
                  icon: Icon(
                    isSelected
                        ? LucideIcons.squareCheckBig
                        : LucideIcons.square,
                    size: 15,
                    color: isSelected ? cs.primary : cs.textTertiary,
                  ),
                ),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
