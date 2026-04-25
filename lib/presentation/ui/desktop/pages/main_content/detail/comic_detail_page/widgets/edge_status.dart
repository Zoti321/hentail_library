import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/navigation/library_return_breadcrumb.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ComicDetailLoading extends StatelessWidget {
  const ComicDetailLoading({super.key});
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return _ComicDetailStatusView(
      leading: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
      ),
      label: '加载中…',
    );
  }
}

class ComicDetailNotFound extends StatelessWidget {
  const ComicDetailNotFound({super.key, required this.comicId});
  final String comicId;
  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return Padding(
      key: ValueKey<String>(comicId),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.lg + 8,
        vertical: tokens.spacing.lg + 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const LibraryReturnBreadcrumb(),
          Expanded(
            child: _ComicDetailStatusView(
              leading: Icon(
                LucideIcons.bookOpen,
                size: 48,
                color: Theme.of(context).colorScheme.textTertiary,
              ),
              label: '漫画不存在或已移除',
              action: TextButton.icon(
                onPressed: () => context.go('/local'),
                icon: const Icon(LucideIcons.library, size: 16),
                label: const Text('前往漫画库'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ComicDetailError extends StatefulWidget {
  const ComicDetailError({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  State<ComicDetailError> createState() => _ComicDetailErrorState();
}

class _ComicDetailErrorState extends State<ComicDetailError> {
  bool retrying = false;
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.lg + 8,
        vertical: tokens.spacing.lg + 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const LibraryReturnBreadcrumb(),
          Expanded(
            child: _ComicDetailStatusView(
              leading: Icon(
                LucideIcons.circleAlert,
                size: 48,
                color: theme.colorScheme.textTertiary,
              ),
              label: '加载失败，请重试',
              action: TextButton.icon(
                onPressed: retrying
                    ? null
                    : () {
                        setState(() => retrying = true);
                        widget.onRetry();
                      },
                icon: retrying
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : const Icon(LucideIcons.refreshCw, size: 16),
                label: Text(retrying ? '重试中…' : '重试'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComicDetailStatusView extends StatelessWidget {
  const _ComicDetailStatusView({
    required this.leading,
    required this.label,
    this.action,
  });
  final Widget leading;
  final String label;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl * 2 + 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spacing.lg,
          children: <Widget>[
            leading,
            Text(
              label,
              style: TextStyle(
                fontSize: tokens.text.bodyMd,
                color: cs.textSecondary,
              ),
            ),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}
