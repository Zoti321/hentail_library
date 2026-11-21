/// The application's visual and interaction system (ADR-0053).
/// Consumers use this explicit public surface; implementation imports stay local.
library;

export 'components/actions/catalog_view_mode_button_group.dart'
    show
        CatalogViewMode,
        CatalogViewModeButtonGroup,
        catalogViewModeButtonGroupDecoration,
        kCatalogViewModeButtonGroupIconSize;
export 'components/actions/ghost_button.dart' show GhostButton;
export 'components/actions/popup_menu_panel_shell.dart'
    show PopupMenuPanelShell;
export 'components/calendar/anchored_calendar_date_picker.dart'
    show showAnchoredCalendarDatePicker;
export 'components/calendar/calendar_date_picker_surface.dart'
    show CalendarDatePickerSurface;
export 'components/calendar/calendar_day_cell.dart' show CalendarDayCell;
export 'components/calendar/calendar_day_picker.dart' show CalendarDayPicker;
export 'components/calendar/calendar_month_picker.dart'
    show CalendarMonthPicker;
export 'components/calendar/calendar_year_picker.dart'
    show
        CalendarYearPicker,
        calendarYearViewHeight,
        kCalendarYearPickerRowHeight;
export 'components/calendar/docked_calendar_date_picker.dart'
    show
        DockedCalendarDatePicker,
        kPublishedDatePickerFirstDate,
        kPublishedDatePickerLastDate;
export 'components/calendar/embeddable_calendar_date_picker.dart'
    show EmbeddableCalendarDatePicker;
export 'components/catalog/age_restriction_chip_mount.dart'
    show AgeRestrictionChipMount;
export 'components/catalog/comic_card.dart'
    show
        ComicCard,
        ComicCardVisualState,
        kComicCardCoverProgressHeight,
        kComicCardCoverProgressKey,
        kComicCardSelectionInset;
export 'components/catalog/comic_catalog_card_shell.dart'
    show
        ComicCatalogCardShell,
        comicCatalogSubtitleStyle,
        comicCatalogTitleStyle,
        kComicCardRadius,
        kComicCatalogContentHorizontalPadding,
        kComicCatalogPinnedOverlayAlphaLight,
        kComicCatalogPinnedOverlayAlphaStrong;
export 'components/catalog/comic_detail_age_restriction_chip.dart'
    show ComicDetailAgeRestrictionChip;
export 'components/catalog/comic_detail_age_restriction_chip_slot.dart'
    show
        ComicDetailAgeRestrictionChipSlot,
        kComicDetailAgeRestrictionChipHideDebounce;
export 'components/catalog/comic_detail_cover.dart' show AppComicDetailCover;
export 'components/catalog/comic_detail_meta_chip_row.dart'
    show
        ComicDetailMetaChipRow,
        kComicDetailMetaChipGap,
        kComicDetailMetaLabelWidth;
export 'components/catalog/comic_list_item.dart'
    show
        ComicListItem,
        ComicListItemVisualState,
        ComicListMoreMenuEntry,
        kComicListItemCoverHeight,
        kComicListItemCoverWidth,
        kComicListItemInfoProgressKey,
        kComicListItemInfoProgressSlotKey,
        kComicListItemMetaSeparator,
        kComicListItemMetaSlotHeight,
        kComicListItemMinHeight,
        kComicListItemProgressMaxWidth,
        kComicListItemProgressTopGap,
        kComicListItemTagChipGap,
        kComicListItemTagSlotHeight,
        kComicListItemTagSlotKey,
        kComicListItemTagTopGap,
        kComicListItemTitleSlotHeight,
        kComicListItemVerticalPadding;
export 'components/catalog/overflow_title_hover_label.dart'
    show OverflowTitleHoverLabel, kOverflowTitleHoverWait;
export 'components/catalog/cover_read_progress_strip.dart'
    show
        CoverReadProgressStrip,
        kCoverReadProgressHeight,
        showsReadProgressStrip;
export 'components/chips/outlined_meta_chip.dart' show OutlinedMetaChip;
export 'components/chips/suggestion_chip_surface.dart'
    show SuggestionChipSurface;
export 'components/dialog/adaptive_form_dialog.dart'
    show showAdaptiveFormDialog;
