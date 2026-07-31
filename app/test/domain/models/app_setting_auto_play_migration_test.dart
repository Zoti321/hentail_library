import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/app_setting.dart';

void main() {
  test('fromJson drops legacy readerAutoPlayEnabled and keeps interval', () {
    final AppSetting setting = AppSetting.fromJson(<String, Object?>{
      'version': 3,
      'readerAutoPlayEnabled': true,
      'readerAutoPlayIntervalSeconds': 8,
    });

    expect(setting.readerAutoPlayIntervalSeconds, 8);
    expect(setting.toJson().containsKey('readerAutoPlayEnabled'), isFalse);
  });
}
