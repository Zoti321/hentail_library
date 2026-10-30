import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/lists/md3e_reorder_exclude.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const Duration _kLiftDuration = Duration(milliseconds: 150);
const Duration _kShiftDuration = Duration(milliseconds: 200);
const Duration _kSettleDuration = Duration(milliseconds: 200);

/// 拖拽浮层的放大倍数（抬起时放大到此值）。
const double _kDragScale = 1.02;

/// 可拖拽排序的分段列表：长按行后拖动，视觉与 [Md3eSplitListGroup] 一致。
///
/// 交互与视觉（自实现，参考 M3E 列表的拖拽行为）：
/// - 长按 [kLongPressTimeout] 开始拖拽，移动超过 [kTouchSlop] 则取消；
/// - 拖拽时源行原地保留高度但隐藏，浮层跟随指针并轻微放大、加阴影；
/// - 相邻行平移让出目标位置，目标位置显示占位块；
/// - 松手时浮层回落到目标位置，然后才回调重排。
///
/// [onReorder] 使用 Flutter [ReorderCallback] 约定（与 [ReorderableListView] 一致）：
/// `newIndex` 需先减一再插入，可直接用 `applyMd3eReorder` 处理。
///
/// [itemKeyOf] 给出每行的稳定标识（如库 id），用于重排后保持行的状态与动画；缺省按下标。
/// 行内的按钮、开关等应包在 [Md3eReorderExclude] 中，长按它们不会开始拖拽。
class Md3eReorderableSplitListGroup extends StatefulWidget {
  const Md3eReorderableSplitListGroup({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    this.itemKeyOf,
    this.onItemTap,
    this.mouseCursor,
    this.outerRadius = kMd3eTonalSurfaceRadius,
  });

  final int itemCount;

  /// 构建行内容（不含分段外壳，外壳由本组件提供）。
  final IndexedWidgetBuilder itemBuilder;
  final ReorderCallback onReorder;

  /// 行的稳定标识；缺省时使用下标。
  final Object Function(int index)? itemKeyOf;

  /// 行级点击；为 null 时行不挂载点按反馈。
  final ValueChanged<int>? onItemTap;
  final MouseCursor? mouseCursor;
  final double outerRadius;

  @override
  State<Md3eReorderableSplitListGroup> createState() =>
      _Md3eReorderableSplitListGroupState();
}

