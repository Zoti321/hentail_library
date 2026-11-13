import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/application/contracts/cover_commands.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<ComicCoverSetCommand> setComicCoverFromPageCommandProvider =
    requiredProvider('setComicCoverFromPageCommandProvider');
final Provider<SeriesCoverSetCommand> setSeriesCoverFromPageCommandProvider =
    requiredProvider('setSeriesCoverFromPageCommandProvider');
