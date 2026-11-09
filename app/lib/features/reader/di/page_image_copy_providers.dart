import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reader/data/adapters/page_image_png_encoder.dart';
import 'package:hentai_library/features/reader/data/adapters/system_clipboard_image_adapter.dart';
import 'package:hentai_library/features/reader/domain/clipboard_image_port.dart';
import 'package:hentai_library/features/reader/application/copy_page_image_service.dart';
import 'package:hentai_library/shared/di/data_providers.dart';

/// Bootstrap / presentation DI for clipboard + page copy (adapters stay in data/).
ClipboardImagePort createClipboardImagePort() =>
    const SystemClipboardImageAdapter();

final Provider<ClipboardImagePort> clipboardImagePortProvider =
    Provider<ClipboardImagePort>((Ref ref) => createClipboardImagePort());

final Provider<CopyPageImageService> copyPageImageServiceProvider =
    Provider<CopyPageImageService>(
      (Ref ref) => CopyPageImageService(
        pageSource: ref.read(comicPageSourcePortProvider),
        clipboardImage: ref.read(clipboardImagePortProvider),
        encodePng: encodePageImagePng,
      ),
    );
