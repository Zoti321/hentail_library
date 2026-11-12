import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/catalog/detail/detail_status_scaffold.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 详情加载失败；传入 [onRetry] 时展示重试按钮，否则仅展示文案。
class DetailErrorStatus extends StatelessWidget {
  const DetailErrorStatus({super.key, required this.label, this.onRetry});

  final String label;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final VoidCallback? retry = onRetry;
    return DetailStatusScaffold(
      leading: Icon(
        LucideIcons.circleAlert,
        size: 48,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      label: label,
      action: retry == null ? null : _DetailRetryButton(onRetry: retry),
    );
  }
}

class _DetailRetryButton extends HookWidget {
  const _DetailRetryButton({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    final ValueNotifier<bool> retrying = useState<bool>(false);
    return TextButton.icon(
      onPressed: retrying.value
          ? null
          : () {
              retrying.value = true;
              onRetry();
            },
      icon: retrying.value
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : const Icon(LucideIcons.refreshCw, size: 16),
      label: Text(retrying.value ? l10n.shellRetrying : l10n.shellRetry),
    );
  }
}
