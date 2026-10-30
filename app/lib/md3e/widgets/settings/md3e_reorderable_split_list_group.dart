import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/md3e/widgets/lists/md3e_reorder_exclude.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 弹簧：`ratio` 为阻尼比（1 无过冲，越小回弹越明显）。
SpringDescription _spring(double stiffness, double ratio) {
  return SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: stiffness,
    ratio: ratio,
  );
}

/// 抬起：快速、无过冲。
final SpringDescription _liftSpring = _spring(3800, 1);

/// 邻行让位、占位块、松手回落：中等刚度、轻微回弹。
final SpringDescription _shiftSpring = _spring(380, 0.8);

/// 抬起时浮层向右下偏移的距离（与 M3E 列表拖拽的抬起感一致）。
const double _kLiftOffset = 12;

/// 拖拽浮层阴影高度（level 4）。
const double _kDragElevation = 8;

/// 可拖拽排序的分段列表：长按行后拖动，未拖拽时视觉与 [Md3eSplitListGroup] 完全一致。
///
/// 交互与视觉（自实现，手感对齐 M3E 列表拖拽）：
/// - 长按 [kLongPressTimeout] 开始拖拽，移动超过 [kTouchSlop] 则取消；开始时触发中等震动；
/// - 源行原位保留高度但隐藏；浮层跟随指针，抬起时向右下偏移 12dp 并投影；
/// - 占位块（[M3ETheme] 的 surfaceContainerLow）以弹簧跟随目标槽位；
/// - 相邻行以弹簧让位，目标变化时触发选择震动；
/// - 松手时浮层以弹簧回落到目标槽位，回落完成后才回调重排。
///
/// [onReorder] 使用 Flutter [ReorderCallback] 约定（`newIndex` 需先减一再插入，
/// 可直接用 `applyMd3eReorder` 处理）。
///
/// [itemKeyOf] 给出每行的稳定标识，用于重排后保持行的状态；缺省按下标。
/// 行内的按钮等应包在 [Md3eReorderExclude] 中，长按它们不会开始拖拽。
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

  // 所有动画都是无界控制器 + 弹簧模拟，便于保留速度做中途改向。
  late final AnimationController _lift = AnimationController.unbounded(
    vsync: this,
  )..addListener(_onTick);
  late final AnimationController _settle =
      AnimationController.unbounded(vsync: this)
        ..addListener(_onTick)
        ..addStatusListener(_onSettleStatus);
  late final AnimationController _placeholder = AnimationController.unbounded(
    vsync: this,
  )..addListener(_onTick);
  final Map<int, AnimationController> _offsets = <int, AnimationController>{};
  final Map<int, double> _offsetGoals = <int, double>{};

  // 指针
  int? _activePointer;
  Offset? _downGlobal;
  int? _downIndex;
  PointerDeviceKind _deviceKind = PointerDeviceKind.touch;
  Timer? _longPressTimer;
  VelocityTracker _velocity = VelocityTracker.withKind(PointerDeviceKind.touch);

  // 拖拽（坐标均为列表 Stack 内的局部坐标）
  int? _dragIndex;
  int? _targetIndex;
  int? _dropFrom;
  int? _dropTo;
  bool _settling = false;
  Size _dragSize = Size.zero;
  Offset _pointer = Offset.zero;
  Offset _grab = Offset.zero;
  Offset _settleFrom = Offset.zero;
  Offset _settleTo = Offset.zero;
  List<Offset> _slotOrigins = <Offset>[];
  List<double> _slotHeights = <double>[];

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _lift.dispose();
    _settle.dispose();
    _placeholder.dispose();
    for (final AnimationController c in _offsets.values) {
      c.dispose();
    }
    super.dispose();
  }

  Object _idOf(int index) => widget.itemKeyOf?.call(index) ?? index;

  GlobalKey _rowKey(Object id) => _rowKeys.putIfAbsent(id, GlobalKey.new);

  void _onTick() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSettleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _settling) {
      _finishDrag();
    }
  }

  AnimationController _offsetCtrl(int index) {
    return _offsets.putIfAbsent(index, () {
      return AnimationController.unbounded(vsync: this)..addListener(_onTick);
    });
  }

  double _offsetValue(int index) => _offsets[index]?.value ?? 0;

  /// 以弹簧从当前位置与速度追到 [target]（中途改向时不会突变）。
  void _springTo(
    AnimationController controller,
    double target,
    SpringDescription spring,
  ) {
    controller.animateWith(
      SpringSimulation(spring, controller.value, target, controller.velocity),
    );
  }

  // ---- 指针 ----

  void _onSlotPointerDown(int index, PointerDownEvent event) {
    if (_dragIndex != null || _settling) {
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
    _deviceKind = event.kind;
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
    if (_dragIndex != null) {
      _velocity.addPosition(event.timeStamp, event.position);
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
    if (_dragIndex != null && !_settling) {
      _endDrag();
    }
  }

  void _cancelLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  // ---- 几何 ----

  /// 测量所有行在列表 Stack 内的左上角与尺寸（拖拽开始时调用，此刻让位偏移均为 0）。
  bool _captureSlots(RenderBox stack) {
    final List<Offset> origins = <Offset>[];
    final List<double> heights = <double>[];
    for (int i = 0; i < widget.itemCount; i++) {
      final RenderBox? box =
          _rowKey(_idOf(i)).currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        return false;
      }
      origins.add(stack.globalToLocal(box.localToGlobal(Offset.zero)));
      heights.add(box.size.height);
    }
    _slotOrigins = origins;
    _slotHeights = heights;
    return true;
  }

  /// 假设 [from] 行被放到 [to] 位置时，所有行在列表中的新 top（各行按自身高度累加）。
  ///
  /// 让位与占位都以这套真实布局为准，因此行高不同时也不会错位、重叠。
  List<double> _layoutTops(int from, int to) {
    final List<int> order = <int>[
      for (int i = 0; i < widget.itemCount; i++)
        if (i != from) i,
    ]..insert(to, from);
    final List<double> tops = List<double>.filled(widget.itemCount, 0);
    double cursor = _slotOrigins.isEmpty ? 0 : _slotOrigins[0].dy;
    for (final int index in order) {
      tops[index] = cursor;
      cursor += _slotHeights[index] + kMd3eSplitListRowGap;
    }
    return tops;
  }

  /// 目标位置：拖拽浮层的中心越过了几条「其他行」的中线，就放到第几位。
  /// 使用各行原始位置的中线，不依赖行高相同。
  int _placementFor(int from, double centerY) {
    int to = 0;
    for (int i = 0; i < widget.itemCount; i++) {
      if (i == from) {
        continue;
      }
      final double mid = _slotOrigins[i].dy + _slotHeights[i] / 2;
      if (mid < centerY) {
        to++;
      }
    }
    return to;
  }

  // ---- 拖拽 ----

  void _startDrag(int index) {
    final Offset? down = _downGlobal;
    if (down == null || index < 0 || index >= widget.itemCount) {
      return;
    }
    final RenderBox? stack =
        _listKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? box =
        _rowKey(_idOf(index)).currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || box == null || !box.hasSize) {
      return;
    }
    if (!_captureSlots(stack)) {
      return;
    }
    _dragSize = box.size;
    _pointer = stack.globalToLocal(down);
    _grab = _pointer - _slotOrigins[index];
    _velocity = VelocityTracker.withKind(_deviceKind);

    _dragIndex = index;
    _targetIndex = index;
    HapticFeedback.mediumImpact();

    _lift.value = 0;
    _springTo(_lift, 1, _liftSpring);
    _settle.value = 0;
    _placeholder.value = _slotOrigins[index].dy;
    _offsetGoals.clear();
    for (final AnimationController c in _offsets.values) {
      c.value = 0;
    }
    _retarget(index);
    setState(() {});
  }

  void _updateDrag(Offset global) {
    final int? from = _dragIndex;
    final RenderBox? stack =
        _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (from == null || _settling || stack == null) {
      return;
    }
    if (_slotOrigins.length != widget.itemCount) {
      return;
    }
    _pointer = stack.globalToLocal(global);
    final Offset center = _pointer - _grab + _dragSize.center(Offset.zero);

    final int to = _placementFor(from, center.dy);
    if (to != _targetIndex) {
      _targetIndex = to;
      HapticFeedback.selectionClick();
      _retarget(from);
    }
    setState(() {});
  }

  /// 目标变化：占位块与其他行都以弹簧追向「目标布局」中的真实位置。
  void _retarget(int from) {
    final int to = _targetIndex ?? from;
    final List<double> tops = _layoutTops(from, to);
    _springTo(_placeholder, tops[from], _shiftSpring);
    for (int i = 0; i < widget.itemCount; i++) {
      final double target = i == from ? 0 : tops[i] - _slotOrigins[i].dy;
      if (_offsetGoals[i] == target) {
        continue;
      }
      _offsetGoals[i] = target;
      _springTo(_offsetCtrl(i), target, _shiftSpring);
    }
  }

  /// 浮层当前的绘制位置（跟随指针，抬起时带 12dp 偏移）。
  Offset _proxyPosition(double lift) {
    return (_pointer - _grab) +
        Offset(_kLiftOffset * lift, _kLiftOffset * lift);
  }

  void _endDrag() {
    final int? from = _dragIndex;
    if (from == null || _settling) {
      return;
    }
    final int to = _targetIndex ?? from;
    _settleFrom = _proxyPosition(_lift.value.clamp(0.0, 1.0));
    _settleTo = Offset(_slotOrigins[to].dx, _layoutTops(from, to)[from]);
    _dropFrom = from;
    _dropTo = to;

    final Offset travel = _settleTo - _settleFrom;
    setState(() => _settling = true);
    if (travel.distance <= 1) {
      _finishDrag();
      return;
    }

    final Velocity velocity = _velocity.getVelocity();
    final double along =
        (velocity.pixelsPerSecond.dx * travel.dx +
            velocity.pixelsPerSecond.dy * travel.dy) /
        travel.distance;
    _settle.value = 0;
    _settle.animateWith(
      SpringSimulation(
        _shiftSpring,
        0,
        1,
        (along / travel.distance).clamp(-10.0, 10.0),
      ),
    );
  }

  void _finishDrag() {
    final int? from = _dropFrom;
    final int? to = _dropTo;
    if (!mounted || from == null || to == null) {
      return;
    }
    _settling = false;
    _dragIndex = null;
    _targetIndex = null;
    _dropFrom = null;
    _dropTo = null;

    _settle.stop();
    _settle.value = 0;
    _placeholder.stop();
    _lift.stop();
    _lift.value = 0;
    for (final AnimationController c in _offsets.values) {
      c.stop();
      c.value = 0;
    }
    _offsetGoals.clear();

    // 同一帧内先复位让位偏移再回调重排，避免行回弹。
    if (from != to) {
      widget.onReorder(from, to > from ? to + 1 : to);
    }
    setState(() {});
  }

  // ---- 构建 ----

  @override
  Widget build(BuildContext context) {
    final int n = widget.itemCount;
    final bool dragging = _dragIndex != null && _slotOrigins.length == n;
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
          if (dragging) _buildPlaceholder(context),
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

    final Widget row = KeyedSubtree(
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

    final Widget listening = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent event) =>
          _onSlotPointerDown(index, event),
      child: row,
    );

    final Widget slot = _dragIndex == index
        // 源行：保留布局高度但隐藏，浮层负责绘制它。
        ? IgnorePointer(child: Opacity(opacity: 0, child: listening))
        : Transform.translate(
            offset: Offset(0, _offsetValue(index)),
            child: listening,
          );

    return KeyedSubtree(
      key: ValueKey<Object>(id),
      child: Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : kMd3eSplitListRowGap),
        child: slot,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final double lift = _lift.value.clamp(0.0, 1.0);
    return Positioned(
      left: _slotOrigins[0].dx,
      top: _placeholder.value,
      width: _dragSize.width,
      height: _dragSize.height,
      child: IgnorePointer(
        child: Opacity(
          opacity: lift,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(widget.outerRadius),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProxy(BuildContext context) {
    final int from = _dragIndex!;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final double lift = _lift.value.clamp(0.0, 1.0);
    final Offset offset = _settling
        ? Offset.lerp(_settleFrom, _settleTo, _settle.value.clamp(0.0, 1.0))!
        : _proxyPosition(lift);

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: _dragSize.width,
      height: _dragSize.height,
      child: IgnorePointer(
        child: PhysicalModel(
          color: scheme.surfaceContainerHigh,
          elevation: _kDragElevation,
          borderRadius: BorderRadius.circular(widget.outerRadius),
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
    );
  }
}
