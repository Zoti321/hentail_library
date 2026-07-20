import 'dart:math' as math;

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_text_field.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod/misc.dart' show ProviderListenable;

const double _kMultiSelectMenuMaxHeight = 240;

/// 漫画元数据「全库关联」多选：作者 / 标签等场景复用；差异在 [MultiSelectCopy] 与数据源。
class MultiSelectCopy {
  const MultiSelectCopy({
    required this.inputPlaceholder,
    required this.listLoadFailed,
    required this.emptyCatalog,
    required this.emptyRemaining,
  });

  final String inputPlaceholder;
  final String listLoadFailed;
  final String emptyCatalog;
  final String emptyRemaining;
}

class _MultiSelectDropdownListStyles {
  const _MultiSelectDropdownListStyles._();

  static const EdgeInsets rowPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  );
}

/// 图书馆实体多选：字段内 chip + 内联输入；浮层列出未选字典项。
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

  static const Key fieldSurfaceKey = Key('multi_select_field_surface');
  static const Key menuPanelKey = Key('multi_select_menu_panel');

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
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  late final ValueNotifier<List<String>> _selectedNamesNotifier;
  double _fieldWidth = 0;

  @override
  void initState() {
    super.initState();
    _selectedNamesNotifier = ValueNotifier<List<String>>(
      List<String>.of(widget.selectedNames),
    );
    _inputFocusNode.addListener(_handleInputFocusChange);
  }

  @override
  void didUpdateWidget(covariant MultiSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectedNamesNotifier();
  }

  @override
  void dispose() {
    _inputFocusNode.removeListener(_handleInputFocusChange);
    _inputFocusNode.dispose();
    _inputController.dispose();
    _selectedNamesNotifier.dispose();
    super.dispose();
  }

  void _syncSelectedNamesNotifier() {
    if (listEquals(_selectedNamesNotifier.value, widget.selectedNames)) {
      return;
    }
    final List<String> next = List<String>.of(widget.selectedNames);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (!listEquals(_selectedNamesNotifier.value, next)) {
        _selectedNamesNotifier.value = next;
      }
    });
  }

  void _handleInputFocusChange() {
    if (_inputFocusNode.hasFocus) {
      _openMenu();
    }
  }

  void _openMenu() {
    if (!_menuController.menuIsShowing) {
      _menuController.showMenu();
    }
  }

  void _closeMenu() {
    if (_menuController.menuIsShowing) {
      _menuController.hideMenu();
    }
  }

  void _submitInput() {
    final String trimmed = _inputController.text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    widget.onAdd(trimmed);
    _inputController.clear();
    _inputFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // Parent may mutate the same List instance; always mirror into the notifier
    // so the open overlay's ValueListenableBuilder can refresh.
    _syncSelectedNamesNotifier();

    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final AsyncValue<List<T>> itemsAsync = ref.watch(widget.itemsProvider);
    final double fieldVerticalPadding = widget.compactTrigger
        ? tokens.spacing.xs + 1
        : tokens.spacing.sm + 2;
    final double fieldMinHeight = widget.compactTrigger ? 32 : 38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: tokens.spacing.sm + 2),
              child: Icon(widget.icon, size: 14, color: cs.hentai.textTertiary),
            ),
            SizedBox(width: tokens.spacing.sm),
            Padding(
              padding: EdgeInsets.only(top: tokens.spacing.sm + 2),
              child: FormLabel(widget.label),
            ),
            SizedBox(width: tokens.spacing.md),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  _fieldWidth = constraints.maxWidth;
                  return CustomPopupMenu(
                    controller: _menuController,
                    barrierColor: Colors.transparent,
                    pressType: PressType.singleClick,
                    showArrow: false,
                    verticalMargin: 4,
                    menuBuilder: () => ValueListenableBuilder<List<String>>(
                      valueListenable: _selectedNamesNotifier,
                      builder:
                          (
                            BuildContext context,
                            List<String> selectedNames,
                            Widget? _,
                          ) {
                            return _MultiSelectMenuPanel<T>(
                              key: ValueKey<String>(selectedNames.join('|')),
                              width: _fieldWidth,
                              itemsProvider: widget.itemsProvider,
                              selectedNames: selectedNames,
                              onAdd: widget.onAdd,
                              onRetry: widget.onRetry,
                              resolveName: widget.resolveName,
                              copy: widget.copy,
                            );
                          },
                    ),
                    child: CallbackShortcuts(
                      bindings: <ShortcutActivator, VoidCallback>{
                        const SingleActivator(LogicalKeyboardKey.escape):
                            _closeMenu,
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _inputFocusNode.requestFocus();
                            _openMenu();
                          },
                          borderRadius: BorderRadius.circular(tokens.radius.md),
                          child: AnimatedContainer(
                            key: MultiSelect.fieldSurfaceKey,
                            duration: const Duration(milliseconds: 150),
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: tokens.spacing.md,
                              vertical: fieldVerticalPadding,
                            ),
                            constraints: BoxConstraints(
                              minHeight: fieldMinHeight,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(
                                tokens.radius.md,
                              ),
                              border: Border.all(
                                color: cs.hentai.borderSubtle,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.shadow,
                                  blurRadius: 1,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: tokens.spacing.xs,
                                    runSpacing: tokens.spacing.xs,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      for (final String name
                                          in widget.selectedNames)
                                        OutlinedMetaChip(
                                          text: name,
                                          onRemove: () => widget.onRemove(name),
                                        ),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minWidth: 72,
                                          maxWidth: 200,
                                        ),
                                        child: IntrinsicWidth(
                                          child: TextField(
                                            controller: _inputController,
                                            focusNode: _inputFocusNode,
                                            onSubmitted: (_) => _submitInput(),
                                            style: TextStyle(
                                              fontSize: tokens.text.bodySm,
                                              height: 1.35,
                                              color: cs.hentai.textPrimary,
                                            ),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              border: InputBorder.none,
                                              hintText:
                                                  widget.selectedNames.isEmpty
                                                  ? widget.copy.inputPlaceholder
                                                  : null,
                                              hintStyle: TextStyle(
                                                fontSize: tokens.text.bodySm,
                                                height: 1.35,
                                                color:
                                                    cs.hentai.textPlaceholder,
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (itemsAsync.isLoading)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: tokens.spacing.xs,
                                    ),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: cs.primary,
                                      ),
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: tokens.spacing.xs,
                                    ),
                                    child: Icon(
                                      LucideIcons.chevronsUpDown,
                                      size: 15,
                                      color: cs.hentai.iconSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (itemsAsync.hasError)
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.sm),
            child: Row(
              children: [
                Icon(
                  LucideIcons.circleAlert,
                  size: 14,
                  color: cs.hentai.warning,
                ),
                SizedBox(width: tokens.spacing.sm),
                Text(
                  widget.copy.listLoadFailed,
                  style: TextStyle(
                    fontSize: tokens.text.labelXs,
                    color: cs.hentai.textSecondary,
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
                  child: Text(context.l10n.commonRetry),
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
    required this.width,
    required this.itemsProvider,
    required this.selectedNames,
    required this.onAdd,
    required this.onRetry,
    required this.resolveName,
    required this.copy,
  });

  final double width;
  final ProviderListenable<AsyncValue<List<T>>> itemsProvider;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final VoidCallback onRetry;
  final String Function(T item) resolveName;
  final MultiSelectCopy copy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final AsyncValue<List<T>> asyncItems = ref.watch(itemsProvider);
    return asyncItems.when(
      loading: () => _MultiSelectMenuSizedShell(
        width: width,
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
        width: width,
        maxHeight: 148,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.commonLoadFailed,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.hentai.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
            ],
          ),
        ),
      ),
      data: (List<T> items) {
        final Set<String> selected = selectedNames.toSet();
        final List<T> remaining = items
            .where((T item) => !selected.contains(resolveName(item)))
            .toList();
        return _MultiSelectMenuList<T>(
          width: width,
          items: remaining,
          allCatalogEmpty: items.isEmpty,
          onAdd: onAdd,
          resolveName: resolveName,
          copy: copy,
        );
      },
    );
  }
}