export 'components/dialog/confirm_dialog.dart' show showConfirmDialog;
export 'components/dialog/lab_dialog_presenter.dart' show LabDialogPresenter;
export 'components/dialog/lab_dialog_route.dart' show pushLabDialogRoute;
export 'components/feedback/app_snackbar.dart'
    show
        kAppSnackbarDefaultDuration,
        showAppSnackbar,
        showInfoSnackbar,
        showSuccessSnackbar;
export 'components/images/comic_cover_placeholder.dart'
    show
        ComicCoverPlaceholder,
        ComicCoverPlaceholderKind,
        ComicCoverPlaceholderVariant;
export 'components/images/cover_hero.dart' show CoverHero;
export 'components/images/cover_letterbox.dart'
    show
        coverFitForAspects,
        coverFitForImageSize,
        coverLetterboxColor,
        kCoverSoftCropAspectTolerance,
        peekCoverImageSize;
export 'components/inputs/app_dense_search_bar.dart' show AppDenseSearchBar;
export 'components/inputs/compact_input_chip.dart' show CompactInputChip;
export 'components/inputs/input_chip_field_layout.dart'
    show
        InputChipFieldContent,
        compactInputChipTheme,
        inputChipCommitLabel,
        inputChipDisplayLabel,
        inputChipFieldVerticalInsets,
        inputChipInlineTopInset,
        inputChipInlineWidth,
        inputChipRowLineHeight,
        kInputChipCompactHeight,
        kInputChipFieldGap,
        kInputChipFieldInlineMinWidth,
        kInputChipInlineCaretGap,
        kInputChipInlineEmptyWidth,
        kInputChipMaxLabelLength,
        outlinedTextFieldMinHeight,
        resolveInputChipInlineMetrics;
export 'components/inputs/management_entity_name_field.dart'
    show ManagementEntityNameField;
export 'components/inputs/metadata_field_lock_button.dart'
    show MetadataFieldLockButton;
export 'components/inputs/named_facet_multi_select_copy.dart'
    show NamedFacetMultiSelectCopy;
export 'components/inputs/named_facet_multi_select_field.dart'
    show FacetMultiSelectField;
export 'components/inputs/outlined_text_field.dart' show OutlinedTextField;
export 'components/inputs/outlined_text_field_selection_scope.dart'
    show OutlinedTextFieldSelectionScope;
export 'components/inputs/outlined_text_field_shell.dart'
    show
        OutlinedTextFieldInputBuilder,
        OutlinedTextFieldShell,
        OutlinedTextFieldTrailingBuilder;
export 'components/inputs/published_date_text_field.dart'
    show PublishedDateTextField;
export 'components/inputs/tag_input_field.dart'
    show TagInputField, kTagInputFieldMaxWidth, kTagInputFieldMinWidth;
export 'components/list_detail/list_detail_detail_transition.dart'
    show ListDetailDetailTransition;
export 'components/list_detail/list_detail_nav_item.dart'
    show ListDetailNavItem;
export 'components/lists/reorder_exclude.dart'
    show ReorderExclude, isPointerInReorderExclude;
export 'components/lists/reorderable_split_list_group.dart'
    show ReorderableSplitListGroup;
export 'components/lists/split_drag_scope.dart'
    show SplitDragScope, kSplitListInnerRadius, kSplitListRowGap;
export 'components/lists/split_list_group.dart' show SplitListGroup;
export 'components/lists/split_list_row.dart' show SplitListRow;
export 'components/menu/anchored_menu.dart'
    show
        AnchoredMenu,
        kToolbarIconMenuAnchorWidth,
        menuAnchorRectFor,
        menuGlobalToRootOverlayLocal,
        pointerContextMenuAnchor,
        showAnchoredMenu,
        showPointerContextMenu;
export 'components/menu/anchored_option_picker.dart' show pickAnchoredOption;
export 'components/menu/context_menu.dart'
    show ContextMenuBuilder, ContextMenuCommon, ContextMenuContainer;
export 'components/menu/context_menu_action_item.dart'
    show ContextMenuActionItem;
export 'components/navigation/expressive_library_scroll_to_top_button.dart'
    show ExpressiveLibraryScrollToTopButton;
export 'components/navigation/library_scroll_to_top_button.dart'
    show
        LibraryScrollToTopButton,
        kLibraryScrollToTopBottomPadding,
        kLibraryScrollToTopFadeDuration,
        kLibraryScrollToTopHideViewportRatio,
        kLibraryScrollToTopScrollDuration,
        kLibraryScrollToTopShowViewportRatio;
