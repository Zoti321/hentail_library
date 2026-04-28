import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/chrome/status_card_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SelectedPathsLoadingCard extends StatelessWidget {
  const SelectedPathsLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return StatusCardShell(
      padding: const EdgeInsets.symmetric(vertical: 42),
      borderRadius: 14,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class SelectedPathsErrorCard extends ConsumerStatefulWidget {
  const SelectedPathsErrorCard({super.key, required this.error});

  final Object error;

  @override
  ConsumerState<SelectedPathsErrorCard> createState() =>
      _SelectedPathsErrorCardState();
}

class _SelectedPathsErrorCardState
    extends ConsumerState<SelectedPathsErrorCard> {
  bool isRetrying = false;

  Future<void> retryLoadPaths() async {
    setState(() => isRetrying = true);
    try {
      await ref.read(selectedPathsPageProvider.notifier).refreshPaths();
    } finally {
      if (mounted) {
        setState(() => isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return StatusCardShell(
      padding: const EdgeInsets.all(20),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '路径加载失败',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.warning,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.error.toString(),
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isRetrying ? null : retryLoadPaths,
            icon: isRetrying
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : const Icon(LucideIcons.rotateCw, size: 16),
            label: Text(isRetrying ? '重试中…' : '重试'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(color: theme.colorScheme.borderSubtle),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
