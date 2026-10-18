import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/detail_status/detail_back_header.dart';
import 'package:hentai_library/shared/di/library_management_providers.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final ColorScheme cs = Theme.of(context).colorScheme;
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
                      color: cs.hentai.textSecondary,
                    ),
                  ),
                  if (action != null) action!,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 详情加载中。
class DetailLoadingStatus extends StatelessWidget {
  const DetailLoadingStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DetailStatusScaffold(
      leading: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
      ),
      label: context.l10n.shellLoading,
    );
  }
}

/// 详情未找到，附带「回到库」操作。
class DetailNotFoundStatus extends StatelessWidget {
  const DetailNotFoundStatus({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DetailStatusScaffold(
      leading: Icon(
        icon,
        size: 48,
        color: Theme.of(context).colorScheme.hentai.textTertiary,
      ),
      label: label,
      action: TextButton.icon(
        onPressed: () => goCurrentLibraryBrowseFromContext(context),
        icon: const Icon(LucideIcons.library, size: 16),
        label: Text(context.l10n.comicDetailGoToLibrary),
      ),
    );
  }
}

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
        color: theme.colorScheme.hentai.textTertiary,
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