export 'components/navigation/navigation_bar.dart' show ExpressiveNavigationBar;
export 'components/navigation/navigation_rail.dart'
    show
        ExpressiveNavigationRail,
        ExpressiveNavigationRailDestination,
        ExpressiveNavigationRailMetrics;
export 'components/overlays/overlay_route_scope.dart'
    show OverlayRouteScope, OverlayRouteScopeSnapshot;
export 'components/pagination/pagination.dart' show Pagination;
export 'components/pagination/pagination_compact.dart' show PaginationCompact;
export 'components/pagination/pagination_compact_summary.dart'
    show PaginationCompactSummary;
export 'components/pagination/pagination_ellipsis_slot.dart'
    show PaginationEllipsisSlot;
export 'components/pagination/pagination_empty_slot.dart'
    show PaginationEmptySlot;
export 'components/pagination/pagination_metrics.dart' show PaginationMetrics;
export 'components/pagination/pagination_page_button.dart'
    show PaginationPageButton;
export 'components/pagination/pagination_page_window.dart'
    show
        PaginationSiblingConfig,
        PaginationWindowEllipsis,
        PaginationWindowEmpty,
        PaginationWindowItem,
        PaginationWindowPage,
        buildPaginationPageWindow,
        padPaginationPageWindow,
        paginationFixedPageSlotCount,
        paginationRange;
export 'components/pagination/pagination_standard.dart' show PaginationStandard;
export 'components/pagination/pagination_standard_page_strip.dart'
    show PaginationStandardPageStrip;
export 'components/scaffold/detail_header_back_button.dart'
    show DetailHeaderBackButton;
export 'components/scaffold/detail_header_edit_button.dart'
    show DetailHeaderEditButton;
export 'components/scaffold/detail_header_icon_button.dart'
    show DetailHeaderIconButton;
export 'components/scaffold/detail_header_more_button.dart'
    show DetailHeaderMoreButton;
export 'components/scaffold/dialog_action_bar.dart' show DialogActionBar;
export 'components/scaffold/library_page_header_metrics.dart'
    show LibraryPageHeaderLayout, LibraryPageHeaderMetrics;
export 'components/scaffold/library_toolbar_row.dart' show LibraryToolbarRow;
export 'components/scaffold/metadata_edit_form_scroll.dart'
    show MetadataEditScrollBehavior;
export 'components/scaffold/metadata_edit_tabbed_shell.dart'
    show MetadataEditTab, MetadataEditTabbedShell;
export 'components/scaffold/metadata_field_label_row.dart'
    show MetadataFieldLabelRow;
export 'components/scaffold/page_header.dart'
    show PageHeaderDelegate, PageHeaderSliver;
export 'components/scaffold/page_header_back_button.dart'
    show PageHeaderBackButton;
export 'components/scaffold/page_header_chrome.dart' show PageHeaderChrome;
export 'components/scaffold/page_title.dart' show PageTitle;
export 'components/scaffold/pinned_toolbar_chrome.dart'
    show PinnedToolbarChrome;
export 'components/selection/segmented_capsule_bar.dart'
    show SegmentedCapsuleBar, SegmentedCapsuleSegment;
export 'components/selection/segmented_capsule_bar_metrics.dart'
    show SegmentedCapsuleBarMetrics;
export 'components/settings/content_section.dart' show ContentSection;
export 'components/settings/settings_category_tile.dart'
    show SettingsCategoryTile;
export 'components/settings/settings_list.dart' show SettingsList;
export 'components/settings/settings_rail_destination.dart'
    show SettingsRailDestination;
export 'components/settings/settings_section.dart' show SettingsSection;
export 'components/settings/settings_section_header.dart'
    show SettingsSectionHeader;
export 'components/settings/settings_switch_tile.dart' show SettingsSwitchTile;
export 'components/settings/settings_tile.dart' show SettingsNavigationTile;
export 'components/settings/settings_tile_label.dart'
    show SettingsTileLabel, settingsTileDisabledOn, settingsTileSecondaryColor;
export 'components/settings/settings_tile_shell.dart' show SettingsTileShell;
export 'components/shell/desktop_shell_metrics.dart' show DesktopShellMetrics;
export 'components/shell/desktop_shell_pane.dart' show DesktopShellPane;
export 'components/shell/shell_content_layout.dart' show ShellContentLayout;
export 'components/shell/shell_library_secondary_layout.dart'
    show ShellNavigationCursor;
export 'components/shell/shell_nav_divider.dart' show ShellNavVerticalDivider;
export 'components/shell/shell_nav_item.dart' show ShellNavItem;
export 'components/surfaces/tonal_surface.dart'
    show TonalSurface, kTonalSurfaceRadius;
