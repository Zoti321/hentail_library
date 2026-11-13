import 'dart:async';
import 'dart:typed_data';

import 'package:hentai_library/core/async/cancellation_token.dart';
import 'package:hentai_library/features/comic_metadata/application/import_tag_dictionary_use_case.dart';
import 'package:hentai_library/features/comic_metadata/application/tag_dictionary_download_gateway.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_dictionary_import_result.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_repository.dart';
import 'package:test/test.dart';

const _result = TagDictionaryImportResult(
  added: 2,
  skippedExisting: 3,
  skippedFilteredOrEmptyOrDedupe: 4,
);

void main() {
  test('construction is inert; download finishes before importing the same payload', () async {
    final response = Completer<Uint8List>();
    final bytes = Uint8List.fromList([1, 2, 3]);
    final token = CancellationToken();
    final calls = <String>[];
    final progressEvents = <(int, int)>[];
    void progress(int received, int total) =>
        progressEvents.add((received, total));
    final gateway = _Gateway(() {
      calls.add('download');
      return response.future;
    });
    final repository = _Repository((payload) async {
      calls.add('import');
      expect(payload, same(bytes));
      return _result;
    });
    final useCase = ImportTagDictionaryUseCase(
      downloadGateway: gateway,
      repository: repository,
    );
    expect(calls, isEmpty);
    final pending = useCase(
      url: 'https://example.com/tags.json',
      cancelToken: token,
      onDownloadProgress: progress,
    );
    expect(calls, ['download']);
    expect(repository.calls, 0);
    expect(gateway.url, 'https://example.com/tags.json');
    expect(gateway.cancelToken, same(token));
    expect(gateway.onProgress, same(progress));
    gateway.onProgress!(1, 3);
    expect(progressEvents, [(1, 3)]);
    response.complete(bytes);
    expect(await pending, same(_result));
    expect(calls, ['download', 'import']);
    expect(gateway.calls, 1);
    expect(repository.calls, 1);
  });

  for (final failure in <Object>[
    const OperationCancelledException(),
    StateError('download'),
  ]) {
    test(
      'download $failure propagates unchanged without importing or retrying',
      () async {
        final gateway = _Gateway(() async => throw failure);
        final repository = _Repository((_) async => _result);
        final useCase = ImportTagDictionaryUseCase(
          downloadGateway: gateway,
          repository: repository,
        );
        await expectLater(
          useCase(url: 'https://example.com/tags.json'),
          throwsA(same(failure)),
        );
        expect(gateway.calls, 1);
        expect(repository.calls, 0);
      },
    );
  }

  for (final failure in <Object>[
    StateError('import'),
    const OperationCancelledException(),
  ]) {
    test(
      'repository $failure keeps its cause and stack in an import failure without retry',
      () async {
        final stack = StackTrace.fromString('repository-original-stack');
        final gateway = _Gateway(() async => Uint8List.fromList([1]));
        final repository = _Repository((_) async {
          Error.throwWithStackTrace(failure, stack);
        });
        final useCase = ImportTagDictionaryUseCase(
          downloadGateway: gateway,
          repository: repository,
        );
        await expectLater(
          useCase(url: 'https://example.com/tags.json'),
          throwsA(
            isA<TagDictionaryImportFailure>()
                .having((error) => error.cause, 'cause', same(failure))
                .having(
                  (error) => error.stackTrace.toString(),
                  'stackTrace',
                  stack.toString(),
                ),
          ),
        );
        expect(gateway.calls, 1);
        expect(repository.calls, 1);
      },
    );
  }

  test('cancellation after a completed download does not interrupt repository import', () async {
    final token = CancellationToken();
    final bytes = Uint8List.fromList([1, 2]);
    final gateway = _Gateway(() async {
      token.cancel('用户取消');
      return bytes;
    });
    final repository = _Repository((payload) async {
      expect(token.isCancelled, isTrue);
      expect(payload, same(bytes));
      return _result;
    });
    final useCase = ImportTagDictionaryUseCase(
      downloadGateway: gateway,
      repository: repository,
    );
    expect(
      await useCase(url: 'https://example.com/tags.json', cancelToken: token),
      same(_result),
    );
    expect(repository.calls, 1);
  });
}

class _Gateway implements TagDictionaryDownloadGateway {
  _Gateway(this.load);

  final Future<Uint8List> Function() load;
  var calls = 0;
  String? url;
  CancellationToken? cancelToken;
  void Function(int received, int total)? onProgress;

  @override
  Future<Uint8List> download({
    required String url,
    void Function(int received, int total)? onProgress,
    CancellationToken? cancelToken,
  }) {
    calls++;
    this.url = url;
    this.cancelToken = cancelToken;
    this.onProgress = onProgress;
    return load();
  }
}

class _Repository implements TagRepository {
  _Repository(this.importBytes);

  final Future<TagDictionaryImportResult> Function(List<int>) importBytes;
  var calls = 0;

  @override
  Future<TagDictionaryImportResult> importTagDictionary(List<int> jsonBytes) {
    calls++;
    return importBytes(jsonBytes);
  }

  @override
  Future<List<Tag>> listAll() =>
      throw StateError('Unexpected dictionary listing');
}
