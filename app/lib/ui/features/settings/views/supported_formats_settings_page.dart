import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/confirm/disable_all_format_groups_confirm_dialog.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/ui/features/shell/views/selected_paths_page/widgets/selected_paths_header.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Supported resource formats 设置子页：草稿勾选 + 保存。
class SupportedFormatsSettingsPage extends ConsumerStatefulWidget {
  const SupportedFormatsSettingsPage({super.key});

  @override
  ConsumerState<SupportedFormatsSettingsPage> createState() =>
      _SupportedFormatsSettingsPageState();
}

class _SupportedFormatsSettingsPageState
    extends ConsumerState<SupportedFormatsSettingsPage> {
  Set<FormatGroup>? _draft;
  bool _saving = false;

  Set<FormatGroup> _draftOrLoaded(AppSetting setting) {
    return _draft ?? setting.enabledFormatGroups.toSet();
  }

  Future<void> _save(Set<FormatGroup> draft) async {
    if (_saving) return;
    if (requiresDisableAllFormatGroupsConfirm(draft)) {
      final bool confirmed =
          await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) =>
                const DisableAllFormatGroupsConfirmDialog(),
          ) ??
          false;
      if (!confirmed || !mounted) {
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final List<FormatGroup> ordered = FormatGroup.all
          .where(draft.contains)
          .toList(growable: false);
      await ref.read(settingsProvider.notifier).setEnabledFormatGroups(ordered);
      if (!mounted) return;
      setState(() {
        _draft = null;
        _saving = false;
      });
      context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final AsyncValue<AppSetting> settingsAsync = ref.watch(settingsProvider);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth = constraints.maxWidth;
        final SettingsLayoutTier layoutTier = settingsLayoutTierForWidth(
          viewportWidth,
        );
        final double horizontalPadding = settingsContentHorizontalPadding(
          layoutTier,
        );
        final double innerMaxWidth = settingsInnerContentMaxWidth(
          layoutTier,
          viewportWidth,
        );
        final l10n = context.l10n;
        final ThemeData theme = Theme.of(context);
        final ColorScheme cs = theme.colorScheme;

        return settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace _) => Center(child: Text('$error')),
          data: (AppSetting setting) {
            final Set<FormatGroup> draft = _draftOrLoaded(setting);
            final bool dirty = !_setEquals(
              draft,
              setting.enabledFormatGroups.toSet(),
            );

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: PageContentWidthAlign(
                    horizontalPadding: horizontalPadding,
                    maxWidth: innerMaxWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: SizedBox(
                        height: 44,
                        child: Row(
                          children: <Widget>[
                            GhostButton.icon(
                              icon: LucideIcons.arrowLeft,
                              tooltip: l10n.shellBack,
                              semanticLabel: l10n.shellBackToSettings,
                              iconSize: 16,
                              size: 32,
                              borderRadius: 8,
                              foregroundColor: cs.hentai.iconDefault,
                              hoverColor: theme.hoverColor,
                              overlayColor: theme.hoverColor,
                              onPressed: () =>
                                  SelectedPathsPageHeaderToolbar.popOrGoSettings(
                                    context,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.settingsSupportedFormatsTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: cs.hentai.textPrimary,
                                ),
                              ),
                            ),
                            FilledButton(
                              onPressed: dirty && !_saving
                                  ? () => _save(draft)
                                  : null,
                              child: Text(l10n.commonSave),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: PageContentWidthAlign(
                    horizontalPadding: horizontalPadding,
                    maxWidth: innerMaxWidth,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: tokens.layout.contentVerticalPadding,
                        bottom: tokens.layout.contentAreaPadding.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 16,
                        children: <Widget>[
                          Text(
                            l10n.settingsSupportedFormatsDescription,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.hentai.textSecondary,
                            ),
                          ),
                          SettingsGroup(
                            title: l10n.settingsSupportedFormatsGroupTitle,
                            children: <Widget>[
                              for (final FormatGroup group in FormatGroup.all)
                                SettingsRow(
                                  layoutTier: layoutTier,
                                  icon: Icon(
                                    _iconFor(group),
                                    size: 20,
                                    color: cs.hentai.iconDefault,
                                  ),
                                  label: l10n.formatGroupLabel(group),
                                  onRowTap: () {
                                    setState(() {
                                      final Set<FormatGroup> next =
                                          Set<FormatGroup>.from(draft);
                                      if (next.contains(group)) {
                                        next.remove(group);
                                      } else {
                                        next.add(group);
                                      }
                                      _draft = next;
                                    });
                                  },
                                  action: Checkbox(
                                    value: draft.contains(group),
                                    onChanged: (bool? checked) {
                                      setState(() {
                                        final Set<FormatGroup> next =
                                            Set<FormatGroup>.from(draft);
                                        if (checked ?? false) {
                                          next.add(group);
                                        } else {
                                          next.remove(group);
                                        }
                                        _draft = next;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static IconData _iconFor(FormatGroup group) {
    return switch (group) {
      FormatGroup.folder => LucideIcons.folder,
      FormatGroup.pdf => LucideIcons.fileText,
      FormatGroup.epub => LucideIcons.bookOpen,
      FormatGroup.archive => LucideIcons.fileArchive,
    };
  }

  static bool _setEquals(Set<FormatGroup> a, Set<FormatGroup> b) {
    return a.length == b.length && a.containsAll(b);
  }
}
