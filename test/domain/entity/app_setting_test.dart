import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/model/models.dart';

void main() {
  test('AppSetting uses default readerDimLevel when json key missing', () {
    final AppSetting actual = AppSetting.fromJson(<String, dynamic>{
      'version': 3,
      'themePreference': 'system',
      'isHealthyMode': false,
      'autoScan': false,
    });
    expect(actual.readerDimLevel, 0.0);
    expect(actual.readerIsVertical, isFalse);
  });

  test('AppSetting serializes readerDimLevel', () {
    final AppSetting setting = AppSetting(
      readerDimLevel: 0.35,
      readerIsVertical: true,
      themePreference: AppThemePreference.dark,
      isHealthyMode: true,
      autoScan: true,
    );
    final Map<String, dynamic> json = setting.toJson();
    expect(json['readerDimLevel'], 0.35);
    expect(json['readerIsVertical'], isTrue);
    expect(json['themePreference'], 'dark');
  });
}
