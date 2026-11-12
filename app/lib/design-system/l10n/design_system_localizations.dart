import 'package:flutter/widgets.dart';

/// Component vocabulary follows the ambient locale without application ARBs.
class DesignSystemLocalizations {
  const DesignSystemLocalizations(this.locale);

  final Locale locale;

  static DesignSystemLocalizations of(BuildContext context) =>
      DesignSystemLocalizations(Localizations.localeOf(context));

  bool get _zh => locale.languageCode == 'zh';

  String get clearLabel => _zh ? '清空' : 'Clear';

  String get clearDateTooltip => _zh ? '清空日期' : 'Clear date';

  String get datePickerHint => _zh ? '选择发布日期' : 'Select published date';

  String get backLabel => _zh ? '返回' : 'Back';

  String get cancelLabel => _zh ? '取消' : 'Cancel';

  String pageSemantic(int page) => _zh ? '第 $page 页' : 'Page $page';

  String get scrollToTopLabel => _zh ? '回到顶部' : 'Back to top';

  String get expandNavigationTooltip => _zh ? '展开导航' : 'Expand navigation';

  String get collapseNavigationTooltip => _zh ? '收起导航' : 'Collapse navigation';
  String get moreActions => _zh ? '更多操作' : 'More actions';
  String get saveLabel => _zh ? '保存' : 'Save';
}
