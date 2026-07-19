import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Dialog ↔ compact page 形态切换时长（与桌面短过渡一致）。
const Duration kAdaptiveFormSurfaceTransitionDuration = Duration(
  milliseconds: 200,
);

/// 打开自适应表单表面：medium/expanded 为 dialog，compact 为全页（标题栏下）。
Future<T?> showAdaptiveFormSurface<T>({
  required BuildContext context,
  required String title,
  required Widget body,
  required List<Widget> actions,
  double maxDialogWidth = 420,
  double borderRadius = 8,
  Color? backgroundColor,
  bool scrollableBody = true,
  EdgeInsetsGeometry bodyPadding = const EdgeInsets.fromLTRB(18, 0, 18, 16),
  bool showFooterDivider = true,
  bool fitContentHeight = false,
  EdgeInsetsGeometry? actionsPadding,
  Key? bodyKey,
}) {
  return showAdaptiveFormSurfaceWidget<T>(
    context: context,
    surface: AdaptiveFormSurface(
      title: title,
      body: body,
      actions: actions,
      maxDialogWidth: maxDialogWidth,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      scrollableBody: scrollableBody,
      bodyPadding: bodyPadding,
      showFooterDivider: showFooterDivider,
      fitContentHeight: fitContentHeight,
      actionsPadding: actionsPadding,
      bodyKey: bodyKey,
    ),
  );
}

/// 打开已组装好的 [AdaptiveFormSurface]（表单 State 自管 title/body/actions 时用）。
Future<T?> showAdaptiveFormSurfaceWidget<T>({
  required BuildContext context,
  required Widget surface,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: kAdaptiveFormSurfaceTransitionDuration,
    pageBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return surface;
        },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final Animation<double> curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          );
        },
  );
}

/// 可复用表单壳：按 [AppLayoutBreakpoints] 在 dialog / page 间 morph。
class AdaptiveFormSurface extends StatefulWidget {
  const AdaptiveFormSurface({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.maxDialogWidth = 420,
    this.borderRadius = 8,
    this.backgroundColor,
    this.scrollableBody = true,
    this.bodyPadding = const EdgeInsets.fromLTRB(18, 0, 18, 16),
    this.showFooterDivider = true,
    this.fitContentHeight = false,
    this.actionsPadding,
    this.bodyKey,
  });

  static const Key dialogChromeKey = ValueKey<String>(
    'adaptive_form_surface_dialog',
  );
  static const Key pageChromeKey = ValueKey<String>(
    'adaptive_form_surface_page',
  );

  final String title;
  final Widget body;
  final List<Widget> actions;
  final double maxDialogWidth;
  final double borderRadius;
  final Color? backgroundColor;
  final bool scrollableBody;
  final EdgeInsetsGeometry bodyPadding;
  final bool showFooterDivider;
  final bool fitContentHeight;
  final EdgeInsetsGeometry? actionsPadding;
  final Key? bodyKey;

  @override
  State<AdaptiveFormSurface> createState() => _AdaptiveFormSurfaceState();
}

class _AdaptiveFormSurfaceState extends State<AdaptiveFormSurface> {
  /// 稳定挂载 body，跨 dialog/page morph 保留 Element / State。
  final GlobalKey _bodySlotKey = GlobalKey(debugLabel: 'adaptive_form_body');

  @override
  Widget build(BuildContext context) {
    final bool compact = AppLayoutBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: compact ? 1 : 0),
      duration: kAdaptiveFormSurfaceTransitionDuration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double t, Widget? child) {
        return _AdaptiveFormMorphChrome(
          t: t,
          title: widget.title,
          actions: widget.actions,
          maxDialogWidth: widget.maxDialogWidth,
          borderRadius: widget.borderRadius,
          backgroundColor: widget.backgroundColor,
          scrollableBody: widget.scrollableBody,
          bodyPadding: widget.bodyPadding,
          showFooterDivider: widget.showFooterDivider,
          fitContentHeight: widget.fitContentHeight,
          actionsPadding: widget.actionsPadding,
          body: child!,
        );
      },
      child: KeyedSubtree(
        key: _bodySlotKey,
        child: KeyedSubtree(key: widget.bodyKey, child: widget.body),
      ),
    );
  }
}

class _AdaptiveFormMorphChrome extends StatelessWidget {
  const _AdaptiveFormMorphChrome({
    required this.t,
    required this.title,
    required this.actions,
    required this.maxDialogWidth,
    required this.borderRadius,
    required this.scrollableBody,
    required this.bodyPadding,
    required this.showFooterDivider,
    required this.fitContentHeight,
    required this.body,
    this.backgroundColor,
    this.actionsPadding,
  });

  /// 0 = dialog，1 = page。
  final double t;
  final String title;
  final List<Widget> actions;
  final double maxDialogWidth;
  final double borderRadius;
  final Color? backgroundColor;
  final bool scrollableBody;
  final EdgeInsetsGeometry bodyPadding;
  final bool showFooterDivider;
  final bool fitContentHeight;
  final EdgeInsetsGeometry? actionsPadding;
  final Widget body;

