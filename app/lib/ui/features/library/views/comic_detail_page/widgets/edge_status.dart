import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/widgets/comic_detail_back_header.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ComicDetailLoading extends StatelessWidget {
  const ComicDetailLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const ComicDetailBackHeader(),
        Expanded(
          child: _ComicDetailStatusView(
            leading: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: cs.primary,
              ),
            ),
            label: l10n.shellLoading,
          ),
        ),
      ],
    );
  }
}

class ComicDetailNotFound extends StatelessWidget {
  const ComicDetailNotFound({super.key, required this.comicId});

  final String comicId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Column(
      key: ValueKey<String>(comicId),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const ComicDetailBackHeader(),
        Expanded(
          child: _ComicDetailStatusView(
            leading: Icon(
              LucideIcons.bookOpen,
              size: 48,
              color: Theme.of(context).colorScheme.hentai.textTertiary,
            ),
            label: l10n.comicDetailNotFound,
            action: TextButton.icon(
              onPressed: () => context.go('/local'),
              icon: const Icon(LucideIcons.library, size: 16),
              label: Text(l10n.comicDetailGoToLibrary),
            ),
          ),
        ),
      ],
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
    final AppLocalizations l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const ComicDetailBackHeader(),
        Expanded(
          child: _ComicDetailStatusView(
            leading: Icon(
              LucideIcons.circleAlert,
              size: 48,
              color: theme.colorScheme.hentai.textTertiary,
            ),
            label: l10n.comicDetailLoadFailedRetry,
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
              label: Text(retrying ? l10n.shellRetrying : l10n.shellRetry),
            ),
          ),
        ),
      ],
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
                color: cs.hentai.textSecondary,
              ),
            ),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}
