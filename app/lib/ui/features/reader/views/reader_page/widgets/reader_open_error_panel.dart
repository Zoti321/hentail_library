import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_open_error_message.dart';

/// Read session 打开失败：分类文案 + 返回详情 + 可选重试。
class ReaderOpenErrorPanel extends StatelessWidget {
  const ReaderOpenErrorPanel({
    super.key,
    required this.error,
    required this.onBackToDetail,
    this.onRetry,
  });

  final Object error;
  final VoidCallback onBackToDetail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final String message = readSessionOpenFailureMessage(context, error);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: tokens.text.bodyLg,
                  color: cs.hentai.readerTextMuted,
                ),
              ),
              SizedBox(height: tokens.spacing.xl),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: tokens.spacing.md,
                runSpacing: tokens.spacing.md,
                children: <Widget>[
                  GhostButton.text(
                    text: context.l10n.readerOpenBackToDetail,
                    onPressed: onBackToDetail,
                  ),
                  if (onRetry != null)
                    GhostButton.text(
                      text: context.l10n.commonRetry,
                      onPressed: onRetry,
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
