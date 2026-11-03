import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/motion/motion.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/md3e_named_facet_multi_select_copy.dart';
import 'package:hentai_library/shared/ui/widgets/inputs/outlined_text_field_shell.dart';
import 'package:hentai_library/shared/util/name_pinyin_assisted_filter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_3_expressive/components/text_fields/utils/m3e_text_field_selection_controls.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:motor/motor.dart';
import 'package:riverpod/misc.dart' show ProviderListenable;

part 'md3e_named_facet_multi_select_menu.dart';

const double _kMd3eNamedFacetMultiSelectMenuMaxHeight = 240;
const double _kMd3eNamedFacetMultiSelectChipGap = 8;
const double _kMd3eNamedFacetMultiSelectInlineMinWidth = 48;

/// MD3E Named facet 多选：chip + 内联输入 + 自绘候选浮层（非 [M3EDropdownMenu] 底座）。
class Md3eNamedFacetMultiSelectField<T> extends ConsumerStatefulWidget {
  const Md3eNamedFacetMultiSelectField({
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
  });

  static const Key fieldSurfaceKey = Key(
    'md3e_named_facet_multi_select_field_surface',
  );
  static const Key menuPanelKey = Key(
    'md3e_named_facet_multi_select_menu_panel',
  );
  static const Key smartMatchedHintKey = Key(
    'md3e_named_facet_multi_select_smart_matched_hint',
  );

  final String label;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final ProviderListenable<AsyncValue<List<T>>> itemsProvider;
  final VoidCallback onRetry;
  final String Function(T item) resolveName;
  final Md3eNamedFacetMultiSelectCopy copy;
  final double maxWidth;
  final bool Function(T item)? resolveSmartMatched;
  final String? smartMatchedTooltip;

  @override
  ConsumerState<Md3eNamedFacetMultiSelectField<T>> createState() =>
      _Md3eNamedFacetMultiSelectFieldState<T>();
}

class _Md3eNamedFacetMultiSelectFieldState<T>
    extends ConsumerState<Md3eNamedFacetMultiSelectField<T>>
    with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
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
      motion: Md3eMotion.spatialReveal,
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
  void didUpdateWidget(covariant Md3eNamedFacetMultiSelectField<T> oldWidget) {
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
    _menuSessionActive = true;
    final M3EDropdownMenuTheme menuTheme = M3ETheme.of(context).dropdownMenuTheme;
    _panelExpandCtrl.motion = _menuPanelSpring(menuTheme.openSpring);
    if (_overlayEntry == null) {
      _panelExpandCtrl.value = 0;
      _overlayEntry = _buildOverlayEntry();
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    }
    _markOverlayNeedsBuild();
    if (Md3eMotion.reduceMotionOf(context)) {
      _panelExpandCtrl.value = 1;
    } else {
      _panelExpandCtrl.animateTo(1);
    }
  }

  void _closeMenu() {
    if (_overlayEntry == null && _panelExpandCtrl.value <= 0.01) {
      return;
    }
    _menuSessionActive = false;
    _highlightedIndexNotifier.value = null;
    final M3EDropdownMenuTheme menuTheme = M3ETheme.of(context).dropdownMenuTheme;
    _panelExpandCtrl.motion = _menuPanelSpring(menuTheme.closeSpring);
    if (Md3eMotion.reduceMotionOf(context)) {
      _panelExpandCtrl.value = 0;
      _removeOverlay(immediate: true);
    } else {
      _panelExpandCtrl.animateTo(0);
    }
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
        alignment: Alignment.topCenter,
        scaleY: clampedScale,
        child: child,
      ),
    );
  }

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(
      builder: (BuildContext overlayContext) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) {
                      return;
                    }
                    _closeMenu();
                  });
                },
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: Offset(0, M3ETheme.of(context).spacing.xs),
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
                                    return _Md3eNamedFacetMultiSelectMenuPanel<T>(
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
                                      resolveSmartMatched:
                                          widget.resolveSmartMatched,
                                      smartMatchedTooltip:
                                          widget.smartMatchedTooltip,
                                      copy: widget.copy,
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
        Scrollable.ensureVisible(rowContext, alignment: 0.5, duration: Duration.zero);
      });
    }
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
    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.backspace ||
            key == LogicalKeyboardKey.delete)) {
      final TextEditingValue value = _inputController.value;
      if (value.text.isNotEmpty ||
          !value.selection.isCollapsed ||
          widget.selectedNames.isEmpty) {
        return KeyEventResult.ignored;
      }
      widget.onRemove(widget.selectedNames.last);
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
    _openMenu();
  }

  void _addFromMenu(String name) {
    widget.onAdd(name);
    _inputController.clear();
    _inputFocusNode.requestFocus();
    _openMenu();
  }

  void _focusInput() {
    if (!_inputFocusNode.hasFocus) {
      _inputFocusNode.requestFocus();
    }
    _openMenu();
  }

  double _inlineWidth(TextStyle style) {
    if (_inputController.text.isEmpty) {
      return _kMd3eNamedFacetMultiSelectInlineMinWidth;
    }
    final TextPainter painter = TextPainter(
      text: TextSpan(text: _inputController.text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return math.max(_kMd3eNamedFacetMultiSelectInlineMinWidth, painter.width + 4);
  }

  @override
  Widget build(BuildContext context) {
    final M3EChipTheme chipTheme = M3ETheme.of(context).chipTheme;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _fieldWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return CompositedTransformTarget(
          link: _layerLink,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            child: Md3eOutlinedTextFieldShell(
                key: Md3eNamedFacetMultiSelectField.fieldSurfaceKey,
                label: widget.label,
                focusNode: _inputFocusNode,
                onTapOutside: _handleTapOutside,
                isPopulated:
                    widget.selectedNames.isNotEmpty ||
                    _inputController.text.isNotEmpty,
                selectionController: _inputController,
                editableTextKey: _editableKey,
                inputBuilder:
                    (
                      BuildContext context,
                      M3ETextFieldColors colors,
                      M3ETextFieldTheme fieldTheme,
                      TextStyle inputStyle,
                    ) {
                      final double inlineWidth = _inlineWidth(inputStyle);
                      final double inputLine = M3ETextFieldTheme.lineHeightOf(
                        inputStyle,
                      );
                      final bool alignWithChips = widget.selectedNames.isNotEmpty;
                      final double slotHeight = alignWithChips
                          ? chipTheme.height
                          : inputLine;
                      final double textTopInset = alignWithChips
                          ? (chipTheme.height - inputLine) / 2
                          : 0;

                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _focusInput,
                        child: Wrap(
                          spacing: _kMd3eNamedFacetMultiSelectChipGap,
                          runSpacing: _kMd3eNamedFacetMultiSelectChipGap,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            for (final String name in widget.selectedNames)
                              M3EChip(
                                label: name,
                                type: M3EChipType.input,
                                onPressed: _focusInput,
                                onDeleted: () => widget.onRemove(name),
                              ),
                            SizedBox(
                              width: inlineWidth,
                              height: slotHeight,
                              child: Padding(
                                padding: EdgeInsets.only(top: textTopInset),
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
                                    backgroundCursorColor: M3ETheme.of(context)
                                        .colorScheme
                                        .outlineVariant,
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
                          ],
                        ),
                      );
                    },
              ),
          ),
        );
      },
    );
  }
}
