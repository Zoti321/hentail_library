import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/scan_interval.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';

part 'library_form.freezed.dart';

/// Library 创建/编辑草稿（name、root、Remote 凭证、扫描设置）。
@freezed
abstract class LibraryForm with _$LibraryForm {
  factory LibraryForm({
    required bool isRemote,
    required String name,
    required String rootPath,
    @Default('') String username,
    @Default('') String password,
    @Default(false) bool allowHttp,
    required List<ResourceFormatCategory> enabledResourceFormatCategories,
    required bool scanOnStartup,
    required ScanInterval scanInterval,
  }) = _LibraryForm;

  factory LibraryForm.createLocal() {
    return LibraryForm(
      isRemote: false,
      name: '',
      rootPath: '',
      enabledResourceFormatCategories: List<ResourceFormatCategory>.of(
        ResourceFormatCategory.all,
      ),
      scanOnStartup: false,
      scanInterval: ScanInterval.disabled,
    );
  }

  factory LibraryForm.createRemote() {
    return LibraryForm(
      isRemote: true,
      name: '',
      rootPath: '',
      enabledResourceFormatCategories: ResourceFormatCategory.all
          .where(
            (ResourceFormatCategory g) => g != ResourceFormatCategory.folder,
          )
          .toList(growable: false),
      scanOnStartup: false,
      scanInterval: ScanInterval.disabled,
    );
  }

  factory LibraryForm.fromLibrary(LocalLibrary library) {
    final bool remote = isRemoteLibrary(library);
    List<ResourceFormatCategory> groups = List<ResourceFormatCategory>.of(
      library.enabledResourceFormatCategories,
    );
    if (remote) {
      groups = groups
          .where(
            (ResourceFormatCategory g) => g != ResourceFormatCategory.folder,
          )
          .toList(growable: false);
    }
    return LibraryForm(
      isRemote: remote,
      name: library.name,
      rootPath: library.rootPath,
      username: library.username,
      password: '',
      allowHttp: library.allowHttp,
      enabledResourceFormatCategories: groups,
      scanOnStartup: library.scanOnStartup,
      scanInterval: library.scanInterval,
    );
  }
}

@freezed
abstract class LibraryFormValidation with _$LibraryFormValidation {
  const factory LibraryFormValidation({
    String? nameError,
    String? rootError,
    String? passwordError,
  }) = _LibraryFormValidation;

  const LibraryFormValidation._();

  bool get isValid =>
      nameError == null && rootError == null && passwordError == null;
}

sealed class LibraryFormApplyResult {
  const LibraryFormApplyResult();
}

final class LibraryFormApplyInvalid extends LibraryFormApplyResult {
  const LibraryFormApplyInvalid(this.validation);

  final LibraryFormValidation validation;
}

final class LibraryFormApplySucceeded extends LibraryFormApplyResult {
  const LibraryFormApplySucceeded({this.rootChanged = false});

  final bool rootChanged;
}

extension LibraryFormOps on LibraryForm {
  LibraryFormValidation validate({required bool isCreate}) {
    final String? nameError = name.trim().isEmpty ? '库名称不能为空' : null;
    final String? rootError = rootPath.trim().isEmpty
        ? (isRemote ? 'WebDAV 根 URL 不能为空' : 'Library root 不能为空')
        : null;
    String? passwordError;
    if (isRemote && isCreate && password.isEmpty) {
      passwordError = '密码不能为空';
    }
    if (isRemote &&
        rootError == null &&
        rootPath.trim().toLowerCase().startsWith('http://') &&
        !allowHttp) {
      return LibraryFormValidation(
        nameError: nameError,
        rootError: '使用 HTTP 时需允许明文连接',
        passwordError: passwordError,
      );
    }
    return LibraryFormValidation(
      nameError: nameError,
      rootError: rootError,
      passwordError: passwordError,
    );
  }

  LibraryForm get normalized {
    final Set<ResourceFormatCategory> unique = enabledResourceFormatCategories
        .toSet();
    if (isRemote) {
      unique.remove(ResourceFormatCategory.folder);
    }
    return copyWith(
      name: name.trim(),
      rootPath: rootPath.trim(),
      username: username.trim(),
      enabledResourceFormatCategories: ResourceFormatCategory.all
          .where(unique.contains)
          .toList(growable: false),
    );
  }

  bool settingsDifferFrom(LocalLibrary original) =>
      _settingsDiffer(normalized, original);
}

bool _settingsDiffer(LibraryForm ready, LocalLibrary original) {
  return ready.name != original.name.trim() ||
      ready.scanOnStartup != original.scanOnStartup ||
      ready.scanInterval != original.scanInterval ||
      !_sameOrderedGroups(
        ready.enabledResourceFormatCategories,
        original.enabledResourceFormatCategories,
      );
}

bool _sameOrderedGroups(
  List<ResourceFormatCategory> a,
  List<ResourceFormatCategory> b,
) {
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