class _MultiSelectMenuSizedShell extends StatelessWidget {
  const _MultiSelectMenuSizedShell({
    required this.width,
    required this.maxHeight,
    required this.child,
  });

  final double width;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Container(
      key: MultiSelect.menuPanelKey,
      width: width > 0 ? width : 240,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(tokens.radius.xs),
        border: Border.all(color: cs.hentai.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: cs.hentai.cardShadowHover,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.xs),
        child: child,
      ),
    );
  }
}

class _MultiSelectMenuList<T> extends StatelessWidget {
  const _MultiSelectMenuList({
    required this.width,
    required this.items,
    required this.allCatalogEmpty,
    required this.onAdd,
    required this.resolveName,
    required this.copy,
  });

  final double width;
  final List<T> items;
  final bool allCatalogEmpty;
  final ValueChanged<String> onAdd;
  final String Function(T item) resolveName;
  final MultiSelectCopy copy;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final double panelMaxHeight = math.min(
      _kMultiSelectMenuMaxHeight,
      MediaQuery.sizeOf(context).height * 0.45,
    );

    return _MultiSelectMenuSizedShell(
      width: width,
      maxHeight: panelMaxHeight,
      child: items.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spacing.lg,
                  vertical: tokens.spacing.md,
                ),
                child: Text(
                  allCatalogEmpty ? copy.emptyCatalog : copy.emptyRemaining,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: tokens.text.bodySm,
                    color: cs.hentai.textTertiary,
                  ),
                ),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(
                top: tokens.spacing.sm,
                bottom: tokens.spacing.md + 2,
              ),
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final T item = items[index];
                final String name = resolveName(item);
                return _MultiSelectDropdownRow(
                  displayName: name,
                  onSelect: () => onAdd(name),
                );
              },
            ),
    );
  }
}

class _MultiSelectDropdownRow extends StatelessWidget {
  const _MultiSelectDropdownRow({
    required this.displayName,
    required this.onSelect,
  });

  final String displayName;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

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
          onTap: onSelect,
          child: Padding(
            padding: _MultiSelectDropdownListStyles.rowPadding,
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.hentai.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
