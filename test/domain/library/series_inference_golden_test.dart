import 'dart:convert';
import 'dart:io';

import 'package:hentai_library/domain/library/auto_series_infer_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

typedef _GoldenCase = ({
  List<String> input,
  String seriesName,
  Map<String, int> indexByTitle,
});

File _goldenDataFile() {
  final String fromCwd = p.join(Directory.current.path, 'test', 'data.json');
  final File cwdFile = File(fromCwd);
  if (cwdFile.existsSync()) {
    return cwdFile;
  }
  return File.fromUri(Platform.script.resolve('../../data.json'));
}

List<_GoldenCase> _loadGoldenCases() {
  final File goldenFile = _goldenDataFile();
  final Object? decoded = jsonDecode(goldenFile.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    throw StateError('test/data.json root must be an object');
  }
  final Object? data = decoded['data'];
  if (data is! List<Object?>) {
    throw StateError('test/data.json must contain a "data" array');
  }
  final List<_GoldenCase> cases = <_GoldenCase>[];
  for (int i = 0; i < data.length; i++) {
    final Object? rawCase = data[i];
    if (rawCase is! Map<String, Object?>) {
      throw StateError('golden case $i must be an object');
    }
    final Object? input = rawCase['input'];
    final Object? output = rawCase['output'];
    if (input is! List<Object?> || output is! Map<String, Object?>) {
      throw StateError('golden case $i must have input[] and output{}');
    }
    final Object? seriesName = output['seriesName'];
    final Object? index = output['index'];
    if (seriesName is! String || index is! Map<String, Object?>) {
      throw StateError('golden case $i output must have seriesName and index');
    }
    final Map<String, int> indexByTitle = <String, int>{};
    for (final MapEntry<String, Object?> entry in index.entries) {
      final Object? value = entry.value;
      if (value is! int) {
        throw StateError(
          'golden case $i index value for "${entry.key}" must be int',
        );
      }
      indexByTitle[entry.key] = value;
    }
    cases.add((
      input: input.cast<String>(),
      seriesName: seriesName,
      indexByTitle: indexByTitle,
    ));
  }
  return cases;
}

void main() {
  const AutoSeriesInferService service = AutoSeriesInferService();
  final List<_GoldenCase> goldenCases = _loadGoldenCases();

  group('AutoSeriesInferService.inferSeriesFromTitles', () {
    for (int i = 0; i < goldenCases.length; i++) {
      final _GoldenCase goldenCase = goldenCases[i];
      final String label = goldenCase.input.isEmpty
          ? 'case $i'
          : goldenCase.input.first;
      test(label, () {
        final InferredSeriesFromTitlesResult? actual = service
            .inferSeriesFromTitles(goldenCase.input);
        expect(actual, isNotNull, reason: 'expected a single inferred series');
        expect(actual!.seriesName, goldenCase.seriesName);
        expect(actual.indexByTitle, goldenCase.indexByTitle);
      });
    }
  });
}
