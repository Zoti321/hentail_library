import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hentai_library/shared/core/logging/app_log.dart';
import 'package:hentai_library/shared/data/adapters/frb_error_mapper.dart';
import 'package:hentai_library/shared/domain/models/tag_dictionary_import_result.dart';
import 'package:hentai_library/features/named_metadata/di/download_providers.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/tag_management_notifier.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_dictionary_import_controller.g.dart';

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
class TagDictionaryImportController extends _$TagDictionaryImportController {
  CancelToken? _cancelToken;

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
    _cancelToken = CancelToken();
    try {
      final Uint8List bytes = await ref
          .read(tagDictionaryDownloadServiceProvider)
          .download(
            url: url,
            cancelToken: _cancelToken,
            onProgress: onDownloadProgress,
          );
      return await _importBytes(bytes);
    } on DioException catch (error, stackTrace) {
      if (CancelToken.isCancel(error)) {
        state = state.copyWith(running: false);
        return null;
      }
      return _fail(error, stackTrace, fallback: '下载标签字典失败');
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
      ref.invalidate(allTagsProvider);
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
    final String message = caughtErrorMessage(error, fallbackMessage: fallback);
    state = state.copyWith(running: false, error: message);
    return null;
  }
}
