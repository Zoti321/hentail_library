import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/app_data/app_data_wipe_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('wipeApplicationData', () {
    late Directory tempDir;
    var shutdownCalled = false;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('app_data_wipe_test');
      shutdownCalled = false;
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_mode': 'dark',
      });
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'deletes app data directory and clears preferences on success',
      () async {
        final File marker = File('${tempDir.path}/marker.txt');
        await marker.writeAsString('keep-me-deleted');

        final AppDataWipeResult result = await wipeApplicationData(
          appDataPath: tempDir.path,
          shutdownAppData: () => shutdownCalled = true,
        );

        expect(result, AppDataWipeResult.success);
        expect(shutdownCalled, isTrue);
        expect(tempDir.existsSync(), isFalse);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getKeys(), isEmpty);
      },
    );

    test(
      'returns deleteFailed without clearing preferences when delete fails',
      () async {
        final File marker = File('${tempDir.path}/marker.txt');
        await marker.writeAsString('blocked');
        var clearCalled = false;

        final AppDataWipeResult result = await wipeApplicationData(
          appDataPath: tempDir.path,
          shutdownAppData: () => shutdownCalled = true,
          deleteAppDataDirectory: (_) async {
            throw const FileSystemException('blocked');
          },
          clearPreferences: () async {
            clearCalled = true;
            return true;
          },
        );

        expect(result, AppDataWipeResult.deleteFailed);
        expect(shutdownCalled, isTrue);
        expect(clearCalled, isFalse);
        expect(marker.existsSync(), isTrue);
      },
    );

    test('treats missing directory as success after shutdown', () async {
      await tempDir.delete(recursive: true);

      final AppDataWipeResult result = await wipeApplicationData(
        appDataPath: tempDir.path,
        shutdownAppData: () => shutdownCalled = true,
      );

      expect(result, AppDataWipeResult.success);
      expect(shutdownCalled, isTrue);
    });
  });
}
