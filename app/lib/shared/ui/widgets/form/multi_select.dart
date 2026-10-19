import 'dart:math' as math;

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/util/name_pinyin_assisted_filter.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/element/chip/outlined_meta_chip.dart';
import 'package:hentai_library/shared/ui/widgets/form/fluent_text_field.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod/misc.dart' show ProviderListenable;

part 'multi_select_state.dart';
part 'multi_select_menu.dart';

const double _kMultiSelectMenuMaxHeight = 240;

/// 漫画元数据「全库关联」多选：作者 / 标签等场景复用；差异在 [MultiSelectCopy] 与数据源。
class MultiSelectCopy {
  const MultiSelectCopy({
    required this.inputPlaceholder,
    required this.listLoadFailed,
    required this.emptyCatalog,
    required this.emptyRemaining,
  });

  final String inputPlaceholder;
  final String listLoadFailed;
  final String emptyCatalog;
  final String emptyRemaining;
}

class _MultiSelectDropdownListStyles {
  const _MultiSelectDropdownListStyles._();

  static const EdgeInsets rowPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  );
}

/// 图书馆实体多选：字段内 chip + 内联输入；浮层列出未选字典项。
///
/// Uses [ConsumerStatefulWidget] for [CustomPopupMenuController] + input/filter
/// notifiers that must outlive overlay rebuilds (hooks impractical here).
class MultiSelect<T> extends ConsumerStatefulWidget {
  const MultiSelect({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedNames,
    required this.onAdd,
    required this.onRemove,
    required this.itemsProvider,
    required this.onRetry,
    required this.resolveName,
    required this.copy,
    this.labelTrailing,
    this.compactTrigger = false,
    this.resolveSmartMatched,
    this.smartMatchedTooltip,
  });

  static const Key fieldSurfaceKey = Key('multi_select_field_surface');
  static const Key menuPanelKey = Key('multi_select_menu_panel');
  static const Key smartMatchedHintKey = Key('multi_select_smart_matched_hint');

  final String label;
  final Widget? labelTrailing;
  final IconData icon;
  final List<String> selectedNames;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final ProviderListenable<AsyncValue<List<T>>> itemsProvider;
  final VoidCallback onRetry;
  final String Function(T item) resolveName;
  final MultiSelectCopy copy;
  final bool compactTrigger;

  /// When true for a dropdown row, show Smart facet match hint icon.
  final bool Function(T item)? resolveSmartMatched;
  final String? smartMatchedTooltip;

  @override
  ConsumerState<MultiSelect<T>> createState() => _MultiSelectState<T>();
}
