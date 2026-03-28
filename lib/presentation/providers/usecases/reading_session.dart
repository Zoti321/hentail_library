import 'package:hentai_library/domain/usecases/usecases.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reading_session.g.dart';

@Riverpod(keepAlive: true)
RecordReadingSessionUseCase recordReadingSessionUseCase(Ref ref) {
  return RecordReadingSessionUseCase(ref.read(readingSessionRepoProvider));
}
