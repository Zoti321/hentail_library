import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_page_aspect_ratios.g.dart';

/// Default width/height for webtoon slots before the first decode reports size.
const double kReaderDefaultPageAspectRatio = 3 / 4;

String readerPageAspectRatioKey(String comicId, int pageIndexZeroBased) =>
    '$comicId:$pageIndexZeroBased';

/// Remembers decoded page aspect ratios so continuous scroll can reserve height.
@Riverpod(keepAlive: true)
class ReaderPageAspectRatios extends _$ReaderPageAspectRatios {
  @override
  Map<String, double> build() => const <String, double>{};

  double? aspectRatioFor({
    required String comicId,
    required int pageIndexZeroBased,
  }) {
    return state[readerPageAspectRatioKey(comicId, pageIndexZeroBased)];
  }

  void remember({
    required String comicId,
    required int pageIndexZeroBased,
    required double width,
    required double height,
  }) {
    if (width <= 0 || height <= 0) {
      return;
    }
    final String key = readerPageAspectRatioKey(comicId, pageIndexZeroBased);
    final double next = width / height;
    if (state[key] == next) {
      return;
    }
    state = <String, double>{...state, key: next};
  }

  void clearComic(String comicId) {
    final String prefix = '$comicId:';
    if (!state.keys.any((String key) => key.startsWith(prefix))) {
      return;
    }
    state = Map<String, double>.fromEntries(
      state.entries.where(
        (MapEntry<String, double> entry) => !entry.key.startsWith(prefix),
      ),
    );
  }
}
