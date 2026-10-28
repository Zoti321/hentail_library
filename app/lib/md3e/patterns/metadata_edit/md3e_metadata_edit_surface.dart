import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_metadata_edit_form_metrics.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_desktop_shell_surfaces.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_edit_actions.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab 元数据编辑壳：compact / medium 用 M3E 全屏 dialog；expanded+ 用 M3EDialog basic。
enum Md3eMetadataEditPresentation {
  /// Widgetbook：宽屏居中卡片 / 窄屏全屏（由 [Md3eLabDialogPresenter] 打开时勿用）。
  embedded,

  /// [M3EDialog] basic 内容（由 presenter 包裹路由）。
  modal,

  /// 仅表单 body（用于 [M3EDialog.showFullScreen] 的 body 槽）。
  labFormBody,
}

class Md3eMetadataEditSurface extends StatelessWidget {
  const Md3eMetadataEditSurface({
    super.key,
    required this.title,
    required this.body,
    required this.onCancel,
    required this.onSave,
    this.maxWidth = Md3eMetadataEditFormMetrics.comicMaxWidth,
    this.presentation = Md3eMetadataEditPresentation.embedded,
    this.saving = false,
    this.saveEnabled = true,
    this.onBack,
  });

  final String title;
  final Widget body;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final double maxWidth;
  final Md3eMetadataEditPresentation presentation;
  final bool saving;
  final bool saveEnabled;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    final bool useFullPage = presentation == Md3eMetadataEditPresentation.embedded &&
        sizeClass.usesMetadataEditFullScreenRoute;

    if (presentation == Md3eMetadataEditPresentation.labFormBody) {
      return body;
    }

    if (presentation == Md3eMetadataEditPresentation.modal) {
      return M3EDialog(
        title: title,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: MediaQuery.sizeOf(context).height * 0.55,
          ),
          child: SingleChildScrollView(child: body),
        ),
        bottomDivider: true,
        actions: md3eMetadataEditDialogActions(
          context,
          onCancel: onCancel,
          onSave: onSave,
          saving: saving,
          saveEnabled: saveEnabled,
        ),
      );
    }

    if (useFullPage) {
      return M3EFullScreenDialog(
        title: title,
        body: SingleChildScrollView(child: body),
        confirmLabel: context.l10n.commonSave,
        onConfirm: saving || !saveEnabled ? null : onSave,
        bottomActions: <Widget>[
          M3EButton(
            onPressed: saving ? null : onCancel,
            style: M3EButtonStyle.text,
            label: Text(context.l10n.commonCancel),
          ),
        ],
        onClose: onBack ?? onCancel,
      );
    }

    return ColoredBox(
      color: md3eLabBrowseCanvasColor(M3ETheme.of(context).colorScheme),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(
            Md3eMetadataEditFormMetrics.contentHorizontalPadding(sizeClass),
          ),
          child: _DialogCard(
            maxWidth: maxWidth,
            title: title,
            body: body,
            onCancel: onCancel,
            onSave: onSave,
            saving: saving,
            saveEnabled: saveEnabled,
          ),
        ),
      ),
    );
  }
}

class _DialogCard extends StatelessWidget {
  const _DialogCard({
    required this.maxWidth,
    required this.title,
    required this.body,
    required this.onCancel,
    required this.onSave,
    required this.saving,
    required this.saveEnabled,
  });

  final double maxWidth;
  final String title;
  final Widget body;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;
  final bool saveEnabled;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;
    final Size size = MediaQuery.sizeOf(context);
    final Md3eWindowSizeClass sizeClass = Md3eWindowSizeClass.fromWidth(size.width);
    final double horizontalInset =
        Md3eMetadataEditFormMetrics.contentHorizontalPadding(sizeClass);
    final double width = math.min(maxWidth, size.width - horizontalInset * 2);
    final double maxHeight = size.height * 0.88;

    return Material(
      color: theme.colorScheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(spacing.md),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, spacing.sm),
                child: Text(
                  title,
                  style: theme.typeScale.titleLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(spacing.lg, spacing.sm, spacing.lg, spacing.lg),
                  child: body,
                ),
              ),
              const Divider(height: 1),
              _ActionBar(
                onCancel: onCancel,
                onSave: onSave,
                saving: saving,
                saveEnabled: saveEnabled,
                padding: EdgeInsets.fromLTRB(spacing.lg, spacing.md, spacing.lg, spacing.md),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onCancel,
    required this.onSave,
    required this.saving,
    required this.saveEnabled,
    required this.padding,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;
  final bool saveEnabled;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3ESpacing spacing = M3ETheme.of(context).spacing;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          M3EButton(
            onPressed: saving ? null : onCancel,
            style: M3EButtonStyle.text,
            label: Text(l10n.commonCancel),
          ),
          SizedBox(width: spacing.sm),
          M3EButton(
            onPressed: saving || !saveEnabled ? null : onSave,
            style: M3EButtonStyle.filled,
            label: saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: M3ETheme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }
}
