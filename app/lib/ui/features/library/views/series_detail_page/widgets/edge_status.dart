import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/widgets/comic_detail_back_header.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesDetailLoading extends StatelessWidget {
  const SeriesDetailLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const ComicDetailBackHeader(),
        Expanded(
          child: _SeriesDetailStatusView(
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

class SeriesDetailError extends StatelessWidget {
  const SeriesDetailError({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const ComicDetailBackHeader(),
        Expanded(
          child: _SeriesDetailStatusView(
            leading: Icon(
              LucideIcons.circleAlert,
              size: 48,
              color: Theme.of(context).colorScheme.hentai.textTertiary,
            ),
            label: l10n.searchLoadFailed(error.toString()),
          ),
        ),
      ],
    );
  }
}

class SeriesNotFound extends StatelessWidget {
  const SeriesNotFound({super.key, this.seriesId, this.seriesName});

  final String? seriesId;
  final String? seriesName;

  String _displayLabel(AppLocalizations l10n) {
    final String? name = seriesName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final String? id = seriesId?.trim();
    if (id != null && id.isNotEmpty) {
      return id;
    }
    return l10n.seriesDetailUnknown;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const ComicDetailBackHeader(),
        Expanded(
          child: _SeriesDetailStatusView(
            leading: Icon(
              LucideIcons.library,
              size: 48,
              color: Theme.of(context).colorScheme.hentai.textTertiary,
            ),
            label: l10n.seriesDetailNotFound(_displayLabel(l10n)),
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

class _SeriesDetailStatusView extends StatelessWidget {
  const _SeriesDetailStatusView({
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
