import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hentai_library/core/constants/ehtag_dictionary_constants.dart';

class EhTagDictionaryImportService {
  EhTagDictionaryImportService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: EhTagDictionaryConstants.connectTimeout,
              receiveTimeout: EhTagDictionaryConstants.receiveTimeout,
              followRedirects: true,
              validateStatus: (int? status) =>
                  status != null && status >= 200 && status < 400,
            ),
          );

  final Dio _dio;

  Future<Uint8List> downloadLatest({
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final Response<List<int>> response = await _dio.get<List<int>>(
      EhTagDictionaryConstants.latestDbTextJsonUrl,
      cancelToken: cancelToken,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: onProgress,
    );
    final List<int>? data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('下载的 db.text.json 为空');
    }
    return Uint8List.fromList(data);
  }
}
