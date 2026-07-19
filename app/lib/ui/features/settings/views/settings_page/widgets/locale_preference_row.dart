import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LocalePreferenceRow extends ConsumerStatefulWidget {
  const LocalePreferenceRow({
    required this.layoutTier,
    required this.viewportWidth,
    super.key,
  });

  final SettingsLayoutTier layoutTier;
  final double viewportWidth;

  @override
  ConsumerState<LocalePreferenceRow> createState() =>
      _LocalePreferenceRowState();
}

class _LocalePreferenceRowState extends ConsumerState<LocalePreferenceRow> {
  final CustomPopupMenuController menuController = CustomPopupMenuController();

  Future<void> applyLocale(AppLocalePreference value) async {
    menuController.hideMenu();
    await ref.read(settingsProvider.notifier).setLocalePreference(value);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalePreference? preference = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) => async.asData?.value.localePreference,
      ),
    );
    if (preference == null) {
      return const SizedBox.shrink();
    }
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final AppLocalizations l10n = context.l10n;
    final double menuWidth = settingsThemeMenuWidth(
      widget.layoutTier,
      widget.viewportWidth,
    );
    final bool usesChevronAction = settingsThemeRowUsesChevronAction(
      widget.layoutTier,
    );

    final Widget menuTrigger = usesChevronAction
        ? Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: colorScheme.hentai.iconSecondary,
          )
        : GhostButton.iconText(
            icon: LucideIcons.chevronsUpDown,
            text: l10n.localePreferenceLabel(preference),
            tooltip: '',
            semanticLabel: l10n.settingsLanguageLabel,
            iconSize: 14,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            borderRadius: tokens.radius.md,
            foregroundColor: colorScheme.hentai.textSecondary,
            hoverColor: colorScheme.hentai.hoverBackground,
            overlayColor: colorScheme.primary.withAlpha(14),
            delayTooltipThreeSeconds: false,
            onPressed: () => menuController.toggleMenu(),
          );

    return SettingsRow(
      layoutTier: widget.layoutTier,
      icon: Icon(
        LucideIcons.languages,
        size: 20,
        color: colorScheme.hentai.iconDefault,
      ),
      label: l10n.settingsLanguageLabel,
      onRowTap: () => menuController.showMenu(),
      action: CustomPopupMenu(
        controller: menuController,
        barrierColor: Colors.transparent,
        pressType: PressType.singleClick,
        showArrow: false,
        verticalMargin: -24,
        menuBuilder: () => AppLocalePreferenceMenuPanel(
          width: menuWidth,
          current: preference,
          onSelect: applyLocale,
        ),
        child: menuTrigger,
      ),
    );
  }
}

class AppLocalePreferenceMenuPanel extends StatelessWidget {
  const AppLocalePreferenceMenuPanel({
    required this.width,
    required this.current,
    required this.onSelect,
    super.key,
  });

  final double width;
  final AppLocalePreference current;
  final Future<void> Function(AppLocalePreference value) onSelect;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final AppLocalizations l10n = context.l10n;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: colorScheme.hentai.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.hentai.cardShadowHover,
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
                  bottom: BorderSide(color: colorScheme.hentai.borderSubtle),
                ),
              ),
              child: Text(
                l10n.settingsLanguageLabel,
                style: TextStyle(
                  fontSize: tokens.text.bodySm,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.hentai.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: AppLocalePreference.values.map((
                  AppLocalePreference option,
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
                                    : colorScheme.hentai.textTertiary,
                              ),
                              SizedBox(width: tokens.spacing.sm),
                              Expanded(
                                child: Text(
                                  l10n.localePreferenceLabel(option),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.hentai.textPrimary,
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
