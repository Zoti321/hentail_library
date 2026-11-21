import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/features/library_admin/public/providers.dart';
import 'package:hentai_library/features/resource_metadata/public/contracts.dart';
import 'package:hentai_library/features/resource_metadata/public/providers.dart';
import 'package:hentai_library/features/resource_metadata/public/widgets.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/app_shell_navigation.dart';
import 'package:hentai_library/shared/ui/navigation/pop_or_go_home.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'media_dashboard.dart';

final _mediaOverviewProvider = FutureProvider.autoDispose
    .family<MediaOverview, bool>((ref, showR18) {
      ref.watch(writebackRevisionProvider);
      return ref.watch(writebackGatewayProvider).overview(showR18: showR18);
    });

class MediaPage extends ConsumerStatefulWidget {
  const MediaPage({super.key});
  @override
  ConsumerState<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends ConsumerState<MediaPage>
    with WidgetsBindingObserver {
  Timer? _updates;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updates = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  void _refresh() {
    if (mounted && _active) {
      final showR18 =
          ref.read(settingsProvider).asData?.value.healthyMode == false;
      ref.invalidate(_mediaOverviewProvider(showR18));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _updates?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = M3ETheme.of(context);
    final layout = PageLayoutSpec.of(context);
    final showR18 =
        ref.watch(settingsProvider).asData?.value.healthyMode == false;
    final overview = ref.watch(_mediaOverviewProvider(showR18));
    final scheme = theme.colorScheme;

    return ColoredBox(
      color: labBrowseCanvasColor(scheme),
      child: SafeArea(
        child: CustomScrollView(
          key: const PageStorageKey('media-overview'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: PageHeaderDelegate(
                layout: layout,
                child: LibraryToolbarRow(
                  title: PageTitle(l10n.mediaTitle),
                  onBack: () => popOrGoHome(context),
                  onOpenNavigation: appShellPageNavigationOpener(context),
                  menuTooltip: l10n.shellOpenNavMenu,
                  menuSemanticLabel: l10n.shellOpenNavMenu,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                layout.horizontalInset,
                layout.headerToBodyGap,
                layout.horizontalInset,
                layout.bodyBottomInset,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 42 * 16),
                      child: Text(
                        l10n.mediaSubtitle,
                        style: theme.typeScale.bodyLarge.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: theme.spacing.xl),
                  if (overview.hasError && overview.hasValue) ...[
                    _RefreshFailureBanner(message: l10n.mediaRefreshFailed),
                    SizedBox(height: theme.spacing.md),
                  ],
                  overview.when(
                    skipLoadingOnReload: true,
                    skipError: true,
                    data: (summary) => MediaDashboard(summary: summary),
                    loading: () => const _OverviewLoading(),
                    error: (error, stack) => _OverviewError(onRetry: _refresh),
                  ),
                  SizedBox(height: theme.spacing.xl + theme.spacing.sm),
                  const _LibraryWritingSettings(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewLoading extends StatelessWidget {
  const _OverviewLoading();

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) SizedBox(height: theme.spacing.md),
            _SkeletonBlock(
              height: 120,
              radius: i == 0
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(28),
                    )
                  : BorderRadius.circular(16),
              color: i == 0
                  ? scheme.primaryContainer.withValues(alpha: 0.45)
                  : scheme.surfaceContainerHigh,
            ),
          ],
          SizedBox(height: theme.spacing.xl),
          _SkeletonBlock(
            height: 168,
            radius: BorderRadius.circular(kTonalSurfaceRadius),
            color: scheme.surfaceContainer,
          ),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.height,
    required this.radius,
    required this.color,
  });

  final double height;
  final BorderRadius radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Material(
        color: color,
        borderRadius: radius,
        child: SizedBox(height: height, width: double.infinity),
      ),
    );
  }
}

class _OverviewError extends StatelessWidget {
  const _OverviewError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final layout = PageLayoutSpec.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: layout.stateTopInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.cloud_off, size: 48, color: scheme.outline),
              SizedBox(height: theme.spacing.sm),
              Text(
                l10n.shellLoadFailed,
                textAlign: TextAlign.center,
                style: theme.typeScale.titleMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(height: theme.spacing.md),
              M3EButton(
                onPressed: onRetry,
                label: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefreshFailureBanner extends StatelessWidget {
  const _RefreshFailureBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(
                Symbols.error_outline,
                size: 20,
                color: scheme.onErrorContainer,
              ),
              SizedBox(width: theme.spacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: theme.typeScale.bodyMedium.copyWith(
                    color: scheme.onErrorContainer,
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

class _LibraryWritingSettings extends ConsumerWidget {
  const _LibraryWritingSettings();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final libraries = ref.watch(librariesProvider);
    return SettingsSection(
      margin: EdgeInsets.zero,
      title: Text(l10n.mediaLibrarySettings),
      bottomInfo: Text(l10n.mediaAutomaticInfo),
      tiles: libraries.when(
        skipLoadingOnReload: true,
        data: (state) {
          final local = state.libraries
              .where((library) => library.kind == 'local')
              .toList();
          if (local.isEmpty) {
            return [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.mediaNoLocalLibraries),
              ),
            ];
          }
          return [
            for (final library in local)
              WritebackSetting(
                key: ValueKey(library.libraryId),
                libraryId: library.libraryId,
                libraryName: library.name,
              ),
          ];
        },
        loading: () => [
          const Padding(
            padding: EdgeInsets.all(16),
            child: M3EProgressIndicator.linear(),
          ),
        ],
        error: (error, stack) => [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.shellLoadFailed),
          ),
        ],
      ),
    );
  }
}
