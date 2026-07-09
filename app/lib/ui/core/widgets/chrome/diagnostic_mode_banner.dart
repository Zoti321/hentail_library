import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/state/diagnostic_mode_notifier.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DiagnosticModeBanner extends ConsumerWidget {
  const DiagnosticModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enabled = ref.watch(diagnosticModeProvider);
    if (!enabled) {
      return const SizedBox.shrink();
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primary.withValues(alpha: 0.1),
      child: Container(
        width: double.infinity,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.hentai.borderSubtle),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(LucideIcons.bug, size: 14, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '诊断模式已开启 · 正在记录更详细日志',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.hentai.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(diagnosticModeProvider.notifier).disable(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('关闭'),
            ),
            TextButton(
              onPressed: () => context.go('/settings'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('设置'),
            ),
          ],
        ),
      ),
    );
  }
}
