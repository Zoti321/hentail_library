import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/domain/entity/app_setting.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/settings_page/widgets/settings_page_constants.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ThemePreferenceRow extends ConsumerStatefulWidget {
  const ThemePreferenceRow({super.key});

  @override
  ConsumerState<ThemePreferenceRow> createState() => _ThemePreferenceRowState();
}

class _ThemePreferenceRowState extends ConsumerState<ThemePreferenceRow> {
  final CustomPopupMenuController menuController = CustomPopupMenuController();

  Future<void> applyTheme(AppThemePreference value) async {
    menuController.hideMenu();
    await ref.read(settingsProvider.notifier).setThemePreference(value);
  }

  @override
  Widget build(BuildContext context) {
    final AppThemePreference? preference = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) => async.asData?.value.themePreference,
      ),
    );
    if (preference == null) {
      return const SizedBox.shrink();
    }
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return SettingsRow(
      icon: Icon(LucideIcons.palette, size: 20, color: colorScheme.iconDefault),
      label: '应用主题',
      description: '可跟随系统或固定浅色、深色；当前：${preference.labelZh}',
      onRowTap: () => menuController.showMenu(),
      action: CustomPopupMenu(
        controller: menuController,
        barrierColor: Colors.transparent,
        pressType: PressType.singleClick,
        showArrow: false,
        verticalMargin: -24,
        menuBuilder: () => AppThemePreferenceMenuPanel(
          current: preference,
          onSelect: applyTheme,
        ),
        child: GhostButton.iconText(
          icon: LucideIcons.chevronsUpDown,
          text: preference.labelZh,
          tooltip: '',
          semanticLabel: '选择应用主题',
          iconSize: 14,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          borderRadius: tokens.radius.md,
          foregroundColor: colorScheme.textSecondary,
          hoverColor: colorScheme.hoverBackground,
          overlayColor: colorScheme.primary.withAlpha(14),
          delayTooltipThreeSeconds: false,
          onPressed: () => menuController.toggleMenu(),
        ),
      ),
    );
  }
}

class AppThemePreferenceMenuPanel extends StatelessWidget {
  const AppThemePreferenceMenuPanel({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final AppThemePreference current;
  final Future<void> Function(AppThemePreference value) onSelect;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Container(
      width: appThemeMenuWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: colorScheme.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.cardShadowHover,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(color: colorScheme.borderSubtle),
                ),
              ),
              child: Text(
                '应用主题',
                style: TextStyle(
                  fontSize: tokens.text.bodySm,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: AppThemePreference.values.map((
                  AppThemePreference option,
                ) {
                  final bool isSelected = option == current;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onSelect(option),
                        borderRadius: BorderRadius.circular(tokens.radius.md),
                        hoverColor: colorScheme.primary.withAlpha(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.spacing.sm,
                            vertical: tokens.spacing.sm,
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                isSelected
                                    ? LucideIcons.circleCheckBig
                                    : LucideIcons.circle,
                                size: 18,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.textTertiary,
                              ),
                              SizedBox(width: tokens.spacing.sm),
                              Expanded(
                                child: Text(
                                  option.labelZh,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
