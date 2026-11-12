import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

/// [LibraryDisplayTarget] 展示文案（枚举所有权在 shared，ADR-0046 §6）。
///
/// `library_browse` 与 `app_settings` 共用本扩展，保证设置页选项与库页 Tab
/// 文案完全一致（ARB 源仍在 `core/l10n`）。
extension LibraryDisplayTargetL10n on AppLocalizations {
  String libraryDisplayTargetTabLabel(LibraryDisplayTarget target) {
    return switch (target) {
      LibraryDisplayTarget.comics => libraryTabComics,
      LibraryDisplayTarget.series => libraryTabSeries,
    };
  }
}
