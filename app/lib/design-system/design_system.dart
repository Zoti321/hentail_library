/// Design System 层：业务无关的主题、动效、布局常量与通用控件（ADR-0044）。
///
/// 本文件是**唯一对外入口**。层内不得依赖产品 feature、`shared` 的业务层
/// （ui / domain / di / data）；只允许 `core`、`shared/util`、层内路径与第三方包。
/// 门禁：`app/test/design-system/design_system_boundary_test.dart`（零 allowlist）。
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
export 'package:hentai_library/design-system/layout/list_detail_adaptive_layout.dart';
export 'package:hentai_library/design-system/layout/metadata_edit_form_metrics.dart';
export 'package:hentai_library/design-system/layout/page_layout_spec.dart';
export 'package:hentai_library/design-system/layout/pinned_toolbar_chrome_metrics.dart';
export 'package:hentai_library/design-system/layout/spacing.dart';

// components
export 'package:hentai_library/design-system/components/actions/catalog_view_mode_button_group.dart';
export 'package:hentai_library/design-system/components/calendar/anchored_calendar_date_picker.dart';
export 'package:hentai_library/design-system/components/calendar/calendar_day_cell.dart';
export 'package:hentai_library/design-system/components/calendar/calendar_day_picker.dart';
export 'package:hentai_library/design-system/components/calendar/calendar_month_picker.dart';
export 'package:hentai_library/design-system/components/calendar/calendar_year_picker.dart';
export 'package:hentai_library/design-system/components/calendar/docked_calendar_date_picker.dart';
export 'package:hentai_library/design-system/components/calendar/embeddable_calendar_date_picker.dart';
export 'package:hentai_library/design-system/components/chips/outlined_meta_chip.dart';
export 'package:hentai_library/design-system/components/chips/suggestion_chip_surface.dart';
export 'package:hentai_library/design-system/components/inputs/input_chip_field_layout.dart';
export 'package:hentai_library/design-system/components/inputs/management_entity_name_field.dart';
export 'package:hentai_library/design-system/components/inputs/named_facet_multi_select_copy.dart';
export 'package:hentai_library/design-system/components/inputs/named_facet_multi_select_field.dart';
export 'package:hentai_library/design-system/components/inputs/outlined_text_field.dart';
export 'package:hentai_library/design-system/components/inputs/outlined_text_field_selection_scope.dart';
export 'package:hentai_library/design-system/components/inputs/outlined_text_field_shell.dart';
export 'package:hentai_library/design-system/components/inputs/published_date_text_field.dart';
export 'package:hentai_library/design-system/components/inputs/tag_input_field.dart';
export 'package:hentai_library/design-system/components/list_detail/list_detail_detail_transition.dart';
export 'package:hentai_library/design-system/components/list_detail/list_detail_nav_item.dart';
export 'package:hentai_library/design-system/components/lists/reorder_exclude.dart';
export 'package:hentai_library/design-system/components/lists/reorderable_split_list_group.dart';
export 'package:hentai_library/design-system/components/lists/split_list_group.dart';
export 'package:hentai_library/design-system/components/menu/anchored_menu.dart';
export 'package:hentai_library/design-system/components/scaffold/library_page_header_metrics.dart';
export 'package:hentai_library/design-system/components/scaffold/metadata_edit_form_scroll.dart';
export 'package:hentai_library/design-system/components/scaffold/metadata_field_label_row.dart';
export 'package:hentai_library/design-system/components/scaffold/page_header.dart';
export 'package:hentai_library/design-system/components/scaffold/page_header_back_button.dart';
export 'package:hentai_library/design-system/components/scaffold/page_title.dart';
export 'package:hentai_library/design-system/components/scaffold/pinned_toolbar_chrome.dart';
export 'package:hentai_library/design-system/components/selection/segmented_capsule_bar.dart';
export 'package:hentai_library/design-system/components/selection/segmented_capsule_bar_metrics.dart';
export 'package:hentai_library/design-system/components/surfaces/tonal_surface.dart';

// util
export 'package:hentai_library/design-system/util/navigation_rail_icon.dart';
export 'package:hentai_library/design-system/util/reorder_index.dart';

// l10n（直接路径暴露，不经 barrel：`design-system/l10n/m3e_material_localizations.dart`）
