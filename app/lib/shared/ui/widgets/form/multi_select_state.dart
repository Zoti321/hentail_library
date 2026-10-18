part of 'multi_select.dart';

class _MultiSelectState<T> extends ConsumerState<MultiSelect<T>> {
  final CustomPopupMenuController _menuController = CustomPopupMenuController();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _menuScrollController = ScrollController();
  final GlobalKey _highlightedRowKey = GlobalKey();
  late final FocusNode _inputFocusNode;
  late final ValueNotifier<List<String>> _selectedNamesNotifier;
  late final ValueNotifier<String> _filterQueryNotifier;
  late final ValueNotifier<int?> _highlightedIndexNotifier;
  List<String> _visibleRemainingNames = const <String>[];
  double _fieldWidth = 0;
  double _menuScrollOffset = 0;
  bool _menuSessionActive = false;

  @override
  void initState() {
    super.initState();
    _inputFocusNode = FocusNode(onKeyEvent: _handleInputKeyEvent);
    _selectedNamesNotifier = ValueNotifier<List<String>>(
      List<String>.of(widget.selectedNames),
    );
    _filterQueryNotifier = ValueNotifier<String>(_inputController.text);
    _highlightedIndexNotifier = ValueNotifier<int?>(null);
    _inputController.addListener(_syncFilterQuery);
    _inputFocusNode.addListener(_handleInputFocusChange);
    _menuScrollController.addListener(_storeMenuScrollOffset);
  }

  @override
  void didUpdateWidget(covariant MultiSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectedNamesNotifier();
  }

  @override
  void dispose() {
    _inputController.removeListener(_syncFilterQuery);
    _inputFocusNode.removeListener(_handleInputFocusChange);
    _menuScrollController.removeListener(_storeMenuScrollOffset);
    _inputFocusNode.dispose();
    _inputController.dispose();
    _menuScrollController.dispose();
    _selectedNamesNotifier.dispose();
    _filterQueryNotifier.dispose();
    _highlightedIndexNotifier.dispose();
    super.dispose();
  }

  void _storeMenuScrollOffset() {
    if (_menuScrollController.hasClients) {
      _menuScrollOffset = _menuScrollController.offset;
    }
  }

  void _syncFilterQuery() {
    final String next = _inputController.text;
    if (_filterQueryNotifier.value == next) {
      return;
    }
    _filterQueryNotifier.value = next;
    // Filter membership changes a lot; reset to a predictable start.
    _menuScrollOffset = 0;
    if (_menuScrollController.hasClients) {
      _menuScrollController.jumpTo(0);
    }
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
    _menuSessionActive = true;
    if (!_menuController.menuIsShowing) {
      _menuController.showMenu();
    }
  }

  void _closeMenu() {
    _menuSessionActive = false;
    if (_menuController.menuIsShowing) {
      _menuController.hideMenu();
    }
  }

