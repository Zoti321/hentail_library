import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// ADR-0039 领域事件门禁：
/// - E1：`DomainEvent` 子类只允许声明在 `lib/shared/domain/events/`；
/// - E2：`.publish(` 只允许出现在 `application/`、`data/`（禁止 presentation 发布）；
/// - E4：`DomainEventPublisher` / `DomainEventBus` 实现面收敛到 shared。
void main() {
  late Directory libDir;

  setUp(() {
    libDir = Directory(p.join(Directory.current.path, 'lib'));
  });

  test('E1: DomainEvent subclasses live in shared/domain/events only', () {
    final List<String> offenders = <String>[
      for (final File file in _dartFiles(libDir))
        if (!_isGenerated(file.path) &&
            !_isEventDir(_rel(libDir, file)) &&
            _subclassRe.hasMatch(file.readAsStringSync()))
          _rel(libDir, file),
    ]..sort();
    expect(
      offenders,
      isEmpty,
      reason:
          'DomainEvent 子类必须在 lib/shared/domain/events/ 声明（ADR-0039）：\n'
          '${offenders.join('\n')}',
    );
  });

  test('E2: publish() only from application/ or data/ layers', () {
    final List<String> offenders = <String>[];
    for (final File file in _dartFiles(libDir)) {
      if (_isGenerated(file.path)) {
        continue;
      }
      final String rel = _rel(libDir, file);
      if (!file.readAsStringSync().contains('.publish(')) {
        continue;
      }
      final bool allowed =
          rel.contains('/application/') ||
          rel.contains('/data/') ||
          rel.startsWith('shared/domain/events/');
      if (!allowed) {
        offenders.add(rel);
      }
    }
    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason:
          '领域事件只允许由 application / data 层发布（ADR-0039），'
          'presentation 请改调 Port 或经 ViewModel 转发：\n${offenders.join('\n')}',
    );
  });

  test('E4: DomainEventPublisher/Bus implementations stay in shared', () {
    final List<String> offenders = <String>[];
    for (final File file in _dartFiles(libDir)) {
      if (_isGenerated(file.path)) {
        continue;
      }
      final String rel = _rel(libDir, file);
      for (final RegExpMatch match in _implRe.allMatches(
        file.readAsStringSync(),
      )) {
        final String type = match.group(1)!;
        final bool allowed = type == 'DomainEventPublisher'
            ? rel == 'shared/domain/events/domain_event_bus.dart'
            : rel.startsWith('shared/data/events/');
        if (!allowed) {
          offenders.add('$rel -> $type');
        }
      }
    }
    offenders.sort();
    expect(
      offenders,
      isEmpty,
      reason:
          'DomainEventBus 具体实现只允许 shared/data/events/（ADR-0039）：\n'
          '${offenders.join('\n')}',
    );
  });
}

final RegExp _subclassRe = RegExp(
  r'^\s*(?:abstract\s+|final\s+|sealed\s+|base\s+|interface\s+|mixin\s+)*class\s+\w+[^;{]*\b(?:extends|implements)\s+DomainEvent\b',
  multiLine: true,
);
final RegExp _implRe = RegExp(
  r'\bimplements\s+(DomainEventPublisher|DomainEventBus)\b',
);

bool _isEventDir(String rel) => rel.startsWith('shared/domain/events/');

bool _isGenerated(String path) {
  final String name = p.basename(path);
  return name.endsWith('.g.dart') ||
      name.endsWith('.freezed.dart') ||
      name.startsWith('frb_generated');
}

String _rel(Directory libDir, File file) =>
    p.posix.joinAll(p.split(p.relative(file.path, from: libDir.path)));

Iterable<File> _dartFiles(Directory root) sync* {
  if (!root.existsSync()) {
    return;
  }
  for (final FileSystemEntity entity in root.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}
