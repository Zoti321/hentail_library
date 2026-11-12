import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/catalog/detail/detail_back_header.dart';

export 'package:hentai_library/shared/ui/catalog/detail/detail_error_status.dart';
export 'package:hentai_library/shared/ui/catalog/detail/detail_loading_status.dart';
export 'package:hentai_library/shared/ui/catalog/detail/detail_not_found_status.dart';

/// 漫画详情与系列详情共用的边缘状态外壳（返回头 + 居中的图标 / 文案 / 操作）。
class DetailStatusScaffold extends StatelessWidget {
  const DetailStatusScaffold({
    super.key,
    required this.leading,
    required this.label,
    this.action,
  });

  final Widget leading;
  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const DetailBackHeader(),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: tokens.spacing.xl * 2 + 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: tokens.spacing.lg,
                children: <Widget>[
                  leading,
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: tokens.text.bodyMd,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  ?action,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
