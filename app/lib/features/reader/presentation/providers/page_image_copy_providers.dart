import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reader/domain/clipboard_image_port.dart';
import 'package:hentai_library/features/reader/application/copy_page_image_service.dart';
import 'package:hentai_library/features/reader/presentation/providers/session_providers.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<ClipboardImagePort> clipboardImagePortProvider =
    requiredProvider('clipboardImagePortProvider');
final Provider<PageImagePngEncoder> pageImagePngEncoderProvider =
    requiredProvider('pageImagePngEncoderProvider');
final copyPageImageServiceProvider = Provider<CopyPageImageService>(
  (ref) => CopyPageImageService(
    loadPageBytes: ref.read(openReadSessionServiceProvider).loadPageBytes,
    clipboardImage: ref.read(clipboardImagePortProvider),
    encodePng: ref.read(pageImagePngEncoderProvider),
  ),
);
