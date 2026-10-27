import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/md3e/l10n/md3e_material_localizations.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_embeddable_calendar_date_picker.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const double _kAnchoredCalendarGap = 4;
const EdgeInsets _kAnchoredCalendarScreenPadding = EdgeInsets.all(8);

/// 在 [anchor] 附近以浮层展示 [Md3eEmbeddableCalendarDatePicker]。
///
/// 点击遮罩或按 Esc 关闭；在「日」视图点选某一天时关闭（年份格点选仍留在浮层内切到月历）。
Future<void> md3eShowAnchoredCalendarDatePicker({
  required BuildContext context,
  required Rect anchor,
  required DateTime firstDate,
  required DateTime lastDate,
  required ValueChanged<DateTime> onDateChanged,
  DateTime? initialDate,
  M3EDatePickerMode initialCalendarMode = M3EDatePickerMode.year,
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
              anchor: anchor,
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

class _Md3eAnchoredCalendarDatePickerLayer extends StatelessWidget {
  const _Md3eAnchoredCalendarDatePickerLayer({
    required this.anchor,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
    required this.onDaySelected,
    required this.onDismiss,
    this.initialDate,
    this.initialCalendarMode = M3EDatePickerMode.year,
  });

  final Rect anchor;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDate;
  final M3EDatePickerMode initialCalendarMode;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onDaySelected;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final M3EDatePickerTheme dateTheme = M3ETheme.of(context).datePickerTheme;
    final double panelWidth = dateTheme.width;
    final double left = _horizontalOffset(
      anchor: anchor,
      panelWidth: panelWidth,
      screenWidth: screen.width,
    );
    final bool openBelow = _preferOpenBelow(
      anchor: anchor,
      screenHeight: screen.height,
    );

    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          onDismiss();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: const SizedBox.expand(),
            ),
          ),
          if (openBelow)
            Positioned(
              left: left,
              top: anchor.bottom + _kAnchoredCalendarGap,
              width: panelWidth,
              child: _panel(
                onDateChanged: onDateChanged,
                onDaySelected: onDaySelected,
              ),
            )
          else
            Positioned(
              left: left,
              bottom: screen.height - anchor.top + _kAnchoredCalendarGap,
              width: panelWidth,
              child: _panel(
                onDateChanged: onDateChanged,
                onDaySelected: onDaySelected,
              ),
            ),
        ],
      ),
    );
  }

  Widget _panel({
    required ValueChanged<DateTime> onDateChanged,
    required VoidCallback onDaySelected,
  }) {
    return Material(
      type: MaterialType.transparency,
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

  static double _horizontalOffset({
    required Rect anchor,
    required double panelWidth,
    required double screenWidth,
  }) {
    final double maxLeft =
        screenWidth - panelWidth - _kAnchoredCalendarScreenPadding.right;
    return anchor.left.clamp(
      _kAnchoredCalendarScreenPadding.left,
      maxLeft < _kAnchoredCalendarScreenPadding.left
          ? _kAnchoredCalendarScreenPadding.left
          : maxLeft,
    );
  }

  static bool _preferOpenBelow({
    required Rect anchor,
    required double screenHeight,
  }) {
    const double estimatedPanelHeight = 360;
    final double spaceBelow =
        screenHeight - anchor.bottom - _kAnchoredCalendarScreenPadding.bottom;
    final double spaceAbove =
        anchor.top - _kAnchoredCalendarScreenPadding.top;
    if (spaceBelow >= estimatedPanelHeight) {
      return true;
    }
    if (spaceAbove >= estimatedPanelHeight) {
      return false;
    }
    return spaceBelow >= spaceAbove;
  }
}
