import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_admin/domain/library_change.dart';

void main() {
  test('LibraryChange.merge accumulates flags', () {
    const LibraryChange a = LibraryChange(tagsWritten: true);
    const LibraryChange b = LibraryChange(metadataSaved: true);
    final LibraryChange merged = a.merge(b);
    expect(merged.tagsWritten, isTrue);
    expect(merged.metadataSaved, isTrue);
    expect(merged.isEmpty, isFalse);
  });
}
