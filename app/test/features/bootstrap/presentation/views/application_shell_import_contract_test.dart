import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('ApplicationShell 不 deep import library_admin 实现层（ADR-0027）', () {
    final File shellFile = File(
      p.join(
        'lib',
        'features',
        'bootstrap',
        'presentation',
        'views',
        'application_shell.dart',
      ),
    );
    final String source = shellFile.readAsStringSync();

    expect(source.contains('features/library_admin/presentation/'), isFalse);
    expect(source.contains('features/library_admin/di/'), isFalse);
    expect(source.contains('features/library_admin/data/'), isFalse);
    expect(source, contains('appShellFeedbackBelowTitleBarFactoryProvider'));
    expect(source, contains('appShellNavigationSlotAssemblyProvider'));
  });
}
