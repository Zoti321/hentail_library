import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_session.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/shared/application/errors/error_message.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 将 Image set Reader 压入根 Navigator；退出即 pop 回图集详情。
void pushImageSetReaderPage(
  NavigatorState? navigator,
  ImageSetReaderEntry entry,
) {
  navigator?.push(
    MaterialPageRoute<void>(builder: (_) => ImageSetReaderPage(entry: entry)),
  );
}

/// Image set 阅读页：按 catalog 顺序翻页，只读，不写 Comic 阅读历史。
class ImageSetReaderPage extends HookConsumerWidget {
  const ImageSetReaderPage({super.key, required this.entry});

  final ImageSetReaderEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ImageSetReaderSession> sessionAsync = ref.watch(
      imageSetReaderSessionProvider(entry),
    );
    final ValueNotifier<int> page = useState<int>(entry.index);
    final int? total = sessionAsync.asData?.value.pages.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: sessionAsync.when(
              data: (ImageSetReaderSession session) =>
                  _buildPage(ref, session, page),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace _) => Center(
                child: Text(
                  appErrorMessage(error),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Row(
                children: <Widget>[
                  IconButton(
                    key: const ValueKey<String>('imageSetReaderBack'),
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  if (total != null)
                    Text(
                      '${page.value + 1} / $total',
                      key: const ValueKey<String>('imageSetReaderIndicator'),
                      style: const TextStyle(color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    WidgetRef ref,
    ImageSetReaderSession session,
    ValueNotifier<int> page,
  ) {
    if (session.pages.isEmpty) {
      return const SizedBox.shrink();
    }
    final int last = session.pages.length - 1;
    final int index = page.value.clamp(0, last);
    final ImageSetImage image = session.pages[index];

    void goTo(int target) => page.value = target.clamp(0, last);

    final AsyncValue<Uint8List> bytes = ref.watch(
      imageSetPageBytesProvider((libraryId: session.libraryId, image: image)),
    );

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            goTo(index - 1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            goTo(index + 1),
      },
      child: Focus(
        autofocus: true,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            bytes.when(
              data: (Uint8List data) => Image.memory(
                data,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace _) => Center(
                child: Text(
                  appErrorMessage(error),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => goTo(index - 1),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => goTo(index + 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
