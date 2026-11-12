import io

p = 'lib/features/app_settings/presentation/views/settings_page/settings_page_body.dart'
s = io.open(p, encoding='utf-8').read()

# 1. split SettingsNarrowPaneSwitcher into own file
sw_start = s.index('/// Narrow master ↔ detail transition (slide + fade).')
switcher = s[sw_start:]
s = s[:sw_start].rstrip() + '\n'

switcher = switcher.replace(
    """        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.topLeft,
            children: <Widget>[...previousChildren, ?currentChild],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          final bool isIncoming = child.key == ValueKey<bool>(showingDetail);
          final Offset begin = isIncoming
              ? (showingDetail ? const Offset(0.12, 0) : const Offset(-0.08, 0))
              : (showingDetail
                    ? const Offset(-0.08, 0)
                    : const Offset(0.12, 0));
          return SlideTransition(
            position: Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },""",
    """        layoutBuilder: _layoutBuilder,
        transitionBuilder: _transitionBuilder,""",
)
switcher = switcher.replace(
    """    return ClipRect(""",
    """    return ClipRect(""",
)
# add builder methods inside the class before build
switcher = switcher.replace(
    """  final Widget detailPane;

  @override
  Widget build(BuildContext context) {""",
    """  final Widget detailPane;

  Widget _layoutBuilder(
    Widget? currentChild,
    List<Widget> previousChildren,
  ) {
    return Stack(
      alignment: Alignment.topLeft,
      children: <Widget>[...previousChildren, ?currentChild],
    );
  }

  Widget _transitionBuilder(Widget child, Animation<double> animation) {
    final bool isIncoming = child.key == ValueKey<bool>(showingDetail);
    final Offset begin = isIncoming
        ? (showingDetail ? const Offset(0.12, 0) : const Offset(-0.08, 0))
        : (showingDetail ? const Offset(-0.08, 0) : const Offset(0.12, 0));
    return SlideTransition(
      position: Tween<Offset>(begin: begin, end: Offset.zero).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {""",
)

# 2. replace _buildPage with _SettingsPageBody widget
bp_start = s.index('  Widget _buildPage(BuildContext context, {required bool listDetailWide}) {')
bp = s[bp_start:]
s = s[:bp_start].rstrip() + '\n'

body_tree = bp[bp.index('    return PopScope<Object?>('):].rstrip()
assert body_tree.endswith('}')
body_tree = body_tree[:-1].rstrip()
body_tree = body_tree.replace(
    """    final AppLocalizations l10n = context.l10n;
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final double horizontalPadding = layout.horizontalInset;

""",
    '',
)
body_tree = body_tree.replace('listDetailWide', 'host.listDetailWide')
body_tree = body_tree.replace('_selected', 'host._selected')
body_tree = body_tree.replace('_showingNarrowDetail', 'host._showingNarrowDetail')
body_tree = body_tree.replace('_detailTransitionReverse', 'host._detailTransitionReverse')
body_tree = body_tree.replace('_handleBack', 'host._handleBack')
body_tree = body_tree.replace('_labState', 'host._labState')
body_tree = body_tree.replace('_updateLabState', 'host._updateLabState')
body_tree = body_tree.replace('widget.', 'host.widget.')
body_tree = body_tree.replace(
    """      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          host._handleBack();
        }
      },""",
    """      onPopInvokedWithResult: host._handlePopInvoked,""",
)
body_tree = body_tree.replace(
    """                    onSelect: (SettingsCategory category) {
                      host._selectCategory(category, wide: wide);
                    },""",
    """                    onSelect: (SettingsCategory category) =>
                        host._selectCategory(category, wide: wide),""",
)

body_cls = """
class _SettingsPageBody extends StatelessWidget {
  const _SettingsPageBody({required this.host, required this.listDetailWide});

  final _SettingsPageState host;
  final bool listDetailWide;

  @override
  Widget build(BuildContext context) {
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final double horizontalPadding = layout.horizontalInset;

    return """ + body_tree.strip() + """;
  }
}

"""

s = s.rstrip() + '\n' + body_cls

# host methods
s = s.replace(
    """  /// 头部返回按钮与系统返回共用""",
    """  void _handlePopInvoked(bool didPop, Object? result) {
    if (!didPop) {
      _handleBack();
    }
  }

  /// 头部返回按钮与系统返回共用""",
)

# build() call site
s = s.replace(
    """        return _buildPage(
          context,
          listDetailWide: SettingsPageMetrics.useListDetail(
            constraints.maxWidth,
          ),
        );""",
    """        return _SettingsPageBody(
          host: this,
          listDetailWide: SettingsPageMetrics.useListDetail(
            constraints.maxWidth,
          ),
        );""",
)

# l10n still used in header Builder -> fine. export switcher
s = s.replace(
    "export 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_detail_panes.dart';",
    "export 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_detail_panes.dart';\nexport 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_narrow_pane_switcher.dart';",
)

io.open(p, 'w', encoding='utf-8', newline='\n').write(s)

sw_file = """import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';

""" + switcher.rstrip() + '\n'
io.open(
    'lib/features/app_settings/presentation/views/settings_page/settings_narrow_pane_switcher.dart',
    'w',
    encoding='utf-8',
    newline='\n',
).write(sw_file)
print('ok')
