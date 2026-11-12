import 'package:hentai_library/features/comic_metadata/application/tag_dictionary_download_gateway.dart';
import 'package:hentai_library/shared/application/cancellation_token.dart';
import 'package:hentai_library/infrastructure/http/cancellable_dio_request.dart';

import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 从网络 URL 下载标签字典 JSON 字节流。
abstract final class TagDictionaryDownloadConstants {
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(minutes: 2);
}

class DioTagDictionaryDownloadGateway implements TagDictionaryDownloadGateway {
  DioTagDictionaryDownloadGateway({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: TagDictionaryDownloadConstants.connectTimeout,
              receiveTimeout: TagDictionaryDownloadConstants.receiveTimeout,
              followRedirects: true,
              validateStatus: (int? status) =>
                  status != null && status >= 200 && status < 400,
            ),
          );

  final Dio _dio;

  @override
  Future<Uint8List> download({
    required String url,
    void Function(int received, int total)? onProgress,
    CancellationToken? cancelToken,
  }) async {
    final Response<List<int>> response = await runCancellableDioRequest(
      cancelToken,
      (dioToken) => _dio.get<List<int>>(
        url,
        cancelToken: dioToken,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onProgress,
      ),
    );
    final List<int>? data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('下载的标签字典为空');
    }
    return Uint8List.fromList(data);
  }
}
