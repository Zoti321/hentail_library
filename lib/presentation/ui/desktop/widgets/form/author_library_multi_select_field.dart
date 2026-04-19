import 'dart:math' as math;

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/comic/author.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/form/fluent_text_field.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const double _kAuthorMenuPanelWidth = 288;
const double _kAuthorMenuMaxHeightCap = 320;
const double _kAuthorMenuScreenHeightFraction = 0.45;

class _AuthorDropdownListStyles {
  const _AuthorDropdownListStyles._();

  static const EdgeInsets rowPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  );

  static const double iconButtonRadius = 7;
  static const Size iconButtonSize = Size(26, 26);
}

/// 全库作者多选：一行「作者 + 下拉」，触发条展示已选数量；浮层内可滚动列表。
class AuthorLibraryMultiSelectField extends ConsumerStatefulWidget {
  const AuthorLibraryMultiSelectField({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedNames,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final IconData icon;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  ConsumerState<AuthorLibraryMultiSelectField> createState() =>
      _AuthorLibraryMultiSelectFieldState();
}

class _AuthorLibraryMultiSelectFieldState
    extends ConsumerState<AuthorLibraryMultiSelectField> {
  final CustomPopupMenuController _menuController = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final AsyncValue<List<Author>> authorsAsync = ref.watch(allAuthorsProvider);
    final int n = widget.selectedNames.length;
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
                menuBuilder: () => _AuthorLibraryMenuPanel(
                  key: ValueKey<String>(widget.selectedNames.join('|')),
                  selectedNames: widget.selectedNames,
                  onAdd: widget.onAdd,
                  onRemove: widget.onRemove,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: authorsAsync.isLoading
                        ? null
                        : () => _menuController.toggleMenu(),
                    borderRadius: BorderRadius.circular(tokens.radius.md),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spacing.md,
                        vertical: tokens.spacing.sm + 2,
                      ),
                      constraints: const BoxConstraints(minHeight: 38),
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
                              n == 0 ? '选择作者…' : '已选 $n 个',
                              style: TextStyle(
                                fontSize: tokens.text.bodySm,
                                color: n == 0
                                    ? cs.textPlaceholder
                                    : cs.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ),
                          if (authorsAsync.isLoading)
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
        if (authorsAsync.hasError)
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.sm),
            child: Row(
              children: [
                Icon(LucideIcons.circleAlert, size: 14, color: cs.warning),
                SizedBox(width: tokens.spacing.sm),
                Text(
                  '作者列表加载失败',
                  style: TextStyle(
                    fontSize: tokens.text.labelXs,
                    color: cs.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(allAuthorsProvider),
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

class _AuthorLibraryMenuPanel extends ConsumerWidget {
  const _AuthorLibraryMenuPanel({
    super.key,
    required this.selectedNames,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Author>> asyncAuthors = ref.watch(allAuthorsProvider);
    return asyncAuthors.when(
      loading: () => _AuthorMenuSizedShell(
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
      error: (Object err, StackTrace? st) => _AuthorMenuSizedShell(
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
              TextButton(
                onPressed: () => ref.invalidate(allAuthorsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      data: (List<Author> authors) => _AuthorMenuWithFilter(
        authors: authors,
        selectedNames: selectedNames,
        onAdd: onAdd,
        onRemove: onRemove,
      ),
    );
  }
}

class _AuthorMenuSizedShell extends StatelessWidget {
  const _AuthorMenuSizedShell({required this.maxHeight, required this.child});

  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Container(
      width: _kAuthorMenuPanelWidth,
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

class _AuthorMenuWithFilter extends StatefulWidget {
  const _AuthorMenuWithFilter({
    required this.authors,
    required this.selectedNames,
    required this.onAdd,
    required this.onRemove,
  });

  final List<Author> authors;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<_AuthorMenuWithFilter> createState() => _AuthorMenuWithFilterState();
}

class _AuthorMenuWithFilterState extends State<_AuthorMenuWithFilter> {
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

  void _toggleAuthor(Author author) {
    setState(() {
      if (_selected.contains(author.name)) {
        _selected.remove(author.name);
        widget.onRemove(author.name);
      } else {
        _selected.add(author.name);
        widget.onAdd(author.name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final double screenH = MediaQuery.sizeOf(context).height;
    final double maxPanelHeight = math.min(
      _kAuthorMenuMaxHeightCap,
      screenH * _kAuthorMenuScreenHeightFraction,
    );
    final String query = _filterController.text.trim().toLowerCase();
    final List<Author> filtered = widget.authors
        .where(
          (Author a) => query.isEmpty || a.name.toLowerCase().contains(query),
        )
        .toList();
    return SizedBox(
      width: _kAuthorMenuPanelWidth,
      height: maxPanelHeight,
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
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.spacing.sm,
                  tokens.spacing.sm,
                  tokens.spacing.sm,
                  tokens.spacing.xs + 2,
                ),
                child: TextField(
                  controller: _filterController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: tokens.text.bodySm,
                    height: 1.3,
                    color: cs.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '筛选作者…',
                    hintStyle: TextStyle(
                      fontSize: tokens.text.bodySm,
                      height: 1.3,
                      color: cs.textPlaceholder,
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: tokens.spacing.xs),
                      child: Icon(
                        LucideIcons.search,
                        size: 14,
                        color: cs.iconSecondary,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                      maxHeight: 30,
                    ),
                    contentPadding: EdgeInsets.fromLTRB(
                      0,
                      tokens.spacing.xs + 2,
                      tokens.spacing.sm + 2,
                      tokens.spacing.xs + 2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radius.sm),
                      borderSide: BorderSide(color: cs.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radius.sm),
                      borderSide: BorderSide(color: cs.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radius.sm),
                      borderSide: BorderSide(color: cs.primary, width: 1.25),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(tokens.spacing.lg),
                          child: Text(
                            widget.authors.isEmpty
                                ? '暂无作者'
                                : (query.isEmpty ? '暂无作者' : '无匹配项'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: tokens.text.bodySm,
                              color: cs.textTertiary,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                        itemCount: filtered.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            Divider(height: 1, color: cs.borderSubtle),
                        itemBuilder: (BuildContext context, int index) {
                          final Author author = filtered[index];
                          final bool isSelected = _selected.contains(author.name);
                          return _AuthorDropdownRow(
                            author: author,
                            isSelected: isSelected,
                            onToggle: () => _toggleAuthor(author),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthorDropdownRow extends StatelessWidget {
  const _AuthorDropdownRow({
    required this.author,
    required this.isSelected,
    required this.onToggle,
  });

  final Author author;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final ButtonStyle iconButtonStyle = IconButton.styleFrom(
      minimumSize: _AuthorDropdownListStyles.iconButtonSize,
      fixedSize: _AuthorDropdownListStyles.iconButtonSize,
      padding: EdgeInsets.zero,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      overlayColor: cs.primary.withAlpha(14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          _AuthorDropdownListStyles.iconButtonRadius,
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
            padding: _AuthorDropdownListStyles.rowPadding,
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
                    author.name,
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
