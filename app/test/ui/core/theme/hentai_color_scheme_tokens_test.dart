import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

void main() {
  group('HentaiColorScheme semantic colors', () {
    test('warning and error are distinct in light theme', () {
      final HentaiColorScheme h = buildAppTheme(Brightness.light).colorScheme.hentai;
      expect(h.warning, isNot(h.error));
      expect(h.serializationHiatus, h.warning);
    });

    test('warning and error are distinct in dark theme', () {
      final HentaiColorScheme h = buildAppTheme(Brightness.dark).colorScheme.hentai;
      expect(h.warning, isNot(h.error));
    });
  });
}
