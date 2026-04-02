import 'package:flutter/material.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ComicDetailLoadingView extends StatelessWidget {
  const ComicDetailLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ComicDetailStatusView(
      leading: CircularProgressIndicator(),
      label: '加载中…',
    );
  }
}

class ComicDetailEmptyView extends StatelessWidget {
  const ComicDetailEmptyView({super.key, required this.comicId});

  final String comicId;

  @override
  Widget build(BuildContext context) {
    return _ComicDetailStatusView(
      leading: Icon(
        LucideIcons.bookOpen,
        size: 48,
        color: Theme.of(context).colorScheme.textTertiary,
      ),
      label: '漫画不存在或已移除',
      action: TextButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(LucideIcons.arrowLeft, size: 16),
        label: const Text('返回'),
      ),
    );
  }
}

class ComicDetailErrorView extends StatefulWidget {
  const ComicDetailErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  State<ComicDetailErrorView> createState() => _ComicDetailErrorViewState();
}

class _ComicDetailErrorViewState extends State<ComicDetailErrorView> {
  bool _retrying = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ComicDetailStatusView(
      leading: Icon(
        LucideIcons.circleAlert,
        size: 48,
        color: theme.colorScheme.textTertiary,
      ),
      label: '加载失败，请重试',
      action: TextButton.icon(
        onPressed: _retrying
            ? null
            : () {
                setState(() => _retrying = true);
                widget.onRetry();
              },
        icon: _retrying
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            : const Icon(LucideIcons.refreshCw, size: 16),
        label: Text(_retrying ? '重试中…' : '重试'),
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            leading,
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.textSecondary,
              ),
            ),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}

