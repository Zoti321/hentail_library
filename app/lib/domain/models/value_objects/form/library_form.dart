import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';

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
    required List<FormatGroup> enabledFormatGroups,
    required bool scanOnStartup,
    required ScanInterval scanInterval,
  }) = _LibraryForm;

  factory LibraryForm.createLocal() {
    return LibraryForm(
      isRemote: false,
      name: '',
      rootPath: '',
      enabledFormatGroups: List<FormatGroup>.from(FormatGroup.all),
      scanOnStartup: false,
      scanInterval: ScanInterval.disabled,
    );
  }

  factory LibraryForm.createRemote() {
    return LibraryForm(
      isRemote: true,
      name: '',
      rootPath: '',
      enabledFormatGroups: FormatGroup.all
          .where((FormatGroup g) => g != FormatGroup.folder)
          .toList(growable: false),
      scanOnStartup: false,
      scanInterval: ScanInterval.disabled,
    );
  }

  factory LibraryForm.fromLibrary(LocalLibrary library) {
    final bool remote = isRemoteLibrary(library);
    List<FormatGroup> groups = List<FormatGroup>.from(
      library.enabledFormatGroups,
    );
    if (remote) {
      groups = groups
          .where((FormatGroup g) => g != FormatGroup.folder)
          .toList(growable: false);
    }
    return LibraryForm(
      isRemote: remote,
      name: library.name,
      rootPath: library.rootPath,
      username: library.username,
      password: '',
      allowHttp: library.allowHttp,
      enabledFormatGroups: groups,
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
    final Set<FormatGroup> unique = enabledFormatGroups.toSet();
    if (isRemote) {
      unique.remove(FormatGroup.folder);
    }
    return copyWith(
      name: name.trim(),
      rootPath: rootPath.trim(),
      username: username.trim(),
      enabledFormatGroups: FormatGroup.all
          .where(unique.contains)
          .toList(growable: false),
    );
  }

  /// Create a new Library then apply scan/settings when they differ from defaults.
  Future<LibraryFormApplyResult> create(LibraryRepository repository) async {
    final LibraryForm ready = normalized;
    final LibraryFormValidation validation = ready.validate(isCreate: true);
    if (!validation.isValid) {
      return LibraryFormApplyInvalid(validation);
    }

    final LocalLibrary created;
    if (ready.isRemote) {
      created = await repository.createRemote(
        rootUrl: ready.rootPath,
        username: ready.username,
        password: ready.password,
        allowHttp: ready.allowHttp,
        name: ready.name,
      );
    } else {
      created = await repository.createLocal(ready.rootPath, name: ready.name);
    }

    await _writeSettingsIfNeeded(repository, created, ready);
    return const LibraryFormApplySucceeded();
  }

  /// Edit existing Library. Empty remote password keeps the stored credential.
  Future<LibraryFormApplyResult> applyTo(
    LibraryRepository repository,
    LocalLibrary original,
  ) async {
    final LibraryForm ready = normalized;
    final LibraryFormValidation validation = ready.validate(isCreate: false);
    if (!validation.isValid) {
      return LibraryFormApplyInvalid(validation);
    }

    final bool rootChanged = ready.rootPath != original.rootPath.trim();
    final bool settingsChanged = _settingsDiffer(ready, original);
    final bool remoteConnectionChanged =
        ready.isRemote &&
        (ready.rootPath != original.rootPath.trim() ||
            ready.username != original.username.trim() ||
            ready.allowHttp != original.allowHttp ||
            ready.password.isNotEmpty);

    if (!rootChanged && !settingsChanged && !remoteConnectionChanged) {
      return const LibraryFormApplySucceeded();
    }

    if (ready.isRemote) {
      if (remoteConnectionChanged) {
        await repository.updateRemote(
          libraryId: original.libraryId,
          rootUrl: ready.rootPath,
          username: ready.username,
          allowHttp: ready.allowHttp,
          password: ready.password.isEmpty ? null : ready.password,
        );
      }
    } else if (rootChanged) {
      await repository.updateLocalRoot(
        libraryId: original.libraryId,
        rootPath: ready.rootPath,
      );
    }

    if (settingsChanged || ready.name != original.name.trim()) {
      await repository.updateSettings(
        libraryId: original.libraryId,
        name: ready.name,
        groups: ready.enabledFormatGroups,
        scanOnStartup: ready.scanOnStartup,
        scanInterval: ready.scanInterval,
      );
    }

    return LibraryFormApplySucceeded(rootChanged: rootChanged);
  }
}

bool _settingsDiffer(LibraryForm ready, LocalLibrary original) {
  return ready.name != original.name.trim() ||
      ready.scanOnStartup != original.scanOnStartup ||
      ready.scanInterval != original.scanInterval ||
      !_sameOrderedGroups(ready.enabledFormatGroups, original.enabledFormatGroups);
}

Future<void> _writeSettingsIfNeeded(
  LibraryRepository repository,
  LocalLibrary created,
  LibraryForm ready,
) async {
  if (!_settingsDiffer(ready, created)) {
    return;
  }
  await repository.updateSettings(
    libraryId: created.libraryId,
    name: ready.name,
    groups: ready.enabledFormatGroups,
    scanOnStartup: ready.scanOnStartup,
    scanInterval: ready.scanInterval,
  );
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