export 'components/window/desktop_title_bar.dart' show DesktopTitleBar;
export 'components/window/desktop_title_bar_metrics.dart'
    show DesktopTitleBarMetrics;
export 'components/window/desktop_window_actions.dart'
    show DesktopWindowActions;
export 'components/window/desktop_window_controls.dart'
    show DesktopWindowControls, closeWindowButtonDecoration;
export 'filtering/name_pinyin_assisted_filter.dart'
    show
        NamePinyinIndex,
        NamePinyinIndexEntry,
        buildNamePinyinIndex,
        buildNamePinyinIndexEntries,
        buildNamePinyinIndexEntry,
        kNamePinyinIndexIsolateThreshold,
        nameMatchesPinyinAssistedFilter,
        namePinyinIndexEntryMatches,
        normalizeLatinPinyinQuery;
export 'interaction/expressive_pointer_target.dart'
    show PointerTarget, kMinInteractiveSize;
export 'interaction/horizontal_wheel_scroll_listener.dart'
    show HorizontalWheelScrollListener;
export 'interaction/pointer_target.dart'
    show
        iconTooltipWait,
        isCompactLayoutWidth,
        kCompactMinInteractiveSize,
        kIconTooltipWait,
        minInteractiveSize,
        unfocusAfterPointerActivation;
export 'l10n/design_system_localizations.dart' show DesignSystemLocalizations;
export 'l10n/m3e_material_localizations.dart'
    show
        MaterialUiLocalizationsScope,
        materialLocalizationsDelegates,
        materialLocalizationsOf;
export 'layout/app_layout_breakpoints.dart' show AppLayoutBreakpoints;
export 'layout/breakpoints.dart'
    show Breakpoints, WindowSizeClass, windowSizeClassOf;
export 'layout/catalog_grid.dart'
    show CatalogGridCell, CatalogGridItemBuilder, catalogGridDelegate;
export 'layout/catalog_grid_box.dart' show CatalogGridBox;
export 'layout/catalog_grid_metrics.dart'
    show CatalogGridLayout, CatalogGridMetrics;
export 'layout/catalog_grid_sliver.dart' show CatalogGridSliver;
export 'layout/catalog_list_layout.dart'
    show CatalogListSliver, comicListColumnCount;
export 'layout/comic_detail_page_metrics.dart' show ComicDetailPageMetrics;
export 'layout/comic_detail_primary_row_layout.dart'
    show ComicDetailPrimaryRowLayout;
export 'layout/comic_detail_title.dart' show ComicDetailTitle;
export 'layout/detail_meta_chip_band_layout.dart'
    show
        DetailMetaChipBandLayout,
        countDetailMetaChipBandRows,
        detailMetaChipBandHeight,
        kDetailMetaChipBandMaxRowsCharacter,
        kDetailMetaChipBandMaxRowsSingle,
        kDetailMetaChipBandMaxRowsTag,
        layoutDetailMetaChipBand;
export 'layout/detail_meta_chip_row_layout.dart'
    show kDetailMetaChipRowHeight, kSeriesDetailMetaChipRowHeight;
export 'layout/fab_sizing.dart' show FabSizing;
export 'layout/library_browse_page_metrics.dart' show LibraryBrowsePageMetrics;
export 'layout/library_filter_sort_metrics.dart'
    show
        LibraryFilterSortLayoutTier,
        LibraryFilterSortRowMetrics,
        kLibraryFilterSortDrawerContentInset,
        kLibraryFilterSortDrawerScrimColor,
        libraryFilterSortDrawerWidth,
        libraryFilterSortDrawerWidthForViewport,
        libraryFilterSortLayoutTierForWidth,
        libraryFilterSortPrefersBottomSheetForViewport,
        libraryFilterSortSideSheetDetachedForViewport,
        libraryFilterSortSideSheetTheme,
        libraryFilterSortSideSheetWidthForViewport;
export 'layout/list_detail_adaptive_layout.dart'
    show ListDetailAdaptiveLayout, kListDetailExpandedBreakpoint;
export 'layout/metadata_edit_form_metrics.dart' show MetadataEditFormMetrics;
export 'layout/page_layout_scope.dart' show PageLayoutScope;
export 'layout/page_layout_spec.dart'
    show LayoutContext, LayoutInputMode, PageLayoutSpec, kPageContentMaxWidth;
