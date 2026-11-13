import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/async/cancellation_token.dart';
import 'package:hentai_library/features/comic_metadata/application/tag_dictionary_download_gateway.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_management_repository.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_dictionary_import_result.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_repository.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/download_providers.dart';
import 'package:hentai_library/features/comic_metadata/presentation/view_models/named_facet_management_view_model.dart';
import 'package:hentai_library/features/comic_metadata/presentation/view_models/tag_dictionary_import_view_model.dart';
import 'package:hentai_library/features/comic_metadata/public/providers/comic_metadata_repository_providers.dart';
import 'package:logging/logging.dart';

const _url = 'https://example.com/tags.json';
const _result = TagDictionaryImportResult(
  added: 2,
  skippedExisting: 3,
  skippedFilteredOrEmptyOrDedupe: 4,
);

void main() {
  test(
    'network import awaits download, repository and UI refresh in order',
    () async {
      final h = _Harness();
      final downloaded = Completer<Uint8List>();
      final imported = Completer<TagDictionaryImportResult>();
      final refreshed = Completer<void>();
      h.gateway.respond = () => downloaded.future;
      h.repository.respond = () => imported.future;
      h.management.respond = () => refreshed.future;
      final progress = <(int, int)>[];
      final pending = h.importer.importFromNetwork(
        url: _url,
        onDownloadProgress: (received, total) =>
            progress.add((received, total)),
      );
      expect(h.events, ['download']);
      expect(h.gateway.url, _url);
      expect(h.gateway.token, isNotNull);
      expect(h.gateway.token!.isCancelled, isFalse);
      h.gateway.progress!(10, 20);
      expect(progress, [(10, 20)]);
      expect(h.state.running, isTrue);
      downloaded.complete(h.bytes);
      await h.repository.entered.future;
      expect(h.events, ['download', 'import']);
      expect(h.repository.received, same(h.bytes));
      expect(h.state.running, isTrue);
      imported.complete(_result);
      await h.management.entered.future;
      expect(h.events, ['download', 'import', 'refresh']);
      expect(h.state.running, isTrue);
      expect(h.state.lastResult, isNull);
      refreshed.complete();
      expect(await pending, same(_result));
      expect(h.state.running, isFalse);
      expect(h.state.lastResult, same(_result));
      expect(h.state.error, isNull);
      expect(h.logs, isEmpty);
      h.importer.cancel();
      expect(h.gateway.token!.isCancelled, isFalse);
    },
  );

  test(
    'another network or local request is inert while download is pending',
    () async {
      final h = _Harness();
      final downloaded = Completer<Uint8List>();
      h.gateway.respond = () => downloaded.future;
      final pending = h.importer.importFromNetwork(url: _url);
      final token = h.gateway.token;
      expect(
        await h.importer.importFromNetwork(
          url: 'https://example.com/other.json',
        ),
        isNull,
      );
      expect(await h.importer.importFromBytes(h.bytes), isNull);
      expect(h.events, ['download']);
      expect(h.gateway.token, same(token));
      expect(h.state.running, isTrue);
      downloaded.complete(h.bytes);
      expect(await pending, same(_result));
      expect(h.events, ['download', 'import', 'refresh']);
    },
  );

  test('download cancellation is silent and does not import', () async {
    final h = _Harness();
    h.gateway.respond = () async {
      await h.gateway.token!.whenCancelled;
      throw const OperationCancelledException();
    };
    final pending = h.importer.importFromNetwork(url: _url);
    h.importer.cancel();
    expect(h.gateway.token!.isCancelled, isTrue);
    expect(h.gateway.token!.reason, '用户取消');
    expect(await pending, isNull);
    expect(h.events, ['download']);
    expect(h.state.running, isFalse);
    expect(h.state.error, isNull);
    expect(h.state.lastResult, isNull);
    expect(h.logs, isEmpty);
  });

  test('download errors retain the download failure phase', () async {
    final h = _Harness();
    final failure = StateError('network');
    h.gateway.respond = () async => throw failure;
    expect(await h.importer.importFromNetwork(url: _url), isNull);
    expect(h.events, ['download']);
    _expectFailure(h, failure, '下载标签字典失败');
  });

  for (final failure in <Object>[
    StateError('repository'),
    const OperationCancelledException(),
  ]) {
    test(
      'repository $failure remains an import failure without retry',
      () async {
        final h = _Harness();
        h.repository.respond = () async => throw failure;
        expect(await h.importer.importFromNetwork(url: _url), isNull);
        expect(h.events, ['download', 'import']);
        _expectFailure(h, failure, '导入标签字典失败');
      },
    );
  }

  test(
    'refresh failure after commit does not retry or report an import result',
    () async {
      final h = _Harness();
      final failure = StateError('refresh');
      h.management.respond = () async => throw failure;
      expect(await h.importer.importFromNetwork(url: _url), isNull);
      expect(h.events, ['download', 'import', 'refresh']);
      _expectFailure(h, failure, '导入标签字典失败');
    },
  );

  test(
    'local import needs no network gateway and still refreshes UI state',
    () async {
      final h = _Harness(network: false);
      expect(await h.importer.importFromBytes(h.bytes), same(_result));
      expect(h.events, ['import', 'refresh']);
      expect(h.repository.received, same(h.bytes));
      expect(h.state.lastResult, same(_result));
      expect(h.state.error, isNull);
      expect(h.state.running, isFalse);
    },
  );

  test('cancel after repository import starts does not interrupt the committed write', () async {
    final h = _Harness();
    final imported = Completer<TagDictionaryImportResult>();
    h.repository.respond = () => imported.future;
    final pending = h.importer.importFromNetwork(url: _url);
    await h.repository.entered.future;
    h.importer.cancel();
    expect(h.gateway.token!.isCancelled, isTrue);
    expect(h.state.running, isTrue);
    imported.complete(_result);
    expect(await pending, same(_result));
    expect(h.events, ['download', 'import', 'refresh']);
    expect(h.state.lastResult, same(_result));
    expect(h.state.error, isNull);
  });
}

