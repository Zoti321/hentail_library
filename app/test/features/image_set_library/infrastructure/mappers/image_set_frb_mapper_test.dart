import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
import 'package:hentai_library/features/image_set_library/infrastructure/mappers/image_set_frb_mapper.dart';
import 'package:hentai_library/src/rust/api/image_set.dart' as rust;
import 'package:test/test.dart';

void main() {
  test('imageSetLibraryGatesFromFrb maps both flags', () {
    const rust.ImageSetLibraryGatesDto dto = rust.ImageSetLibraryGatesDto(
      resourceMutation: true,
      managedLayout: false,
    );
    final ImageSetLibraryGates gates = imageSetLibraryGatesFromFrb(dto);
    expect(gates.resourceMutation, isTrue);
    expect(gates.managedLayout, isFalse);
  });

  test('imageSetSubmissionFromFrb copies ordered member ids', () {
    const rust.ImageSetSubmissionDto dto = rust.ImageSetSubmissionDto(
      submissionId: 's1',
      libraryId: 'lib',
      imageSetId: 'set',
      name: 'Favs',
      memberImageIds: <String>['a', 'b'],
    );
    final ImageSetSubmission sub = imageSetSubmissionFromFrb(dto);
    expect(sub.submissionId, 's1');
    expect(sub.name, 'Favs');
    expect(sub.memberImageIds, <String>['a', 'b']);
    sub.memberImageIds.add('c');
    expect(dto.memberImageIds, <String>['a', 'b']);
  });

  test('imageSetImage round-trip keeps carrier fields', () {
    const rust.ImageSetImageDto dto = rust.ImageSetImageDto(
      imageSetImageId: 'img',
      imageSetId: 'set',
      libraryId: 'lib',
      carrierRelativePath: 'album/0001.jpg',
      memberPath: '',
      carrierKind: 'loose',
      name: '0001.jpg',
    );
    final ImageSetImage image = imageSetImageFromFrb(dto);
    final rust.ImageSetImageDto back = imageSetImageToFrb(image);
    expect(back.imageSetImageId, dto.imageSetImageId);
    expect(back.carrierRelativePath, dto.carrierRelativePath);
    expect(back.carrierKind, dto.carrierKind);
    expect(back.name, dto.name);
  });
}
