import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/config/app_fluent_color_scheme.dart';
import 'package:hentai_library/core/util/snackbar_util.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/widgets/button/home_refresh_button.dart';
import 'package:hentai_library/presentation/widgets/dialog/scan_progress_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// 单例扫描约束：扫描进行中不打开新对话框，并提示用户。
  static void _openScanDialogIfAllowed(BuildContext context, WidgetRef ref) {
    if (ref.read(scanInProgressProvider)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('扫描进行中，请勿重复操作'),
            behavior: SnackBarBehavior.floating,
            margin: snackBarMargin(context),
          ),
        );
      }
      return;
    }
    ref.read(scanInProgressProvider.notifier).setInProgress(true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ScanProgressDialog(
        onBackgroundComplete: () {
          if (!context.mounted) return;
          ref.read(libraryPageProvider.notifier).refreshStream();
        },
        onScanEnd: () {
          ref.read(scanInProgressProvider.notifier).setInProgress(false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comicCount = ref
        .watch(libraryPageProvider.select((s) => s.rawList.length));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            const SizedBox(height: 32),
            _buildHeroWidgets(context, ref, comicCount),
            const SizedBox(height: 24),
            _buildShortcutEntries(context, ref),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '下午好，读者',
              style: TextStyle(color: cs.textTertiary, fontSize: 14),
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
              onPressed: () => _openScanDialogIfAllowed(context, ref),
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
                  borderRadius: BorderRadius.circular(10),
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
    final cs = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: cs.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: cs.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$comicCount',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: cs.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '共 $comicCount 本',
                    style: TextStyle(fontSize: 13, color: cs.textSecondary),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(LucideIcons.bookImage, size: 32, color: cs.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutEntries(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ShortcutEntry(
          icon: LucideIcons.library,
          label: '漫画库',
          onTap: () => context.go('/local'),
          colorScheme: cs,
        ),
        _ShortcutEntry(
          icon: LucideIcons.folderTree,
          label: '选中路径',
          onTap: () => context.go('/paths'),
          colorScheme: cs,
        ),
        _ShortcutEntry(
          icon: LucideIcons.scanSearch,
          label: '扫描漫画库',
          onTap: () => _openScanDialogIfAllowed(context, ref),
          colorScheme: cs,
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
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
                  fontSize: 14,
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
