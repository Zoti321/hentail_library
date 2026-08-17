import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/library_sidebar_layout.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/core/widgets/navigation/desktop_sidebar.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/library_reorder_mode.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Full-sidebar Library reorder mode (Pinned / Unpinned, cross-section drag).
class LibrariesSidebarReorderPane extends HookConsumerWidget {
  const LibrariesSidebarReorderPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final List<LocalLibrary> libraries =
        ref.watch(currentLibraryProvider).asData?.value.libraries ??
        const <LocalLibrary>[];
    final LibrarySidebarSections sections = splitLibrarySidebar(libraries);
    final ValueNotifier<List<LocalLibrary>> pinned = useState(sections.pinned);
    final ValueNotifier<List<LocalLibrary>> unpinned = useState(
      sections.unpinned,
    );

    useEffect(() {
      pinned.value = sections.pinned;
      unpinned.value = sections.unpinned;
      return null;
    }, <Object?>[libraries]);

    final ObjectRef<Future<void>> writeChain = useRef(Future<void>.value());

    Future<void> persistLatest() async {
      final LibrarySidebarSections snapshot = (
        pinned: List<LocalLibrary>.from(pinned.value),
        unpinned: List<LocalLibrary>.from(unpinned.value),
      );
      try {
        await ref
            .read(currentLibraryProvider.notifier)
            .updateSidebarLayout(
              encodeLibrarySidebarLayout(
                pinned: snapshot.pinned,
                unpinned: snapshot.unpinned,
              ),
            );
      } catch (err) {
        if (context.mounted) {
          showErrorToast(context, err);
        }
        await ref.read(currentLibraryProvider.notifier).refresh();
      }
    }

    final List<Widget> rows = <Widget>[
      _ReorderSectionTitle(
        key: const ValueKey<String>('sidebar-pinned-header'),
        label: l10n.sidebarPinnedSection,
      ),
      for (int i = 0; i < pinned.value.length; i++)
        _ReorderLibraryRow(
          key: ValueKey<String>(pinned.value[i].libraryId),
          library: pinned.value[i],
          index: 1 + i,
        ),
      _ReorderSectionTitle(
        key: const ValueKey<String>('sidebar-unpinned-header'),
        label: l10n.sidebarUnpinnedSection,
      ),
      for (int i = 0; i < unpinned.value.length; i++)
        _ReorderLibraryRow(
          key: ValueKey<String>(unpinned.value[i].libraryId),
          library: unpinned.value[i],
          index: 1 + pinned.value.length + 1 + i,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: DesktopSidebar.navItemHeight,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.sidebarReorderLibraries,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.hentai.textPrimary,
                    fontSize: tokens.text.bodyMd,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GhostButton.icon(
                icon: LucideIcons.x,
                tooltip: l10n.sidebarExitReorder,
                semanticLabel: l10n.sidebarExitReorder,
                iconSize: 16,
                size: 28,
                borderRadius: tokens.radius.sm,
                foregroundColor: cs.hentai.textSecondary,
                hoverColor: cs.hentai.sidebarItemHoverBackground,
                overlayColor: cs.hentai.sidebarItemHoverBackground.withAlpha(
                  110,
                ),
                delayTooltipThreeSeconds: true,
                onPressed: () =>
                    ref.read(libraryReorderModeProvider.notifier).exit(),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spacing.sm),
        Expanded(
          child: ReorderableListView(
            buildDefaultDragHandles: false,
            padding: EdgeInsets.zero,
            onReorder: (int oldIndex, int newIndex) {
              final LibrarySidebarSections next = applyLibrarySidebarReorder(
                pinned: pinned.value,
                unpinned: unpinned.value,
                oldIndex: oldIndex,
                newIndex: newIndex,
              );
              if (_sameIds(pinned.value, next.pinned) &&
                  _sameIds(unpinned.value, next.unpinned)) {
                return;
              }
              pinned.value = next.pinned;
              unpinned.value = next.unpinned;
              writeChain.value = writeChain.value
                  .catchError((Object _) {})
                  .then((_) => persistLatest());
            },
            children: rows,
          ),
        ),
      ],
    );
  }
}

bool _sameIds(List<LocalLibrary> a, List<LocalLibrary> b) {
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i].libraryId != b[i].libraryId) {
      return false;
    }
  }
  return true;
}

class _ReorderSectionTitle extends StatelessWidget {
  const _ReorderSectionTitle({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spacing.sm,
          tokens.spacing.sm,
          tokens.spacing.sm,
          tokens.spacing.xs,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.hentai.textTertiary,
            fontSize: tokens.text.labelXs,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ReorderLibraryRow extends StatelessWidget {
  const _ReorderLibraryRow({
    super.key,
    required this.library,
    required this.index,
  });

  final LocalLibrary library;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final String name = localLibraryDisplayName(library);

    return ReorderableDragStartListener(
      index: index,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: DesktopSidebar.navItemVerticalMargin,
          ),
          height: DesktopSidebar.navItemHeight,
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm),
          child: Row(
            children: <Widget>[
              Icon(
                LucideIcons.gripVertical,
                size: 16,
                color: cs.hentai.textTertiary,
              ),
              SizedBox(width: tokens.spacing.sm),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.hentai.textSecondary,
                    fontSize: tokens.text.bodyMd,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
