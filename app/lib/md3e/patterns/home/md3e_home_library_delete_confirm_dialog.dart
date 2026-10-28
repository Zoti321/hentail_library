import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_copy.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Lab：从 Home 预览列表移除 Library 的确认（不写 FRB / 不删 Resource）。
Future<bool> showMd3eHomeLibraryDeleteConfirmDialog({
  required BuildContext context,
  required String libraryDisplayName,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: false,
    builder: (BuildContext dialogContext) {
      return _Md3eHomeLibraryDeleteConfirmDialog(
        libraryDisplayName: libraryDisplayName,
      );
    },
  );
  return confirmed ?? false;
}

class _Md3eHomeLibraryDeleteConfirmDialog extends StatefulWidget {
  const _Md3eHomeLibraryDeleteConfirmDialog({
    required this.libraryDisplayName,
  });

  final String libraryDisplayName;

  @override
  State<_Md3eHomeLibraryDeleteConfirmDialog> createState() =>
      _Md3eHomeLibraryDeleteConfirmDialogState();
}

class _Md3eHomeLibraryDeleteConfirmDialogState
    extends State<_Md3eHomeLibraryDeleteConfirmDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ESpacing spacing = theme.spacing;

    return Dialog(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.lg,
          spacing.lg,
          spacing.lg,
          spacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              Md3eHomeLibraryManagementCopy.deleteConfirmTitle(
                widget.libraryDisplayName,
              ),
              style: theme.typeScale.titleLarge.copyWith(
                color: scheme.onSurface,
              ),
            ),
            SizedBox(height: spacing.md),
            _Md3eHomeLibraryDeleteConfirmBody(
              acknowledged: _acknowledged,
              onAcknowledgementChanged: (bool value) {
                setState(() => _acknowledged = value);
              },
              scheme: scheme,
              spacing: spacing,
              theme: theme,
            ),
            SizedBox(height: spacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                M3EButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: M3EButtonStyle.text,
                  label: Text(l10n.commonCancel),
                ),
                SizedBox(width: spacing.sm),
                M3EButton(
                  onPressed: _acknowledged
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: M3EButtonStyle.filled,
                  decoration: M3EButtonDecoration.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                    disabledBackgroundColor: scheme.onSurface.withValues(
                      alpha: 0.12,
                    ),
                    disabledForegroundColor: scheme.onSurface.withValues(
                      alpha: 0.38,
                    ),
                  ),
                  label: Text(l10n.sidebarDeleteLibrary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog 正文：说明 + 勾选闸门（复选框与说明文案垂直居中）。
class _Md3eHomeLibraryDeleteConfirmBody extends StatelessWidget {
  const _Md3eHomeLibraryDeleteConfirmBody({
    required this.acknowledged,
    required this.onAcknowledgementChanged,
    required this.scheme,
    required this.spacing,
    required this.theme,
  });

  final bool acknowledged;
  final ValueChanged<bool> onAcknowledgementChanged;
  final M3EColorScheme scheme;
  final M3ESpacing spacing;
  final M3EThemeData theme;

  @override
  Widget build(BuildContext context) {
    final TextStyle descriptionStyle = theme.typeScale.bodyMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final TextStyle acknowledgementStyle = theme.typeScale.bodyMedium.copyWith(
      color: scheme.onSurface,
    );

    void toggleAcknowledgement() {
      onAcknowledgementChanged(!acknowledged);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          Md3eHomeLibraryManagementCopy.deleteConfirmBody,
          style: descriptionStyle,
        ),
        SizedBox(height: spacing.md),
        Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: toggleAcknowledgement,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: spacing.sm,
                horizontal: spacing.sm,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    M3ECheckbox(
                      value: acknowledged,
                      onChanged: (bool? value) {
                        onAcknowledgementChanged(value ?? false);
                      },
                      focusable: true,
                    ),
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: Text(
                        Md3eHomeLibraryManagementCopy
                            .deleteConfirmAcknowledgement,
                        style: acknowledgementStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
