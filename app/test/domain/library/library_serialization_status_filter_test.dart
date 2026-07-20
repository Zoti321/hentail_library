import 'package:hentai_library/domain/library/library_serialization_status_filter.dart';
import 'package:test/test.dart';

void main() {
  group('LibrarySerializationStatusFilter', () {
    test('fromStorage falls back to unrestricted for unknown raw', () {
      expect(
        LibrarySerializationStatusFilter.fromStorage(null),
        LibrarySerializationStatusFilter.unrestricted,
      );
      expect(
        LibrarySerializationStatusFilter.fromStorage('bogus'),
        LibrarySerializationStatusFilter.unrestricted,
      );
    });

    test('seriesSerializationStatus maps selectable options to rust strings', () {
      expect(
        LibrarySerializationStatusFilter.unrestricted.seriesSerializationStatus(),
        isNull,
      );
      expect(
        LibrarySerializationStatusFilter.ongoing.seriesSerializationStatus(),
        'ongoing',
      );
      expect(
        LibrarySerializationStatusFilter.ended.seriesSerializationStatus(),
        'ended',
      );
      expect(
        LibrarySerializationStatusFilter.hiatus.seriesSerializationStatus(),
        'hiatus',
      );
      expect(
        LibrarySerializationStatusFilter.unknown.seriesSerializationStatus(),
        'unknown',
      );
    });

    test('selectableOptions excludes unrestricted', () {
      expect(
        LibrarySerializationStatusFilter.selectableOptions,
        isNot(contains(LibrarySerializationStatusFilter.unrestricted)),
      );
      expect(
        LibrarySerializationStatusFilter.selectableOptions,
        containsAll(<LibrarySerializationStatusFilter>[
          LibrarySerializationStatusFilter.ongoing,
          LibrarySerializationStatusFilter.ended,
          LibrarySerializationStatusFilter.hiatus,
          LibrarySerializationStatusFilter.unknown,
        ]),
      );
    });
  });
}
