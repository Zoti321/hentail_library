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
import 'package:material_3_expressive/material_3_expressive.dart';

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
    return Scaffold(
      backgroundColor: labBrowseCanvasColor(theme.colorScheme),
      body: SafeArea(
        child: Column(
          children: [
            PageHeaderChrome(
              layout: layout,
              child: SizedBox(
                height: PageLayoutSpec.toolbarRowHeight,
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      PageHeaderBackButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    Expanded(child: PageTitle(l10n.mediaTitle)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                key: const PageStorageKey('media-overview'),
                padding: EdgeInsets.fromLTRB(
                  layout.horizontalInset,
                  layout.headerToBodyGap,
                  layout.horizontalInset,
                  layout.bodyBottomInset,
                ),
                children: [
                  Text(
                    l10n.mediaSubtitle,
                    style: theme.typeScale.bodyLarge.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: theme.spacing.lg),
                  if (overview.hasError && overview.hasValue) ...[
                    Text(
                      l10n.mediaRefreshFailed,
                      style: theme.typeScale.bodyMedium.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    SizedBox(height: theme.spacing.md),
                  ],
                  overview.when(
                    skipLoadingOnReload: true,
                    skipError: true,
                    data: (summary) => MediaDashboard(summary: summary),
                    loading: () => Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: layout.stateTopInset,
                      ),
                      child: const Center(
                        child: M3EProgressIndicator.circular(),
                      ),
                    ),
                    error: (error, stack) => Column(
                      children: [
                        Text(l10n.shellLoadFailed),
                        SizedBox(height: theme.spacing.md),
                        M3EButton(
                          onPressed: _refresh,
                          label: Text(l10n.commonRetry),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: theme.spacing.xl),
                  const _LibraryWritingSettings(),
                ],
              ),
            ),
          ],
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