export 'layout/page_viewport.dart' show PageViewport;
export 'layout/pinned_toolbar_chrome_metrics.dart'
    show PinnedToolbarChromeMetrics;
export 'layout/settings_page_metrics.dart' show SettingsPageMetrics;
export 'layout/spacing.dart' show Spacing;
export 'motion/app_motion.dart'
    show
        motionDuration,
        motionDurationOf,
        readerAutoPlayAllowed,
        reduceMotionOf;
export 'motion/catalog_detail_transition.dart'
    show CatalogDetailTransition, kCatalogDetailPageTransitionDuration;
export 'motion/desktop_page_transition.dart'
    show
        DesktopFadeThroughPageTransitionsBuilder,
        DesktopFadeThroughTransitionWrapper,
        desktopFadeThroughEnterOpacity,
        desktopFadeThroughExitOpacity,
        kDesktopPageTransitionDuration,
        kFadeThroughIncomingStart,
        kFadeThroughOutgoingEnd;
export 'motion/effects_decorated_box.dart' show EffectsDecoratedBox;
export 'motion/mode_chrome_transition.dart' show ModeChromeTransition;
export 'motion/motion.dart' show LabMotion;
export 'motion/peer_content_transition.dart' show PeerContentTransition;
export 'motion/shared_axis_route.dart'
    show SharedAxisTransitionWrapper, kSharedAxisRouteDuration, sharedAxisRoute;
export 'motion/spring_curve.dart' show SpringCurve;
export 'motion/spring_positioned.dart' show SpringPositioned;
export 'motion/spring_reveal.dart' show SpringReveal;
export 'motion/spring_size.dart' show SpringSize;
export 'motion/spring_value.dart' show SpringValue;
export 'platform/platform_desktop.dart'
    show isDesktop, supportsDesktopWindowChrome;
export 'theme/app_font.dart'
    show
        AppFontSpec,
        appFontFamilyOf,
        appFontSpecForId,
        kAppFontFamily,
        kAppFontFamilyMiSans,
        kAppFontFamilyNotoCjkFallbacks,
        kAppFontFamilyNotoSans,
        kAppFontFamilyNotoSansJp,
        kAppFontFamilyNotoSansSc;
export 'theme/app_m3e_theme.dart'
    show
        applyShellNavRailOverrides,
        buildAppM3eThemeData,
        buildMaterialTheme,
        flutterColorSchemeFromM3e,
        kBrandSeedColor,
        m3eColorSchemeForBrightness,
        withAppFontFamily;
export 'theme/color/app_color_scheme_seeds.dart'
    show colorSchemeSeedForId, kKnownColorSchemeIds;
export 'theme/color/app_shadow_palette.dart' show AppShadowPalette;
export 'theme/color/desktop_shell_surfaces.dart'
    show DesktopShellSurfaceRoles, labBrowseCanvasColor;
export 'theme/color/reader_color_scheme.dart' show ReaderColorScheme;
export 'theme/extensions/theme_context_extensions.dart'
    show ThemeDesignX, ThemeTokensX;
export 'theme/lab_text.dart' show LabText, labButtonLabelStyle, labTextStyle;
export 'theme/theme.dart'
    show
        AssembledAppTheme,
        appSystemUiOverlayStyle,
        assembleAppTheme,
        buildAppTheme,
        materialThemeFromM3e,
        resolveAppThemeSeed;
export 'theme/tokens/app_layout_tokens.dart' show AppLayoutTokens;
export 'theme/tokens/app_motion_tokens.dart' show AppMotionTokens;
export 'theme/tokens/app_radius_tokens.dart' show AppRadiusTokens;
export 'theme/tokens/app_shadow_tokens.dart' show AppShadowTokens;
export 'theme/tokens/app_spacing_tokens.dart' show AppSpacingTokens;
export 'theme/tokens/app_text_tokens.dart' show AppTextTokens;
export 'theme/tokens/app_theme_tokens.dart' show AppThemeTokens;
export 'util/navigation_rail_icon.dart'
    show NavigationRailIcon, iconSupportsFillVariation;
export 'util/reorder_index.dart' show applyReorder;
export 'components/scaffold/metadata_edit_cancel_button.dart'
    show MetadataEditCancelButton;
export 'components/scaffold/metadata_edit_save_button.dart'
    show MetadataEditSaveButton;
export 'components/scaffold/metadata_edit_surface.dart'
    show MetadataEditSurface, MetadataEditPresentation;
