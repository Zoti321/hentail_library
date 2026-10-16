import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/data/adapters/system_clipboard_image_adapter.dart';
import 'package:hentai_library/shared/domain/ports/clipboard_image_port.dart';
import 'package:hentai_library/features/read_session/domain/page_image_copy.dart';
import 'package:hentai_library/features/bootstrap/di/ports.dart';

final Provider<ClipboardImagePort> clipboardImagePortProvider =
    Provider<ClipboardImagePort>(
      (Ref ref) => const SystemClipboardImageAdapter(),
    );

final Provider<PageImageCopy> pageImageCopyProvider = Provider<PageImageCopy>(
  (Ref ref) => PageImageCopy(
    pageSource: ref.read(comicPageSourcePortProvider),
    clipboardImage: ref.read(clipboardImagePortProvider),
  ),
);
