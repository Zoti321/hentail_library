import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/md3e/l10n/md3e_material_localizations.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_embeddable_calendar_date_picker.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const double _kAnchoredCalendarGap = 4;

/// 在 [layerLink] 锚点处以浮层展示 [Md3eEmbeddableCalendarDatePicker]。
///
/// 使用 [CompositedTransformFollower] 对齐字段，避免 Widgetbook / 嵌套滚动下
/// root overlay 坐标换算错位。点击遮罩或按 Esc 关闭；月历点选某一天后关闭。
Future<void> md3eShowAnchoredCalendarDatePicker({
  required BuildContext context,
  required LayerLink layerLink,
  required DateTime firstDate,
  required DateTime lastDate,
  required ValueChanged<DateTime> onDateChanged,
  DateTime? initialDate,
  M3EDatePickerMode initialCalendarMode = M3EDatePickerMode.year,
  BuildContext? placementContext,
}) {
  final M3EThemeData themeData = M3ETheme.of(context);
  final Locale locale = Localizations.localeOf(context);
  final MediaQueryData mediaQuery = MediaQuery.of(context);
  final Completer<void> completer = Completer<void>();
  late OverlayEntry entry;
  var overlayRemoved = false;

  void dismiss() {
    if (!overlayRemoved) {
      overlayRemoved = true;
      entry.remove();
    }
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  entry = OverlayEntry(
    builder: (BuildContext overlayContext) {
      return MediaQuery(
        data: mediaQuery,
        child: Localizations(
          locale: locale,
          delegates: md3eMaterialLocalizationsDelegates,
          child: M3ETheme(
            data: themeData,
            child: _Md3eAnchoredCalendarDatePickerLayer(
              layerLink: layerLink,
              placementContext: placementContext ?? context,
              firstDate: firstDate,
              lastDate: lastDate,
              initialDate: initialDate,
              initialCalendarMode: initialCalendarMode,
              onDateChanged: onDateChanged,
              onDaySelected: dismiss,
              onDismiss: dismiss,
            ),
          ),
        ),
      );
    },
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  return completer.future;
}

class _Md3eAnchoredCalendarDatePickerLayer extends StatefulWidget {
  const _Md3eAnchoredCalendarDatePickerLayer({
    required this.layerLink,
    required this.placementContext,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
    required this.onDaySelected,
    required this.onDismiss,
    this.initialDate,
    this.initialCalendarMode = M3EDatePickerMode.year,
  });

  final LayerLink layerLink;
  final BuildContext placementContext;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDate;
  final M3EDatePickerMode initialCalendarMode;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onDaySelected;
  final VoidCallback onDismiss;

  @override
  State<_Md3eAnchoredCalendarDatePickerLayer> createState() =>
      _Md3eAnchoredCalendarDatePickerLayerState();
}

class _Md3eAnchoredCalendarDatePickerLayerState
    extends State<_Md3eAnchoredCalendarDatePickerLayer> {
  bool _openBelow = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveVerticalPlacement());
  }

  void _resolveVerticalPlacement() {
    if (!mounted) {
      return;
    }
    final RenderObject? object =
        widget.placementContext.findRenderObject();
    if (object is! RenderBox || !object.hasSize || !object.attached) {
      return;
    }
    const double estimatedPanelHeight = 360;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final Offset topLeft = object.localToGlobal(Offset.zero);
    final double spaceBelow =
        screenHeight - topLeft.dy - object.size.height - _kAnchoredCalendarGap;
    final double spaceAbove = topLeft.dy - _kAnchoredCalendarGap;
    final bool openBelow = spaceBelow >= estimatedPanelHeight
        ? true
        : spaceAbove >= estimatedPanelHeight
        ? false
        : spaceBelow >= spaceAbove;
    if (openBelow != _openBelow) {
      setState(() => _openBelow = openBelow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Alignment targetAnchor = _openBelow
        ? Alignment.bottomLeft
        : Alignment.topLeft;
    final Alignment followerAnchor = _openBelow
        ? Alignment.topLeft
        : Alignment.bottomLeft;
    final double verticalOffset = _openBelow
        ? _kAnchoredCalendarGap
        : -_kAnchoredCalendarGap;

    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onDismiss();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onDismiss,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: widget.layerLink,
            showWhenUnlinked: false,
            targetAnchor: targetAnchor,
            followerAnchor: followerAnchor,
            offset: Offset(0, verticalOffset),
            child: _CalendarPanel(
              initialDate: widget.initialDate,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              initialCalendarMode: widget.initialCalendarMode,
              onDateChanged: widget.onDateChanged,
              onDaySelected: widget.onDaySelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
    required this.onDaySelected,
    this.initialDate,
    this.initialCalendarMode = M3EDatePickerMode.year,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDate;
  final M3EDatePickerMode initialCalendarMode;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onDaySelected;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EDatePickerTheme dateTheme = theme.datePickerTheme;

    return Material(
      elevation: dateTheme.elevation,
      borderRadius: dateTheme.borderRadius,
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: Md3eEmbeddableCalendarDatePicker(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        initialCalendarMode: initialCalendarMode,
        onDateChanged: onDateChanged,
        onDaySelected: (_) => onDaySelected(),
      ),
    );
  }
}
