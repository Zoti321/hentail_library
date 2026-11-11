/// Design System 层：业务无关的主题、动效、布局常量与通用控件（ADR-0044）。
///
/// 本文件是**唯一对外入口**。层内不得 import `features/**`、`shared/ui/**`、
/// `shared/domain/**`、`shared/di/**`、`shared/data/**`；只允许依赖
/// `core/**`、`shared/util/**`、层内相对路径与第三方包。
library;

// theme
export 'package:hentai_library/design-system/theme/app_font.dart';
export 'package:hentai_library/design-system/theme/app_m3e_theme.dart';
export 'package:hentai_library/design-system/theme/lab_text.dart';
export 'package:hentai_library/design-system/theme/theme.dart';

// motion
export 'package:hentai_library/design-system/motion/app_motion.dart';
export 'package:hentai_library/design-system/motion/catalog_detail_page.dart';
export 'package:hentai_library/design-system/motion/desktop_page_transition.dart';
export 'package:hentai_library/design-system/motion/effects_decorated_box.dart';
export 'package:hentai_library/design-system/motion/mode_chrome_transition.dart';
export 'package:hentai_library/design-system/motion/motion.dart';
export 'package:hentai_library/design-system/motion/peer_content_transition.dart';
export 'package:hentai_library/design-system/motion/shared_axis_route.dart';
export 'package:hentai_library/design-system/motion/spring_curve.dart';
export 'package:hentai_library/design-system/motion/spring_positioned.dart';
export 'package:hentai_library/design-system/motion/spring_reveal.dart';
export 'package:hentai_library/design-system/motion/spring_size.dart';
export 'package:hentai_library/design-system/motion/spring_value.dart';

// layout
export 'package:hentai_library/design-system/layout/app_layout_breakpoints.dart';
export 'package:hentai_library/design-system/layout/breakpoints.dart';
export 'package:hentai_library/design-system/layout/fab_sizing.dart';
export 'package:hentai_library/design-system/layout/page_layout_spec.dart';
export 'package:hentai_library/design-system/layout/spacing.dart';

// l10n（直接路径暴露，不经 barrel：`design-system/l10n/m3e_material_localizations.dart`）
