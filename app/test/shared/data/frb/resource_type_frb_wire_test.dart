import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/data/frb/resource_type_frb_wire.dart';

void main() {
  test('mapResourceType covers every ResourceType wire token', () {
    expect(mapResourceType(ResourceType.dir), 'dir');
    expect(mapResourceType(ResourceType.zip), 'zip');
    expect(mapResourceType(ResourceType.cbz), 'cbz');
    expect(mapResourceType(ResourceType.epub), 'epub');
    expect(mapResourceType(ResourceType.cbr), 'cbr');
    expect(mapResourceType(ResourceType.rar), 'rar');
    expect(mapResourceType(ResourceType.cb7), 'cb7');
    expect(mapResourceType(ResourceType.sevenZ), 'sevenz');
    expect(mapResourceType(ResourceType.pdf), 'pdf');
  });
}