class _Md3eReorderableSplitListGroupState
    extends State<Md3eReorderableSplitListGroup>
    with TickerProviderStateMixin {
  final GlobalKey _listKey = GlobalKey();
  final Map<Object, GlobalKey> _rowKeys = <Object, GlobalKey>{};

  late final AnimationController _lift = AnimationController(
    vsync: this,
    duration: _kLiftDuration,
  );
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: _kSettleDuration,
  );

  // 指针状态
  int? _activePointer;
  Offset? _downGlobal;
  int? _downIndex;
  Timer? _longPressTimer;

  // 拖拽状态（布局坐标均相对于列表 Stack）
  int? _dragFrom;
  int? _dragTarget;
  double _dragHeight = 0;
  double _grabOffset = 0;
  double _proxyTop = 0;
  List<double> _slotTops = <double>[];
  List<double> _slotHeights = <double>[];
  bool _settling = false;
  double _settleFrom = 0;
  double _settleTo = 0;

  /// 松手重排的那一帧关闭让位动画，避免行在重排时出现回弹。
  bool _suppressShiftAnimation = false;

  @override
  void initState() {
    super.initState();
    _lift.addListener(_onLiftTick);
    _settle.addListener(_onSettleTick);
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _lift.dispose();
    _settle.dispose();
    super.dispose();
  }

  Object _idOf(int index) => widget.itemKeyOf?.call(index) ?? index;

  GlobalKey _rowKey(Object id) => _rowKeys.putIfAbsent(id, GlobalKey.new);

  void _onLiftTick() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSettleTick() {
    if (!mounted || !_settling) {
      return;
    }
    final double t = Curves.easeOutCubic.transform(_settle.value);
    setState(() {
      _proxyTop = _settleFrom + (_settleTo - _settleFrom) * t;
    });
  }

  // ---- 指针 ----

  void _onSlotPointerDown(int index, PointerDownEvent event) {
    if (_dragFrom != null || _settling) {
      return;
    }
    final BuildContext? rowContext = _rowKey(_idOf(index)).currentContext;
    if (rowContext == null ||
        md3eIsPointerInReorderExclude(rowContext, event.position)) {
      return;
    }
    _activePointer = event.pointer;
    _downGlobal = event.position;
    _downIndex = index;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(kLongPressTimeout, _onLongPressTimeout);
  }

  void _onLongPressTimeout() {
    final int? index = _downIndex;
    if (!mounted || _activePointer == null || index == null) {
      return;
    }
    _startDrag(index);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _settling) {
      return;
    }
    if (_dragFrom != null) {
      _updateDrag(event.position);
      return;
    }
    final Offset? down = _downGlobal;
    if (down != null && (event.position - down).distance > kTouchSlop) {
      _cancelLongPress();
    }
  }

  void _onPointerUp(PointerEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    _cancelLongPress();
    _activePointer = null;
    _downGlobal = null;
    _downIndex = null;
    if (_dragFrom != null && !_settling) {
      _endDrag();
    }
  }

  void _cancelLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  // ---- 几何 ----

  Offset _toListLocal(Offset global) {
    final RenderBox? box =
        _listKey.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? global : box.globalToLocal(global);
  }

  /// 在拖拽开始时测量所有行的位置与高度（此时尚未发生让位，测量值即原始布局）。
  bool _measure() {
    final RenderBox? listBox =
        _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null || !listBox.hasSize) {
      return false;
    }
    final List<double> tops = <double>[];
    final List<double> heights = <double>[];
    for (int i = 0; i < widget.itemCount; i++) {
      final RenderBox? box =
          _rowKey(_idOf(i)).currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        return false;
      }
      tops.add(listBox.globalToLocal(box.localToGlobal(Offset.zero)).dy);
      heights.add(box.size.height);
    }
    _slotTops = tops;
    _slotHeights = heights;
    return true;
  }

  // ---- 拖拽 ----

  void _startDrag(int index) {
    final Offset? down = _downGlobal;
    if (down == null || index < 0 || index >= widget.itemCount) {
      return;
    }
    if (!_measure()) {
      return;
    }
    final double pointerTop = _toListLocal(down).dy;
    _dragFrom = index;
    _dragTarget = index;
    _dragHeight = _slotHeights[index];
    _grabOffset = pointerTop - _slotTops[index];
    _proxyTop = _slotTops[index];
    _lift.forward(from: 0);
    setState(() {});
  }

  void _updateDrag(Offset global) {
    if (_slotTops.length != widget.itemCount) {
      return;
    }
    _proxyTop = _toListLocal(global).dy - _grabOffset;
    final double centerY = _proxyTop + _dragHeight / 2;
    int target = widget.itemCount - 1;
    for (int i = 0; i < widget.itemCount; i++) {
      if (centerY < _slotTops[i] + _slotHeights[i] / 2) {
        target = i;
        break;
      }
    }
    _dragTarget = target;
    setState(() {});
  }

  /// 第 [index] 行（重排前的下标）因拖拽需要让出的竖向位移。
  double _shiftFor(int index) {
    final int? from = _dragFrom;
    final int? to = _dragTarget;
    if (from == null || to == null) {
      return 0;
    }
    final double step = _dragHeight + kMd3eSplitListRowGap;
    if (to > from && index > from && index <= to) {
      return -step;
    }
    if (to < from && index >= to && index < from) {
      return step;
    }
    return 0;
  }

  void _endDrag() {
    final int? from = _dragFrom;
    if (from == null) {
      return;
    }
    final int target = _dragTarget ?? from;
    _settling = true;
    _settleFrom = _proxyTop;
    _settleTo = _slotTops[target];
    _settle.forward(from: 0).whenComplete(() => _commit(from, target));
  }

  void _commit(int from, int target) {
    if (!mounted) {
      return;
    }
    _suppressShiftAnimation = true;
    if (target != from) {
      widget.onReorder(from, target > from ? target + 1 : target);
    }
    _lift.value = 0;
    setState(() {
      _dragFrom = null;
      _dragTarget = null;
      _settling = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _suppressShiftAnimation = false;
      }
    });
  }

  // ---- 构建 ----

  @override
  Widget build(BuildContext context) {
    final int n = widget.itemCount;
    final bool dragging =
        _dragFrom != null && _dragTarget != null && _slotTops.length == n;
    final List<Widget> slots = <Widget>[
      for (int i = 0; i < n; i++) _buildSlot(context, i),
    ];

    return Listener(
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: Stack(
        key: _listKey,
        clipBehavior: Clip.none,
        children: <Widget>[
          if (dragging)
            Positioned(
              top: _slotTops[_dragTarget!],
              left: 0,
              right: 0,
              height: _dragHeight,
              child: _buildPlaceholder(context),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: slots,
          ),
          if (dragging) _buildProxy(context),
        ],
      ),
    );
  }

  Widget _buildSlot(BuildContext context, int index) {
    final int n = widget.itemCount;
    final Object id = _idOf(index);
    final bool first = index == 0;
    final bool last = index == n - 1;

    Widget row = KeyedSubtree(
      key: _rowKey(id),
      child: Md3eSplitListRow(
        topRadius: first ? widget.outerRadius : kMd3eSplitListInnerRadius,
        bottomRadius: last ? widget.outerRadius : kMd3eSplitListInnerRadius,
        pressedRadius: widget.outerRadius,
        mouseCursor: widget.onItemTap == null ? null : widget.mouseCursor,
        onTap: widget.onItemTap == null ? null : () => widget.onItemTap!(index),
        child: widget.itemBuilder(context, index),
      ),
    );

    row = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent event) =>
          _onSlotPointerDown(index, event),
      child: row,
    );

    if (_dragFrom == index) {
      // 源行：保留布局高度但隐藏，浮层负责绘制它。
      row = IgnorePointer(child: Opacity(opacity: 0, child: row));
    } else {
      row = _ShiftedRow(
        offsetY: _shiftFor(index),
        duration: _suppressShiftAnimation ? Duration.zero : _kShiftDuration,
        child: row,
      );
    }

    return KeyedSubtree(
      key: ValueKey<Object>(id),
      child: Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : kMd3eSplitListRowGap),
        child: row,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(widget.outerRadius),
      ),
    );
  }

  Widget _buildProxy(BuildContext context) {
    final int from = _dragFrom!;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final double lift = _lift.value;

    return Positioned(
      left: 0,
      right: 0,
      top: _proxyTop,
      height: _dragHeight,
      child: IgnorePointer(
        child: Transform.scale(
          scale: 1 + (_kDragScale - 1) * lift,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.outerRadius),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2 * lift),
                  blurRadius: 8 * lift,
                  offset: Offset(0, 4 * lift),
                ),
              ],
            ),
            child: Md3eSplitDragScope(
              color: scheme.surfaceContainerHigh,
              radius: widget.outerRadius,
              child: Md3eSplitListRow(
                topRadius: widget.outerRadius,
                bottomRadius: widget.outerRadius,
                child: widget.itemBuilder(context, from),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 行的竖向让位动画：目标位移变化时平滑过渡；[duration] 为零时瞬时跳转。
class _ShiftedRow extends StatelessWidget {
  const _ShiftedRow({
    required this.offsetY,
    required this.duration,
    required this.child,
  });

  final double offsetY;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: offsetY),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.translate(offset: Offset(0, value), child: child);
      },
    );
  }
}