  void _handleMenuVisibility(bool showing) {
    if (showing) {
      _menuSessionActive = true;
      return;
    }
    // Barrier hides before chip onPressed; defer clearing so remove can reopen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _menuController.menuIsShowing) {
        return;
      }
      _menuSessionActive = false;
      _highlightedIndexNotifier.value = null;
    });
  }

  void _reportVisibleRemaining(List<String> names) {
    final bool listChanged = !listEquals(names, _visibleRemainingNames);
    _visibleRemainingNames = List<String>.of(names);

    final int? current = _highlightedIndexNotifier.value;
    final int? next;
    if (names.isEmpty) {
      next = null;
    } else if (listChanged || current == null || current >= names.length) {
      next = 0;
    } else {
      next = current;
    }

    if (_highlightedIndexNotifier.value != next) {
      _highlightedIndexNotifier.value = next;
    }
  }

  void _highlightAt(int index, {bool scrollIntoView = false}) {
    if (index < 0 || index >= _visibleRemainingNames.length) {
      return;
    }
    if (_highlightedIndexNotifier.value != index) {
      _highlightedIndexNotifier.value = index;
    }
    if (scrollIntoView) {
      _scrollHighlightIntoView();
    }
  }

  void _scrollHighlightIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final BuildContext? rowContext = _highlightedRowKey.currentContext;
      if (rowContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        rowContext,
        alignment: 0.5,
        duration: Duration.zero,
      );
    });
  }

  void _moveHighlight(int delta) {
    if (!_menuController.menuIsShowing) {
      if (delta <= 0) {
        return;
      }
      _openMenu();
      if (_visibleRemainingNames.isNotEmpty) {
        _highlightAt(0, scrollIntoView: true);
      }
      return;
    }
    if (_visibleRemainingNames.isEmpty) {
      return;
    }
    final int current = _highlightedIndexNotifier.value ?? 0;
    final int next = (current + delta).clamp(
      0,
      _visibleRemainingNames.length - 1,
    );
    _highlightAt(next, scrollIntoView: true);
  }

  KeyEventResult _handleInputKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_inputController.value.isComposingRangeValid) {
      return KeyEventResult.ignored;
    }

    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveHighlight(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (!_menuController.menuIsShowing) {
        return KeyEventResult.ignored;
      }
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        return KeyEventResult.ignored;
      }
      final int? index = _highlightedIndexNotifier.value;
      if (index == null ||
          index < 0 ||
          index >= _visibleRemainingNames.length) {
        return KeyEventResult.ignored;
      }
      _addFromMenu(_visibleRemainingNames[index]);
      return KeyEventResult.handled;
    }
    // Chip clear: KeyDown only (no KeyRepeat) so holding the key cannot wipe
    // many selected names in one gesture.
    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.backspace ||
            key == LogicalKeyboardKey.delete)) {
      final TextEditingValue value = _inputController.value;
      if (value.text.isNotEmpty ||
          !value.selection.isCollapsed ||
          widget.selectedNames.isEmpty) {
        return KeyEventResult.ignored;
      }
      _removeSelected(widget.selectedNames.last);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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

  void _addFromMenu(String name) {
    widget.onAdd(name);
    // Align with keyboard submit: clear inline filter so the open menu shows
    // all remaining unselected candidates.
    _inputController.clear();
    _inputFocusNode.requestFocus();
  }

  void _removeSelected(String name) {
    final bool restoreMenu = _menuSessionActive;
    widget.onRemove(name);
    if (!restoreMenu) {
      return;
    }
    // Transparent CustomPopupMenu barrier hides on chip taps; reopen and
    // restore scroll so remove matches the "selection-only" retention rule.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _openMenu();
      _inputFocusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_menuScrollController.hasClients) {
          return;
        }
        final double max = _menuScrollController.position.maxScrollExtent;
        _menuScrollController.jumpTo(_menuScrollOffset.clamp(0.0, max));
      });
    });
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 14, color: cs.hentai.textTertiary),
            SizedBox(width: tokens.spacing.sm),
            Expanded(
              child: FormLabel(widget.label, trailing: widget.labelTrailing),
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.sm - 2),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            _fieldWidth = constraints.maxWidth;
            return CustomPopupMenu(
              controller: _menuController,
              barrierColor: Colors.transparent,
              pressType: PressType.singleClick,
              showArrow: false,
              verticalMargin: 4,
              menuOnChange: _handleMenuVisibility,
              menuBuilder: () => ValueListenableBuilder<List<String>>(
                valueListenable: _selectedNamesNotifier,
                builder:
                    (
                      BuildContext context,
                      List<String> selectedNames,
                      Widget? _,
                    ) {
                      return ValueListenableBuilder<String>(
                        valueListenable: _filterQueryNotifier,
                        builder:
                            (
                              BuildContext context,
                              String filterQuery,
                              Widget? _,
                            ) {
                              return _MultiSelectMenuPanel<T>(
                                // Key only on filter so selection changes do not
                                // force-rebuild the panel (which jumps scroll).
                                // Filter changes intentionally reset scroll.
                                key: ValueKey<String>(filterQuery),
                                width: _fieldWidth,
                                itemsProvider: widget.itemsProvider,
                                selectedNames: selectedNames,
                                filterQuery: filterQuery,
                                scrollController: _menuScrollController,
                                highlightedIndexListenable:
                                    _highlightedIndexNotifier,
                                highlightedRowKey: _highlightedRowKey,
                                onVisibleRemainingChanged:
                                    _reportVisibleRemaining,
                                onHighlightIndex: _highlightAt,
                                onAdd: _addFromMenu,
                                onRetry: widget.onRetry,
                                resolveName: widget.resolveName,
                                resolveSmartMatched: widget.resolveSmartMatched,
                                smartMatchedTooltip: widget.smartMatchedTooltip,
                                copy: widget.copy,
                              );
                            },
                      );
                    },
              ),
              child: CallbackShortcuts(
                bindings: <ShortcutActivator, VoidCallback>{
                  const SingleActivator(LogicalKeyboardKey.escape): _closeMenu,
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
                      constraints: BoxConstraints(minHeight: fieldMinHeight),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(tokens.radius.md),
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
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                for (final String name in widget.selectedNames)
                                  OutlinedMetaChip(
                                    text: name,
                                    onRemove: () => _removeSelected(name),
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
                                        hintText: widget.selectedNames.isEmpty
                                            ? widget.copy.inputPlaceholder
                                            : null,
                                        hintStyle: TextStyle(
                                          fontSize: tokens.text.bodySm,
                                          height: 1.35,
                                          color: cs.hentai.textPlaceholder,
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
                              padding: EdgeInsets.only(top: tokens.spacing.xs),
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
                              padding: EdgeInsets.only(top: tokens.spacing.xs),
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
        if (itemsAsync.hasError)
          Padding(
            padding: EdgeInsets.only(top: tokens.spacing.sm),
            child: Row(
              children: [
                Icon(LucideIcons.circleAlert, size: 14, color: cs.hentai.error),
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

