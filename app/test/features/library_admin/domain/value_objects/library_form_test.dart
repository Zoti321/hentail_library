import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/scan_interval.dart';
import 'package:test/test.dart';

void main() {
  group('LibraryForm.validate', () {
    test('requires name and root', () {
      final LibraryFormValidation v = LibraryForm.createLocal().validate(
        isCreate: true,
      );
      expect(v.isValid, isFalse);
      expect(v.nameError, isNotNull);
      expect(v.rootError, isNotNull);
    });

    test('create remote requires password', () {
      final LibraryFormValidation v = LibraryForm.createRemote()
          .copyWith(name: 'R', rootPath: 'https://dav.example/c')
          .validate(isCreate: true);
      expect(v.passwordError, isNotNull);
    });

    test('edit remote allows empty password', () {
      final LibraryFormValidation v = LibraryForm.createRemote()
          .copyWith(name: 'R', rootPath: 'https://dav.example/c')
          .validate(isCreate: false);
      expect(v.isValid, isTrue);
    });
  });

  group('LibraryForm image set', () {
    test('createImageSetLocal has no format groups and scan disabled', () {
      final LibraryForm form = LibraryForm.createImageSetLocal().copyWith(
        name: 'G',
        rootPath: r'D:\images',
        scanOnStartup: true,
        scanInterval: ScanInterval.daily,
        enabledResourceFormatCategories: ResourceFormatCategory.all,
      );
      final LibraryForm ready = form.normalized;
      expect(ready.isImageSet, isTrue);
      expect(ready.isRemote, isFalse);
      expect(ready.enabledResourceFormatCategories, isEmpty);
      expect(ready.scanOnStartup, isFalse);
      expect(ready.scanInterval, ScanInterval.disabled);
    });

    test('fromLibrary keeps image set kind and clears format groups', () {
      final LocalLibrary library = (
        libraryId: 'img',
        kind: 'local',
        catalogKind: 'image_set',
        rootPath: r'D:\images',
        name: 'G',
        enabledResourceFormatCategories: const <ResourceFormatCategory>[],
        username: '',
        allowHttp: false,
        scanOnStartup: false,
        scanInterval: ScanInterval.disabled,
        pinned: false,
        sidebarOrder: 0,
      );
      final LibraryForm form = LibraryForm.fromLibrary(library);
      expect(form.isImageSet, isTrue);
      expect(form.enabledResourceFormatCategories, isEmpty);
    });

    test('image set create requires root', () {
      final LibraryFormValidation v = LibraryForm.createImageSetLocal()
          .copyWith(name: 'G')
          .validate(isCreate: true);
      expect(v.rootError, isNotNull);
    });
  });
}
