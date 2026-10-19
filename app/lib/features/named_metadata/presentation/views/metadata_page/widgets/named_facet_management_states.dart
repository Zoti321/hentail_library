part of 'named_facet_management_panel.dart';

class _NamedFacetManagementLoadingState extends StatelessWidget {
  const _NamedFacetManagementLoadingState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl * 2),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: cs.primary),
        ),
      ),
    );
  }
}

class _NamedFacetManagementErrorState extends StatelessWidget {
  const _NamedFacetManagementErrorState({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl * 2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              LucideIcons.circleAlert,
              size: 32,
              color: context.hentai.textTertiary,
            ),
            SizedBox(height: tokens.spacing.md),
            Text(
              '$error',
              style: TextStyle(
                fontSize: tokens.text.bodySm,
                color: context.hentai.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _NamedFacetManagementEmptyState extends StatelessWidget {
  const _NamedFacetManagementEmptyState({
    required this.kind,
    required this.hasSearchQuery,
    required this.onCreate,
  });

  final ManagedNamedFacetKind kind;
  final bool hasSearchQuery;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl * 2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              hasSearchQuery ? LucideIcons.searchX : _iconForKind(kind),
              size: 32,
              color: context.hentai.textTertiary,
            ),
            SizedBox(height: tokens.spacing.md),
            Text(
              hasSearchQuery
                  ? l10n.metadataNoMatchTitle(kind)
                  : l10n.metadataEmptyTitle(kind),
              style: TextStyle(
                fontSize: tokens.text.bodyMd,
                fontWeight: FontWeight.w600,
                color: context.hentai.textPrimary,
              ),
            ),
            SizedBox(height: tokens.spacing.xs),
            Text(
              hasSearchQuery
                  ? l10n.metadataSearchNoMatchHint
                  : l10n.metadataEmptyHint(kind),
              style: TextStyle(
                fontSize: tokens.text.bodySm,
                color: context.hentai.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasSearchQuery) ...<Widget>[
              SizedBox(height: tokens.spacing.lg),
              FilledButton(
                onPressed: onCreate,
                child: Text(l10n.metadataAddLabel(kind)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NamedFacetConfirmDeleteDialog extends StatelessWidget {
  const _NamedFacetConfirmDeleteDialog({
    required this.name,
    required this.attachmentCount,
  });

  final String name;
  final int attachmentCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return HentaiDialog(
      title: l10n.confirmDeleteNamedFacetTitle,
      content: Text(l10n.confirmDeleteNamedFacetContent(name, attachmentCount)),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        const SizedBox(width: 8),
        DestructiveFilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.commonDelete),
        ),
      ],
    );
  }
}

Future<void> _renameNamedFacet(
  BuildContext context,
  WidgetRef ref,
  ManagedNamedFacetKind kind,
  String name,
) async {
  final l10n = context.l10n;
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => TagNameEditorDialog(
      title: l10n.metadataRenameTitle(kind),
      labelText: l10n.metadataNewName,
      hintText: l10n.metadataRenameHint(kind),
      initialValue: name,
      shouldCloseOnUnchanged: true,
      onSubmit: (String value) async {
        await ref
            .read(namedFacetManagementControllerProvider(kind).notifier)
            .rename(name, value);
      },
    ),
  );
}

Future<void> _deleteNamedFacet(
  BuildContext context,
  WidgetRef ref,
  ManagedNamedFacetKind kind,
  String name,
) async {
  final int count;
  try {
    count = await ref
        .read(namedFacetManagementControllerProvider(kind).notifier)
        .countAttachments(name);
  } catch (error) {
    if (context.mounted) {
      showErrorToast(context, error);
    }
    return;
  }
  if (!context.mounted) {
    return;
  }
  final bool confirmed =
      await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) =>
            _NamedFacetConfirmDeleteDialog(name: name, attachmentCount: count),
      ) ??
      false;
  if (!confirmed || !context.mounted) {
    return;
  }
  try {
    await ref
        .read(namedFacetManagementControllerProvider(kind).notifier)
        .delete(name);
    if (context.mounted) {
      showSuccessToast(context, context.l10n.metadataDeletedToast(kind));
    }
  } catch (error) {
    if (context.mounted) {
      showErrorToast(context, error);
    }
  }
}

Future<void> openNamedFacetCreateDialog(
  BuildContext context,
  WidgetRef ref,
  ManagedNamedFacetKind kind,
) async {
  final l10n = context.l10n;
  await showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => TagNameEditorDialog(
      title: l10n.metadataAddLabel(kind),
      labelText: l10n.metadataNameLabel,
      hintText: l10n.metadataAddHint(kind),
      initialValue: '',
      onSubmit: (String value) async {
        await ref
            .read(namedFacetManagementControllerProvider(kind).notifier)
            .add(value);
      },
    ),
  );
}

IconData _iconForKind(ManagedNamedFacetKind kind) => switch (kind) {
  ManagedNamedFacetKind.author => LucideIcons.penLine,
  ManagedNamedFacetKind.tag => LucideIcons.tags,
  ManagedNamedFacetKind.parody => LucideIcons.clapperboard,
  ManagedNamedFacetKind.character => LucideIcons.userRound,
};
