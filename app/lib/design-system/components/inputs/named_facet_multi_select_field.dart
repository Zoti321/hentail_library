import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show ValueListenable, defaultTargetPlatform, listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/components/inputs/named_facet_multi_select_copy.dart';
import 'package:hentai_library/shared/util/name_pinyin_assisted_filter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_3_expressive/components/text_fields/components/m3e_text_field_affordance.dart';
import 'package:material_3_expressive/components/text_fields/utils/m3e_text_field_selection_controls.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:motor/motor.dart';
import 'package:riverpod/misc.dart' show ProviderListenable;
import 'package:hentai_library/design-system/components/inputs/compact_input_chip.dart';
import 'package:hentai_library/design-system/components/inputs/input_chip_field_layout.dart';
import 'package:hentai_library/design-system/components/inputs/outlined_text_field_shell.dart';
import 'package:hentai_library/design-system/motion/motion.dart';

part 'named_facet_multi_select_menu.dart';

const double _kNamedFacetMultiSelectMenuMaxHeight = 240;
const double _kNamedFacetMultiSelectMenuEmptyMinHeight = 160;

/// MD3E Named facet 多选：chip + 内联输入 + 自绘候选浮层（非 [M3EDropdownMenu] 底座）。
class FacetMultiSelectField<T> extends ConsumerStatefulWidget {
  const FacetMultiSelectField({
    super.key,
    required this.label,
    required this.selectedNames,
    required this.onAdd,
    required this.onRemove,
    required this.itemsProvider,
    required this.onRetry,
    required this.resolveName,
    required this.copy,
    this.maxWidth = double.infinity,
    this.resolveSmartMatched,
    this.smartMatchedTooltip,
    this.onClearAll,
    this.clearAllTooltip,
  });

  static const Key fieldSurfaceKey = Key(
    '_named_facet_multi_select_field_surface',
  );
  static const Key menuPanelKey = Key('_named_facet_multi_select_menu_panel');
  static const Key smartMatchedHintKey = Key(
    '_named_facet_multi_select_smart_matched_hint',
  );
  static const Key clearAllButtonKey = Key(
    '_named_facet_multi_select_clear_all_button',
  );

  final String label;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final ProviderListenable<AsyncValue<List<T>>> itemsProvider;
  final VoidCallback onRetry;
  final String Function(T item) resolveName;
  final NamedFacetMultiSelectCopy copy;
  final double maxWidth;
  final bool Function(T item)? resolveSmartMatched;
  final String? smartMatchedTooltip;
  final VoidCallback? onClearAll;
  final String? clearAllTooltip;

  @override
  ConsumerState<FacetMultiSelectField<T>> createState() =>
      _NamedFacetMultiSelectFieldState<T>();
}

