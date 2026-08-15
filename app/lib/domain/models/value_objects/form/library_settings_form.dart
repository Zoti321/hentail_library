import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';

part 'library_settings_form.freezed.dart';

/// Library 用户可配置项编辑草稿（显示名、Scan on startup、Scan interval、格式分组）。
@freezed
abstract class LibrarySettingsForm with _$LibrarySettingsForm {
  factory LibrarySettingsForm({
    required String name,
    required List<FormatGroup> enabledFormatGroups,
    required bool scanOnStartup,
    required ScanInterval scanInterval,
  }) = _LibrarySettingsForm;

  factory LibrarySettingsForm.fromLibrary(LocalLibrary library) {
    return LibrarySettingsForm(
      name: library.name,
      enabledFormatGroups: List<FormatGroup>.from(library.enabledFormatGroups),
      scanOnStartup: library.scanOnStartup,
      scanInterval: library.scanInterval,
    );
  }
}

/// 字段级校验结果；[isValid] 为 true 时方可落库。
@freezed
abstract class LibrarySettingsFormValidation
    with _$LibrarySettingsFormValidation {
  const factory LibrarySettingsFormValidation({String? nameError}) =
      _LibrarySettingsFormValidation;

  const LibrarySettingsFormValidation._();

  bool get isValid => nameError == null;
}

/// [LibrarySettingsForm.applyTo] 的结果：非法不调仓储；成功已落库。
/// 仓储异常仍向上抛，由 UI toast。
sealed class LibrarySettingsApplyResult {
  const LibrarySettingsApplyResult();
}

final class LibrarySettingsApplyInvalid extends LibrarySettingsApplyResult {
  const LibrarySettingsApplyInvalid(this.validation);

  final LibrarySettingsFormValidation validation;
}

final class LibrarySettingsApplySucceeded extends LibrarySettingsApplyResult {
  const LibrarySettingsApplySucceeded();
}

extension LibrarySettingsFormOps on LibrarySettingsForm {
  /// 一次算出字段错误（目前仅名称）。
  LibrarySettingsFormValidation validate() {
    return LibrarySettingsFormValidation(
      nameError: name.trim().isEmpty ? '库名称不能为空' : null,
    );
  }

  /// trim 名称；格式分组按 [FormatGroup.all] 顺序去重。
  LibrarySettingsForm get normalized {
    final Set<FormatGroup> unique = enabledFormatGroups.toSet();
    return copyWith(
      name: name.trim(),
      enabledFormatGroups: FormatGroup.all
          .where(unique.contains)
          .toList(growable: false),
    );
  }

  /// 非法 → [LibrarySettingsApplyInvalid]；相对 [original] 无变化则不调仓储。
  Future<LibrarySettingsApplyResult> applyTo(
    LibraryRepository repository,
    LocalLibrary original,
  ) async {
    final LibrarySettingsForm ready = normalized;
    final LibrarySettingsFormValidation validation = ready.validate();
    if (!validation.isValid) {
      return LibrarySettingsApplyInvalid(validation);
    }

    final bool sameGroups = _sameOrderedGroups(
      ready.enabledFormatGroups,
      original.enabledFormatGroups,
    );
    final bool hasChanges =
        ready.name != original.name.trim() ||
        !sameGroups ||
        ready.scanOnStartup != original.scanOnStartup ||
        ready.scanInterval != original.scanInterval;
    if (!hasChanges) {
      return const LibrarySettingsApplySucceeded();
    }

    await repository.updateSettings(
      libraryId: original.libraryId,
      name: ready.name,
      groups: ready.enabledFormatGroups,
      scanOnStartup: ready.scanOnStartup,
      scanInterval: ready.scanInterval,
    );
    return const LibrarySettingsApplySucceeded();
  }
}

bool _sameOrderedGroups(List<FormatGroup> a, List<FormatGroup> b) {
  if (a.length != b.length) {
    return false;
  }
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
