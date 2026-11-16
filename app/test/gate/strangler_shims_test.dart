import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'lib_layout_scan_helpers.dart';

void main() {
  late Directory libDir;
  late File allowlistFile;

  setUp(() {
    libDir = Directory(p.join(Directory.current.path, 'lib'));
    allowlistFile = File(p.join('test', 'gate', 'strangler_shims.txt'));
  });

  group('strangler shim allowlist (#219)', () {
    test('allowlist file exists', () {
      expect(allowlistFile.existsSync(), isTrue);
    });

    test('every export-only shim under lib/ is listed', () {
      final List<String> allowlisted = readStranglerShimAllowlist(
        allowlistFile,
      );
      final List<String> actualShims = collectStranglerShims(libDir);
      final List<String> unlisted = actualShims
          .where((String path) => !allowlisted.contains(path))
          .toList();
      expect(
        unlisted,
        isEmpty,
        reason: 'Add paths to test/gate/strangler_shims.txt or remove shims',
      );
    });

    test('every allowlisted path exists and is an export-only shim', () {
      final List<String> allowlisted = readStranglerShimAllowlist(
        allowlistFile,
      );
      final List<String> missing = <String>[];
      final List<String> notShims = <String>[];
      for (final String relative in allowlisted) {
        final File file = File(p.join(libDir.path, relative));
        if (!file.existsSync()) {
          missing.add(relative);
          continue;
        }
        if (!isStranglerShimSource(file.readAsStringSync())) {
          notShims.add(relative);
        }
      }
      expect(missing, isEmpty, reason: 'Ghost allowlist entries');
      expect(
        notShims,
        isEmpty,
        reason: 'Allowlisted files must be export-only shims',
      );
    });
  });

  group('shared 下禁止 export-only 转发到 features（#504）', () {
    late File forwarderAllowlist;

    setUp(() {
      forwarderAllowlist = File(
        p.join('test', 'gate', 'shared_feature_forwarder_allowlist.txt'),
      );
    });

    test('allowlist file exists', () {
      expect(forwarderAllowlist.existsSync(), isTrue);
    });

    test('every shared→features export-only forwarder is listed', () {
      final List<String> allowlisted = readStranglerShimAllowlist(
        forwarderAllowlist,
      );
      final List<String> actual = collectSharedFeatureForwarders(libDir);
      final List<String> unlisted = actual
          .where((String path) => !allowlisted.contains(path))
          .toList();
      expect(
        unlisted,
        isEmpty,
        reason:
            '`lib/shared/**` 不得 export-only 转发到 `features/**`；'
            '消除转发或登记到 test/gate/shared_feature_forwarder_allowlist.txt：\n'
            '${unlisted.join('\n')}',
      );
    });

    test('every allowlisted forwarder path exists and still forwards', () {
      final List<String> allowlisted = readStranglerShimAllowlist(
        forwarderAllowlist,
      );
      final List<String> missing = <String>[];
      final List<String> notForwarders = <String>[];
      for (final String relative in allowlisted) {
        final File file = File(p.join(libDir.path, relative));
        if (!file.existsSync()) {
          missing.add(relative);
          continue;
        }
        if (!isSharedFeatureForwarderSource(file.readAsStringSync())) {
          notForwarders.add(relative);
        }
      }
      expect(missing, isEmpty, reason: 'Ghost forwarder allowlist entries');
      expect(
        notForwarders,
        isEmpty,
        reason: 'Allowlisted files must still be shared→features forwarders',
      );
    });
  });
}
