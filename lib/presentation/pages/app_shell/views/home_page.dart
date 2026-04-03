import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/button/home_refresh_button.dart';
import 'package:hentai_library/presentation/widgets/dialog/scan_progress_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _onTapScanLibrary(BuildContext context, WidgetRef ref) {
    final running = ref.read(
      scanLibraryControllerProvider.select((s) => s.running),
    );
    if (!running) {
      // 点击即启动任务，对话框只订阅状态。
      ref.read(scanLibraryControllerProvider.notifier).start();
    }

    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (_) => const ScanProgressDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final comicCount = ref.watch(
      libraryPageProvider.select((s) => s.rawList.length),
    );

    ref.listen(scanLibraryControllerProvider, (prev, next) {
      final wasRunning = prev?.running ?? false;
      if (!wasRunning || next.running) return;
      if (next.cancelled) return;
      if (next.error != null) return;
      ref.read(libraryPageProvider.notifier).refreshStream();
    });

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            SizedBox(height: tokens.spacing.xl + 12),
            _buildHeroWidgets(context, ref, comicCount),
            SizedBox(height: tokens.spacing.lg + 8),
            _buildShortcutEntries(context, ref),
            SizedBox(height: tokens.spacing.xl * 4),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final cs = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '首页',
              style: TextStyle(
                color: cs.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: tokens.spacing.xs),
            Text(
              '下午好，读者',
              style: TextStyle(
                color: cs.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            HomeRefreshButton(
              onPressed: () async {
                ref.read(libraryPageProvider.notifier).refreshStream();
              },
            ),
            FilledButton.icon(
              onPressed: () => _onTapScanLibrary(context, ref),
              icon: const Icon(LucideIcons.scanSearch, size: 18),
              label: const Text('扫描漫画库'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroWidgets(
    BuildContext context,
    WidgetRef ref,
    int comicCount,
  ) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final cs = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(tokens.spacing.lg + 8),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '漫画库',
                    style: TextStyle(
                      fontSize: tokens.text.labelXs,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: cs.textTertiary,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.sm),
                  Text(
                    '$comicCount',
                    style: TextStyle(
                      fontSize: tokens.text.titleLg + 4,
                      fontWeight: FontWeight.w600,
                      color: cs.textPrimary,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.sm - 2),
                  Text(
                    '共 $comicCount 本',
                    style: TextStyle(
                      fontSize: tokens.text.bodySm,
                      color: cs.textSecondary,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(tokens.spacing.sm),
                child: Icon(LucideIcons.bookImage, size: 32, color: cs.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutEntries(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Wrap(
      spacing: tokens.spacing.md,
      runSpacing: tokens.spacing.md,
      children: [
        _ShortcutEntry(
          icon: LucideIcons.library,
          label: '漫画库',
          onTap: () => context.go('/local'),
          colorScheme: cs,
          tokens: tokens,
        ),
        _ShortcutEntry(
          icon: LucideIcons.folderTree,
          label: '选中路径',
          onTap: () => context.go('/paths'),
          colorScheme: cs,
          tokens: tokens,
        ),
        _ShortcutEntry(
          icon: LucideIcons.scanSearch,
          label: '扫描漫画库',
          onTap: () => _onTapScanLibrary(context, ref),
          colorScheme: cs,
          tokens: tokens,
        ),
      ],
    );
  }
}

class _ShortcutEntry extends StatelessWidget {
  const _ShortcutEntry({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
    required this.tokens,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.lg,
            vertical: tokens.spacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: tokens.text.bodyMd,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
