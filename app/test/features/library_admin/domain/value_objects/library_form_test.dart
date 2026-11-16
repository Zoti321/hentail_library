import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';
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
}