void _expectFailure(_Harness h, Object failure, String phase) {
  expect(h.state.running, isFalse);
  expect(h.state.lastResult, isNull);
  expect(h.state.error, failure.toString());
  expect(h.logs.map((record) => record.message), [phase]);
  expect(h.logs.single.error, same(failure));
}

class _Harness {
  _Harness({bool network = true}) {
    gateway = _Gateway(events, bytes);
    repository = _Repository(events);
    management = _Management(events);
    container = ProviderContainer(
      overrides: [
        tagRepoProvider.overrideWithValue(repository),
        if (network)
          tagDictionaryDownloadGatewayProvider.overrideWithValue(gateway),
        namedFacetManagementViewModelProvider(ManagedNamedFacetKind.tag)
            .overrideWith(() => management),
      ],
    );
    addTearDown(container.dispose);
    final subscription = Logger.root.onRecord
        .where((record) => record.loggerName == 'hentai.ui.tag-import')
        .listen(logs.add);
    addTearDown(subscription.cancel);
    importer = container.read(tagDictionaryImportViewModelProvider.notifier);
  }

  final bytes = Uint8List.fromList([1, 2, 3]);
  final events = <String>[];
  final logs = <LogRecord>[];
  late final _Gateway gateway;
  late final _Repository repository;
  late final _Management management;
  late final ProviderContainer container;
  late final TagDictionaryImportViewModel importer;
  TagDictionaryImportState get state =>
      container.read(tagDictionaryImportViewModelProvider);
}

class _Gateway implements TagDictionaryDownloadGateway {
  _Gateway(this.events, this.bytes);
  final List<String> events;
  final Uint8List bytes;
  Future<Uint8List> Function()? respond;
  CancellationToken? token;
  void Function(int, int)? progress;
  String? url;

  @override
  Future<Uint8List> download({
    required String url,
    void Function(int, int)? onProgress,
    CancellationToken? cancelToken,
  }) {
    events.add('download');
    this.url = url;
    token = cancelToken;
    progress = onProgress;
    return respond?.call() ?? Future.value(bytes);
  }
}

class _Repository implements TagRepository {
  _Repository(this.events);
  final List<String> events;
  final entered = Completer<void>();
  Future<TagDictionaryImportResult> Function()? respond;
  List<int>? received;

  @override
  Future<TagDictionaryImportResult> importTagDictionary(List<int> jsonBytes) {
    events.add('import');
    received = jsonBytes;
    entered.complete();
    return respond?.call() ?? Future.value(_result);
  }

  @override
  Future<List<Tag>> listAll() => throw UnimplementedError();
}

class _Management extends NamedFacetManagementViewModel {
  _Management(this.events);
  final List<String> events;
  final entered = Completer<void>();
  Future<void> Function()? respond;

  @override
  NamedFacetManagementState build(ManagedNamedFacetKind kind) =>
      NamedFacetManagementState.initial();

  @override
  Future<void> refreshAfterTagDictionaryChange() {
    events.add('refresh');
    entered.complete();
    return respond?.call() ?? Future.value();
  }
}
