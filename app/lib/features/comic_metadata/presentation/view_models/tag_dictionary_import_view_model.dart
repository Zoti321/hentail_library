import 'dart:typed_data';

import 'package:hentai_library/shared/application/cancellation_token.dart';
import 'package:hentai_library/core/logging/app_log.dart';
import 'package:hentai_library/core/errors/error_message.dart';
import 'package:hentai_library/features/comic_metadata/domain/tag_dictionary_import_result.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/download_providers.dart';
import 'package:hentai_library/features/comic_metadata/presentation/view_models/named_facet_management_view_model.dart';
import 'package:hentai_library/features/comic_metadata/public/providers/comic_metadata_repository_providers.dart';
import 'package:hentai_library/features/comic_metadata/domain/named_facet_management_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_dictionary_import_view_model.g.dart';

class TagDictionaryImportState {
  const TagDictionaryImportState({
    this.running = false,
    this.error,
    this.lastResult,
  });

  final bool running;
  final String? error;
  final TagDictionaryImportResult? lastResult;

  TagDictionaryImportState copyWith({
    bool? running,
    String? error,
    TagDictionaryImportResult? lastResult,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return TagDictionaryImportState(
      running: running ?? this.running,
      error: clearError ? null : (error ?? this.error),
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
    );
  }
}

@Riverpod(keepAlive: true)
class TagDictionaryImportViewModel extends _$TagDictionaryImportViewModel {
  CancellationToken? _cancelToken;

  @override
  TagDictionaryImportState build() => const TagDictionaryImportState();

  Future<TagDictionaryImportResult?> importFromNetwork({
    required String url,
    void Function(int received, int total)? onDownloadProgress,
  }) async {
    if (state.running) {
      return null;
    }
    state = state.copyWith(running: true, clearError: true, clearResult: true);
    _cancelToken = CancellationToken();
    try {
      final Uint8List bytes = await ref
          .read(tagDictionaryDownloadGatewayProvider)
          .download(
            url: url,
            cancelToken: _cancelToken,
            onProgress: onDownloadProgress,
          );
      return await _importBytes(bytes);
    } on OperationCancelledException {
      state = state.copyWith(running: false);
      return null;
    } catch (error, stackTrace) {
      return _fail(error, stackTrace, fallback: '下载标签字典失败');
    } finally {
      _cancelToken = null;
    }
  }

  Future<TagDictionaryImportResult?> importFromBytes(Uint8List bytes) async {
    if (state.running) {
      return null;
    }
    state = state.copyWith(running: true, clearError: true, clearResult: true);
    try {
      return await _importBytes(bytes);
    } catch (error, stackTrace) {
      return _fail(error, stackTrace, fallback: '导入标签字典失败');
    }
  }

  void cancel() {
    _cancelToken?.cancel('用户取消');
  }

  void clearLastResult() {
    state = state.copyWith(clearResult: true, clearError: true);
  }

  Future<TagDictionaryImportResult?> _importBytes(Uint8List bytes) async {
    try {
      final TagDictionaryImportResult result = await ref
          .read(tagRepoProvider)
          .importTagDictionary(bytes);
      await ref
          .read(
            namedFacetManagementViewModelProvider(ManagedNamedFacetKind.tag)
                .notifier,
          )
          .refreshAfterTagDictionaryChange();
      state = state.copyWith(running: false, lastResult: result);
      return result;
    } catch (error, stackTrace) {
      return _fail(error, stackTrace, fallback: '导入标签字典失败');
    }
  }

  TagDictionaryImportResult? _fail(
    Object error,
    StackTrace stackTrace, {
    required String fallback,
  }) {
    logError(AppLog.ui('tag-import'), fallback, error, stackTrace);
    final String message = appErrorMessage(error);
    state = state.copyWith(running: false, error: message);
    return null;
  }
}
