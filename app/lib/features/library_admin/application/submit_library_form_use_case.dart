import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';

/// 按已有连接、根与设置顺序提交表单，成功后发布目录事实。
///
/// 多次仓储写入不构成一个事务；中途失败不发布整体成功或自动重试。
class SubmitLibraryFormUseCase {
  const SubmitLibraryFormUseCase(this.repository, this.events);
  final DomainEventPublisher events;
  final LibraryRepository repository;

  Future<LibraryFormApplyResult> call(
    LibraryForm form, {
    LocalLibrary? original,
  }) async {
    final result = original == null
        ? await _create(form)
        : await _applyTo(form, original);
    if (result is LibraryFormApplySucceeded) {
      events.publish(
        const LibraryCatalogChanged(CatalogChangeSource.libraryAdmin),
      );
    }
    return result;
  }

  /// Create a new Library then apply scan/settings when they differ from defaults.
  Future<LibraryFormApplyResult> _create(LibraryForm form) async {
    final LibraryForm ready = form.normalized;
    final LibraryFormValidation validation = ready.validate(isCreate: true);
    if (!validation.isValid) {
      return LibraryFormApplyInvalid(validation);
    }

    final LocalLibrary created;
    created = ready.isRemote
        ? await repository.createRemote(
            rootUrl: ready.rootPath,
            username: ready.username,
            password: ready.password,
            allowHttp: ready.allowHttp,
            name: ready.name,
          )
        : await repository.createLocal(ready.rootPath, name: ready.name);

    await _writeSettingsIfNeeded(created, ready);
    return const LibraryFormApplySucceeded();
  }

  /// Edit existing Library. Empty remote password keeps the stored credential.
  Future<LibraryFormApplyResult> _applyTo(
    LibraryForm form,
    LocalLibrary original,
  ) async {
    final LibraryForm ready = form.normalized;
    final LibraryFormValidation validation = ready.validate(isCreate: false);
    if (!validation.isValid) {
      return LibraryFormApplyInvalid(validation);
    }

    final bool rootChanged = ready.rootPath != original.rootPath.trim();
    final bool settingsChanged = ready.settingsDifferFrom(original);
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
        groups: ready.enabledResourceFormatCategories,
        scanOnStartup: ready.scanOnStartup,
        scanInterval: ready.scanInterval,
      );
    }

    return LibraryFormApplySucceeded(rootChanged: rootChanged);
  }

  Future<void> _writeSettingsIfNeeded(
    LocalLibrary created,
    LibraryForm ready,
  ) async {
    if (!ready.settingsDifferFrom(created)) {
      return;
    }
    await repository.updateSettings(
      libraryId: created.libraryId,
      name: ready.name,
      groups: ready.enabledResourceFormatCategories,
      scanOnStartup: ready.scanOnStartup,
      scanInterval: ready.scanInterval,
    );
  }
}
