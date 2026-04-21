import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/series/auto_series_infer_service.dart';

void main() {
  test('data.json golden cases match inferSeriesFromTitles', () async {
    final File file = File('test/data/services/series/data.json');
    final Map<String, dynamic> root =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final List<dynamic> cases = root['data'] as List<dynamic>;
    const AutoSeriesInferService service = AutoSeriesInferService();
    for (final dynamic raw in cases) {
      final Map<String, dynamic> item = raw as Map<String, dynamic>;
      final List<dynamic> inputRaw = item['input'] as List<dynamic>;
      final List<String> input =
          inputRaw.map((dynamic e) => e as String).toList();
      final Map<String, dynamic> expectedOut =
          item['output'] as Map<String, dynamic>;
      final String expectedName = expectedOut['seriesName'] as String;
      final Map<String, dynamic> expectedIndexRaw =
          expectedOut['index'] as Map<String, dynamic>;
      final Map<String, int> expectedIndex = expectedIndexRaw.map(
        (String k, dynamic v) => MapEntry<String, int>(k, v as int),
      );
      final InferredSeriesFromTitlesResult? actual =
          service.inferSeriesFromTitles(input);
      expect(actual, isNotNull, reason: 'input: $input');
      expect(actual!.seriesName, expectedName);
      expect(actual.indexByTitle.length, expectedIndex.length);
      for (final MapEntry<String, int> e in expectedIndex.entries) {
        expect(actual.indexByTitle[e.key], e.value);
      }
    }
  });
}
