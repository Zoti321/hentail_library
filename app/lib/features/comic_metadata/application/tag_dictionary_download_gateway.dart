import 'dart:typed_data';

import 'package:hentai_library/core/async/cancellation_token.dart';

abstract interface class TagDictionaryDownloadGateway {
  Future<Uint8List> download({
    required String url,
    void Function(int received, int total)? onProgress,
    CancellationToken? cancelToken,
  });
}
