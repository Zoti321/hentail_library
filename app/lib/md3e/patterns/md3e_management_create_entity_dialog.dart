import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/patterns/md3e_management_named_facet.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_management_entity_name_field.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

const double _kMd3eManagementCreateDialogMaxWidth = 400;

/// 移动端：FAB 打开的新建实体 Dialog（outlined 字段 + 操作）。
Future<void> showMd3eManagementCreateEntityDialog({
  required BuildContext context,
  required Md3eManagementNamedFacet facet,
  required ValueChanged<String> onCreate,
}) {
  return showDialog<void>(
    context: context,
    useRootNavigator: false,
    builder: (BuildContext dialogContext) {
      return _Md3eManagementCreateEntityDialog(
        facet: facet,
        onCreate: onCreate,
      );
    },
  );
}

class _Md3eManagementCreateEntityDialog extends StatefulWidget {
  const _Md3eManagementCreateEntityDialog({
    required this.facet,
    required this.onCreate,
  });

  final Md3eManagementNamedFacet facet;
  final ValueChanged<String> onCreate;

  @override
  State<_Md3eManagementCreateEntityDialog> createState() =>
      _Md3eManagementCreateEntityDialogState();
}

class _Md3eManagementCreateEntityDialogState
    extends State<_Md3eManagementCreateEntityDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    widget.onCreate(name);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ESpacing spacing = theme.spacing;
    final Size size = MediaQuery.sizeOf(context);
    final Md3eWindowSizeClass sizeClass = Md3eWindowSizeClass.fromWidth(
      size.width,
    );
    final double horizontalInset =
        Md3eLibraryBrowsePageMetrics.contentHorizontalPadding(sizeClass);
    final double contentWidth = math.min(
      _kMd3eManagementCreateDialogMaxWidth,
      size.width - horizontalInset * 2,
    );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: spacing.lg,
      ),
      child: SizedBox(
        width: contentWidth,
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
                widget.facet.createDialogTitle,
                style: theme.typeScale.titleLarge.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: spacing.lg),
              Md3eManagementEntityNameField(
                label: widget.facet.createFieldLabel,
                controller: _controller,
                autofocus: true,
                onSubmitted: (_) => _submit(),
              ),
              SizedBox(height: spacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  M3EButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: M3EButtonStyle.text,
                    label: const Text('取消'),
                  ),
                  SizedBox(width: spacing.sm),
                  M3EButton(
                    onPressed: _submit,
                    style: M3EButtonStyle.filled,
                    label: const Text('创建'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
