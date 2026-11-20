import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_submission_editor_page.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/pump_localized_app.dart';

const ImageSetImage _image1 = ImageSetImage(
  imageSetImageId: 'i1',
  imageSetId: 'a',
  libraryId: 'img-1',
  carrierRelativePath: 'alpha/1.jpg',
  memberPath: '',
  carrierKind: 'loose',
  name: '1.jpg',
);

const ImageSetImage _image2Excluded = ImageSetImage(
  imageSetImageId: 'i2',
  imageSetId: 'a',
  libraryId: 'img-1',
  carrierRelativePath: 'alpha/2.jpg',
  memberPath: '',
  carrierKind: 'loose',
  name: '2.jpg',
  excluded: true,
);

const ImageSetSubmission _submission = ImageSetSubmission(
  submissionId: 'sub-1',
  libraryId: 'img-1',
  imageSetId: 'a',
  name: 'Draft A',
  memberImageIds: <String>['i1'],
);

final Uint8List _png1x1 = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
  0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _Probe {
  final List<List<String>> addMemberCalls = <List<String>>[];
  final List<List<String>> removeMemberCalls = <List<String>>[];
  final List<List<String>> reorderCalls = <List<String>>[];
  List<ImageSetSubmission> submissions = <ImageSetSubmission>[_submission];
}

List<Override> _overrides(_Probe probe) => <Override>[
  libraryRevisionStateProvider.overrideWithValue(const LibraryRevisionState()),
  imageSetSubmissionsQueryProvider.overrideWithValue(
    (String libraryId, String imageSetId) async => probe.submissions,
  ),
  imageSetWorkspaceImagesQueryProvider.overrideWithValue(
    (String libraryId, String imageSetId) async =>
        <ImageSetImage>[_image1, _image2Excluded],
  ),
  imageSetPageBytesQueryProvider.overrideWithValue(
    (String libraryId, ImageSetImage image) async => _png1x1,
  ),
  imageSetRenameSubmissionCommandProvider.overrideWithValue(
    (_, __, ___) async {},
  ),
  imageSetDeleteSubmissionCommandProvider.overrideWithValue((_, __) async {}),
  imageSetAddSubmissionMembersCommandProvider.overrideWithValue(
    (_, __, List<String> ids) async {
      probe.addMemberCalls.add(List<String>.from(ids));
    },
  ),
  imageSetRemoveSubmissionMembersCommandProvider.overrideWithValue(
    (_, __, List<String> ids) async {
      probe.removeMemberCalls.add(List<String>.from(ids));
    },
  ),
  imageSetReorderSubmissionMembersCommandProvider.overrideWithValue(
    (_, __, List<String> ids) async {
      probe.reorderCalls.add(List<String>.from(ids));
    },
  ),
];

Future<void> _pumpEditor(WidgetTester tester, _Probe probe) =>
    pumpLocalizedApp(
      tester,
      overrides: _overrides(probe),
      home: const ImageSetSubmissionEditorPage(
        libraryId: 'img-1',
        imageSetId: 'a',
        submission: _submission,
      ),
    );

void main() {
  testWidgets('add members invokes command with picked ids', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    await _pumpEditor(tester, probe);
    await tester.pumpAndSettle();

    await tester.tap(find.text('添加成员'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2.jpg'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(probe.addMemberCalls, hasLength(1));
    expect(probe.addMemberCalls.single, <String>['i2']);
  });

  testWidgets('remove member invokes command', (WidgetTester tester) async {
    final _Probe probe = _Probe();
    await _pumpEditor(tester, probe);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('移出投稿'));
    await tester.pump();

    expect(probe.removeMemberCalls, hasLength(1));
    expect(probe.removeMemberCalls.single, <String>['i1']);
  });

  testWidgets('reorder members invokes full permutation', (
    WidgetTester tester,
  ) async {
    final _Probe probe = _Probe();
    probe.submissions = <ImageSetSubmission>[
      const ImageSetSubmission(
        submissionId: 'sub-1',
        libraryId: 'img-1',
        imageSetId: 'a',
        name: 'Draft A',
        memberImageIds: <String>['i1', 'i2'],
      ),
    ];
    await _pumpEditor(tester, probe);
    await tester.pumpAndSettle();

    final Finder dragHandle = find.byIcon(Icons.drag_handle).first;
    await tester.scrollUntilVisible(dragHandle, 80);
    await tester.longPress(dragHandle);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.drag(dragHandle, const Offset(0, 120));
    await tester.pumpAndSettle();

    expect(probe.reorderCalls, hasLength(1));
    expect(probe.reorderCalls.single, <String>['i2', 'i1']);
  });
}