  static const double _dialogInset = 24;
  static const double _fitContentChromeReserve = 120;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Size media = MediaQuery.sizeOf(context);

    final double dialogWidth = math.min(
      maxDialogWidth,
      media.width - _dialogInset * 2,
    );
    final double inset = lerpDouble(_dialogInset, 0, t)!;
    final double radius = lerpDouble(borderRadius, 0, t)!;
    final double width = lerpDouble(dialogWidth, media.width, t)!;
    final double maxHeight = media.height - inset * 2;
    final double minHeight = lerpDouble(0, maxHeight, t)!;
    final bool pageMode = t >= 0.5;

    final Color ambient = isDark
        ? Colors.black.withAlpha(52)
        : Colors.black.withAlpha(14);
    final Color contact = isDark
        ? Colors.black.withAlpha(72)
        : Colors.black.withAlpha(22);
    final double shadowOpacity = (1 - t).clamp(0.0, 1.0);

    final Widget paddedBody = scrollableBody
        ? SingleChildScrollView(padding: bodyPadding, child: body)
        : Padding(padding: bodyPadding, child: body);

    final Widget bodySection;
    if (pageMode) {
      bodySection = Expanded(child: paddedBody);
    } else if (fitContentHeight) {
      final double maxBodyHeight = math.max(
        0,
        media.height - 48 - _fitContentChromeReserve,
      );
      bodySection = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxBodyHeight),
        child: paddedBody,
      );
    } else {
      bodySection = Flexible(child: paddedBody);
    }

    return SafeArea(
      left: pageMode,
      top: pageMode,
      right: pageMode,
      bottom: pageMode,
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: ClipRRect(
            key: pageMode
                ? AdaptiveFormSurface.pageChromeKey
                : AdaptiveFormSurface.dialogChromeKey,
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              width: width,
              constraints: BoxConstraints(
                maxHeight: maxHeight,
                minHeight: minHeight,
              ),
              decoration: BoxDecoration(
                color:
                    backgroundColor ??
                    (pageMode ? cs.surface : cs.hentai.cardHover),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: cs.hentai.borderSubtle.withValues(
                    alpha: (1 - t).clamp(0.0, 1.0),
                  ),
                  width: 1,
                ),
                boxShadow: shadowOpacity <= 0
                    ? null
                    : <BoxShadow>[
                        BoxShadow(
                          color: ambient.withValues(
                            alpha: ambient.a * shadowOpacity,
                          ),
                          blurRadius: 32,
                          spreadRadius: -4,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: cs.hentai.cardShadowHover.withValues(
                            alpha: cs.hentai.cardShadowHover.a * shadowOpacity,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: cs.hentai.cardShadow.withValues(
                            alpha: cs.hentai.cardShadow.a * shadowOpacity,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: contact.withValues(
                            alpha: contact.a * shadowOpacity,
                          ),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: pageMode ? MainAxisSize.max : MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        pageMode ? tokens.spacing.sm : 18,
                        pageMode ? tokens.spacing.sm : 16,
                        pageMode ? tokens.spacing.lg : 18,
                        pageMode ? tokens.spacing.sm : 12,
                      ),
                      child: Row(
                        children: <Widget>[
                          if (pageMode) ...<Widget>[
                            GhostButton.icon(
                              icon: LucideIcons.arrowLeft,
                              tooltip: context.l10n.commonBack,
                              semanticLabel: context.l10n.commonBack,
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                            SizedBox(width: tokens.spacing.sm),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: pageMode ? tokens.text.titleSm : 16,
                                fontWeight: FontWeight.w600,
                                color: cs.hentai.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    bodySection,
                    _AdaptiveFormActionsBar(
                      actions: actions,
                      showDivider: showFooterDivider,
                      padding: actionsPadding,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdaptiveFormActionsBar extends StatelessWidget {
  const _AdaptiveFormActionsBar({
    required this.actions,
    required this.showDivider,
    this.padding,
  });

  final List<Widget> actions;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;

  static const double _compactActionsBreakpoint = 360;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compactActions =
            constraints.maxWidth < _compactActionsBreakpoint;
        final double horizontalPadding = compactActions ? 12 : 16;
        final double actionSpacing = compactActions ? 4 : 8;
        final ThemeData theme = Theme.of(context);
        final ThemeData actionTheme = compactActions
            ? theme.copyWith(
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              )
            : theme;

        final EdgeInsetsGeometry effectivePadding =
            padding ??
            EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 14);

        return Container(
          padding: effectivePadding,
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    top: BorderSide(
                      color: theme.colorScheme.hentai.borderSubtle,
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Theme(
            data: actionTheme,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: actionSpacing,
              runSpacing: actionSpacing,
              children: actions
                  .where(
                    (Widget action) =>
                        !(action is SizedBox &&
                            action.child == null &&
                            action.width != null),
                  )
                  .toList(growable: false),
            ),
          ),
        );
      },
    );
  }
}
