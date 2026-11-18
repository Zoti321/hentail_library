import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reader/domain/clipboard_image_port.dart';
import 'package:hentai_library/features/reader/application/copy_page_image_use_case.dart';
import 'package:hentai_library/features/reader/presentation/providers/session_providers.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<ClipboardImagePort> clipboardImagePortProvider =
    requiredProvider('clipboardImagePortProvider');
final Provider<PageImagePngEncoder> pageImagePngEncoderProvider =
    requiredProvider('pageImagePngEncoderProvider');
final copyPageImageUseCaseProvider = Provider<CopyPageImageUseCase>(
  (ref) => CopyPageImageUseCase(
    loadPageBytes: ref.read(openReadSessionUseCaseProvider).loadPageBytes,
    clipboardImage: ref.read(clipboardImagePortProvider),
    encodePng: ref.read(pageImagePngEncoderProvider),
  ),
);