class _NamedFacetMultiSelectFieldState<T>
    extends ConsumerState<FacetMultiSelectField<T>>
    with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldAnchorKey = GlobalKey();
  final TextEditingController _inputController = TextEditingController();
  late final FocusNode _inputFocusNode;
  final GlobalKey<EditableTextState> _editableKey =
      GlobalKey<EditableTextState>();
  final ScrollController _menuScrollController = ScrollController();
  final GlobalKey _highlightedRowKey = GlobalKey();
  final ValueNotifier<List<String>> _selectedNamesNotifier =
      ValueNotifier<List<String>>(<String>[]);
  final ValueNotifier<String> _filterQueryNotifier = ValueNotifier<String>('');
  final ValueNotifier<int?> _highlightedIndexNotifier = ValueNotifier<int?>(
    null,
  );

  OverlayEntry? _overlayEntry;
  double _fieldWidth = 0;
  List<String> _visibleRemainingNames = const <String>[];
  bool _menuSessionActive = false;
  bool _menuOpensAbove = false;
  final Object _tapRegionGroup = Object();
  bool _highlightMovedByKeyboard = false;
  late final SingleMotionController _panelExpandCtrl;

  SpringMotion _menuPanelSpring(M3ESpring spring) {
    return MaterialSpringMotion.expressiveSpatialDefault().copyWith(
      stiffness: spring.stiffness,
      damping: spring.damping,
    );
  }

  @override
  void initState() {
    super.initState();
    _panelExpandCtrl = SingleMotionController(
      motion: LabMotion.spatialReveal,
      vsync: this,
      initialValue: 0,
    );
    _panelExpandCtrl.addListener(_onPanelExpandTick);
    _inputFocusNode = FocusNode(onKeyEvent: _handleInputKeyEvent);
    _selectedNamesNotifier.value = List<String>.of(widget.selectedNames);
    _inputController.addListener(_syncFilterQuery);
    _inputFocusNode.addListener(_handleInputFocusChange);
  }

  @override
  void didUpdateWidget(covariant FacetMultiSelectField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectedNamesNotifier();
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

  @override
  void dispose() {
    _panelExpandCtrl.removeListener(_onPanelExpandTick);
    _panelExpandCtrl.dispose();
    _removeOverlay(immediate: true);
    _inputController.removeListener(_syncFilterQuery);
    _inputFocusNode.removeListener(_handleInputFocusChange);
    _inputController.dispose();
    _inputFocusNode.dispose();
    _menuScrollController.dispose();
    _selectedNamesNotifier.dispose();
    _filterQueryNotifier.dispose();
    _highlightedIndexNotifier.dispose();
    super.dispose();
  }

  void _syncFilterQuery() {
    final String next = _inputController.text;
    if (_filterQueryNotifier.value == next) {
      return;
    }
    _filterQueryNotifier.value = next;
    _highlightMovedByKeyboard = false;
    if (_menuScrollController.hasClients) {
      _menuScrollController.jumpTo(0);
    }
    _markOverlayNeedsBuild();
  }

  void _handleInputFocusChange() {
    if (_inputFocusNode.hasFocus) {
      _openMenu();
    }
  }

  void _handleTapOutside(PointerDownEvent event) {
    if (_overlayEntry != null) {
      return;
    }
    M3EFocus.tapOutsideHandler(_inputFocusNode)(event);
  }

  void _onPanelExpandTick() {
    _markOverlayNeedsBuild();
    if (!_menuSessionActive &&
        _panelExpandCtrl.value <= 0.01 &&
        _overlayEntry != null) {
      _removeOverlay(immediate: true);
    }
  }

  void _markOverlayNeedsBuild() {
    _overlayEntry?.markNeedsBuild();
  }

  void _openMenu() {
    if (!_menuSessionActive) {
      setState(() => _menuSessionActive = true);
    }
    _resolveMenuOpensAbove();
    final M3EDropdownMenuTheme menuTheme = M3ETheme.of(context)
        .dropdownMenuTheme;
    _panelExpandCtrl.motion = _menuPanelSpring(menuTheme.openSpring);
    if (_overlayEntry == null) {
      _panelExpandCtrl.value = 0;
      _overlayEntry = _buildOverlayEntry();
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    }
    _markOverlayNeedsBuild();
    if (LabMotion.reduceMotionOf(context)) {
      _panelExpandCtrl.value = 1;
    } else {
      _panelExpandCtrl.animateTo(1);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _closeMenu();
    });
  }

  void _closeMenu() {
    if (_overlayEntry == null && _panelExpandCtrl.value <= 0.01) {
      return;
    }
    if (_menuSessionActive) {
      setState(() => _menuSessionActive = false);
    }
    _menuSessionActive = false;
    _highlightedIndexNotifier.value = null;
    final M3EDropdownMenuTheme menuTheme = M3ETheme.of(context)
        .dropdownMenuTheme;
    _panelExpandCtrl.motion = _menuPanelSpring(menuTheme.closeSpring);
    if (LabMotion.reduceMotionOf(context)) {
      _panelExpandCtrl.value = 0;
      _removeOverlay(immediate: true);
    } else {
      _panelExpandCtrl.animateTo(0);
    }
  }

  void _resolveMenuOpensAbove() {
    final BuildContext? anchorContext = _fieldAnchorKey.currentContext;
    if (anchorContext == null) {
      _menuOpensAbove = false;
      return;
    }
    final RenderObject? renderObject = anchorContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      _menuOpensAbove = false;
      return;
    }
    final RenderBox box = renderObject;
    if (!box.attached) {
      _menuOpensAbove = false;
      return;
    }
    final Offset globalTopLeft = box.localToGlobal(Offset.zero);
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double spaceBelow = screenHeight - globalTopLeft.dy - box.size.height;
    final double spaceAbove = globalTopLeft.dy;
    final M3EDropdownMenuTheme menuTheme = M3ETheme.of(context)
        .dropdownMenuTheme;
    final double panelMaxHeight = math.min(
      _kNamedFacetMultiSelectMenuMaxHeight,
      math.min(
        menuTheme.panelMaxHeight,
        MediaQuery.sizeOf(context).height * 0.45,
      ),
    );
    _menuOpensAbove = spaceBelow < panelMaxHeight && spaceAbove > spaceBelow;
  }

  Offset _menuFollowerOffset(M3EDropdownMenuTheme menuTheme) {
    final double gap = M3ETheme.of(context).spacing.xs;
    final double margin = menuTheme.panelMarginTop;
    final double magnitude = margin > 0 ? margin : gap;
    return _menuOpensAbove ? Offset(0, -magnitude) : Offset(0, magnitude);
  }

  void _removeOverlay({bool immediate = false}) {
    if (!immediate && _panelExpandCtrl.value > 0.01) {
      return;
    }
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
    _panelExpandCtrl.value = 0;
  }

  Widget _wrapPanelExpandAnimation(Widget? child) {
    final double progress = _panelExpandCtrl.value.clamp(0.0, 1.5);
    final double clampedScale = progress.clamp(0.0, 1.2);
    if (progress <= 0.01) {
      return const SizedBox.shrink();
    }
    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.scale(
        alignment: _menuOpensAbove
            ? Alignment.bottomCenter
            : Alignment.topCenter,
        scaleY: clampedScale,
        child: child,
      ),
    );
  }

  OverlayEntry _buildOverlayEntry() {
    final M3EThemeData themeData = M3ETheme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return OverlayEntry(
      builder: (BuildContext overlayContext) {
        final M3EDropdownMenuTheme menuTheme = themeData.dropdownMenuTheme;
        final Offset followerOffset = _menuFollowerOffset(menuTheme);
        return MediaQuery(
          data: mediaQuery,
          child: M3ETheme(
            data: themeData,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: _handlePointerDown,
                  ),
                ),
                CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  targetAnchor: _menuOpensAbove
                      ? Alignment.topLeft
                      : Alignment.bottomLeft,
                  followerAnchor: _menuOpensAbove
                      ? Alignment.bottomLeft
                      : Alignment.topLeft,
                  offset: followerOffset,
                  child: AnimatedBuilder(
                    animation: _panelExpandCtrl,
                    builder: (BuildContext context, Widget? _) {
                      return _wrapPanelExpandAnimation(
                        ValueListenableBuilder<List<String>>(
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
                                        return TapRegion(
                                          groupId: _tapRegionGroup,
                                          child:
                                              _NamedFacetMultiSelectMenuPanel<
                                                T
                                              >(
                                                width: _fieldWidth,
                                                itemsProvider:
                                                    widget.itemsProvider,
                                                selectedNames: selectedNames,
                                                filterQuery: filterQuery,
                                                scrollController:
                                                    _menuScrollController,
                                                highlightedIndexListenable:
                                                    _highlightedIndexNotifier,
                                                highlightedRowKey:
                                                    _highlightedRowKey,
                                                onVisibleRemainingChanged:
                                                    _reportVisibleRemaining,
                                                onHighlightIndex: _highlightAt,
                                                onAdd: _addFromMenu,
                                                onRetry: widget.onRetry,
                                                resolveName: widget.resolveName,
                                                resolveSmartMatched:
                                                    widget.resolveSmartMatched,
                                                smartMatchedTooltip:
                                                    widget.smartMatchedTooltip,
                                                copy: widget.copy,
                                              ),
                                        );
                                      },
                                );
                              },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      _markOverlayNeedsBuild();
    }
  }

  void _highlightAt(int index, {bool scrollIntoView = false}) {
    if (index < 0 || index >= _visibleRemainingNames.length) {
      return;
    }
    if (_highlightedIndexNotifier.value != index) {
      _highlightedIndexNotifier.value = index;
      _markOverlayNeedsBuild();
    }
    if (scrollIntoView) {
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
  }

  bool _trySelectHighlightedCandidate() {
    if (_overlayEntry == null || _visibleRemainingNames.isEmpty) {
      return false;
    }
    final int? index = _highlightedIndexNotifier.value;
    if (index == null || index < 0 || index >= _visibleRemainingNames.length) {
      return false;
    }
    _addFromMenu(_visibleRemainingNames[index]);
    return true;
  }

  void _removeSelected(String name) {
    final bool restoreMenu = _menuSessionActive;
    widget.onRemove(name);
    if (!restoreMenu) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _openMenu();
      _inputFocusNode.requestFocus();
    });
  }

  void _moveHighlight(int delta) {
    if (_overlayEntry == null) {
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
    _highlightMovedByKeyboard = true;
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
      if (_overlayEntry == null) {
        return KeyEventResult.ignored;
      }
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _closeMenu();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final String trimmed = _inputController.text.trim();
      if (trimmed.isEmpty || _highlightMovedByKeyboard) {
        if (_trySelectHighlightedCandidate()) {
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.tab) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        return KeyEventResult.ignored;
      }
      if (_trySelectHighlightedCandidate()) {
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
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
    if (key == LogicalKeyboardKey.home) {
      if (_overlayEntry == null || _visibleRemainingNames.isEmpty) {
        return KeyEventResult.ignored;
      }
      _highlightAt(0, scrollIntoView: true);
      _highlightMovedByKeyboard = true;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      if (_overlayEntry == null || _visibleRemainingNames.isEmpty) {
        return KeyEventResult.ignored;
      }
      _highlightAt(_visibleRemainingNames.length - 1, scrollIntoView: true);
      _highlightMovedByKeyboard = true;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _submitInput() {
    final String trimmed = inputChipCommitLabel(_inputController.text);
    if (trimmed.isEmpty) {
      return;
    }
    widget.onAdd(trimmed);
    _inputController.clear();
    _inputFocusNode.requestFocus();
    _openMenu();
  }

  void _addFromMenu(String name) {
    _highlightMovedByKeyboard = false;
    widget.onAdd(inputChipCommitLabel(name));
    _inputController.clear();
    _openMenu();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _inputFocusNode.requestFocus();
    });
  }

  void _focusInput() {
    if (!_inputFocusNode.hasFocus) {
      _inputFocusNode.requestFocus();
    }
    _openMenu();
  }

  void _clearAllSelected() {
    if (widget.selectedNames.isEmpty) {
      return;
    }
    final VoidCallback? clearAll = widget.onClearAll;
    if (clearAll == null) {
      return;
    }
    clearAll();
    _inputController.clear();
    _closeMenu();
    _inputFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool hasSelectedTags = widget.selectedNames.isNotEmpty;
    final bool showClearAll = hasSelectedTags && widget.onClearAll != null;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _fieldWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return ListenableBuilder(
          listenable: _inputController,
          builder: (BuildContext context, Widget? _) {
            return CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.escape): _closeMenu,
              },
              child: CompositedTransformTarget(
                key: _fieldAnchorKey,
                link: _layerLink,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: widget.maxWidth),
                  child: RepaintBoundary(
                    child: OutlinedTextFieldShell(
                      key: FacetMultiSelectField.fieldSurfaceKey,
                      label: widget.label,
                      focusNode: _inputFocusNode,
                      onTapOutside: _handleTapOutside,
                      iconSlotAlignment: M3ETextFieldSlotAlignment.firstLine,
                      chipFirstLineLayout: true,
                      appearanceFocused: _menuSessionActive,
                      tapRegionGroupId: _tapRegionGroup,
                      isPopulated:
                          widget.selectedNames.isNotEmpty ||
                          _inputController.text.isNotEmpty,
                      selectionController: _inputController,
                      editableTextKey: _editableKey,
                      trailingBuilder: showClearAll
                          ? (
                              BuildContext context,
                              M3ETextFieldColors colors,
                              M3ETextFieldTheme fieldTheme,
                            ) => M3ETooltip(
                              message:
                                  widget.clearAllTooltip ?? l10n.commonClear,
                              child: M3ETextFieldAffordance(
                                key: FacetMultiSelectField.clearAllButtonKey,
                                icon: M3EIcons.cancel,
                                color: colors.trailingIcon,
                                iconSize: fieldTheme.iconSize,
                                semanticLabel:
                                    widget.clearAllTooltip ?? l10n.commonClear,
                                onPressed: _clearAllSelected,
                              ),
                            )
                          : null,
                      inputBuilder:
                          (
                            BuildContext context,
                            M3ETextFieldColors colors,
                            M3ETextFieldTheme fieldTheme,
                            TextStyle inputStyle,
                          ) {
                            final M3EChipTheme chipTheme = M3ETheme.of(context)
                                .chipTheme;
                            final bool hasChips =
                                widget.selectedNames.isNotEmpty;
                            final ({
                              double rowLineHeight,
                              double textTopInset,
                              double inlineWidth,
                            })
                            metrics = resolveInputChipInlineMetrics(
                              chipTheme: chipTheme,
                              inputStyle: inputStyle,
                              text: _inputController.text,
                              hasChips: hasChips,
                            );

                            return InputChipFieldContent(
                              fieldTheme: fieldTheme,
                              inputStyle: inputStyle,
                              hasChips: hasChips,
                              onTap: _focusInput,
                              chips: <Widget>[
                                for (final String name in widget.selectedNames)
                                  CompactInputChip(
                                    label: name,
                                    onPressed: _focusInput,
                                    onDeleted: () => _removeSelected(name),
                                  ),
                              ],
                              inlineField: SizedBox(
                                width: metrics.inlineWidth,
                                height: metrics.rowLineHeight,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: metrics.textTopInset,
                                  ),
                                  child: CallbackShortcuts(
                                    bindings: M3EFocus.editableInputShortcuts(
                                      _inputFocusNode,
                                    ),
                                    child: EditableText(
                                      key: _editableKey,
                                      controller: _inputController,
                                      focusNode: _inputFocusNode,
                                      style: inputStyle,
                                      cursorColor: colors.caret,
                                      backgroundCursorColor: M3ETheme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                      selectionColor: M3ETheme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(
                                            alpha: fieldTheme.selectionOpacity,
                                          ),
                                      textCapitalization:
                                          TextCapitalization.none,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _submitInput(),
                                      maxLines: 1,
                                      scrollPadding: EdgeInsets.zero,
                                      rendererIgnoresPointer: true,
                                      selectionControls:
                                          m3eTextFieldSelectionControls(
                                            defaultTargetPlatform,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
