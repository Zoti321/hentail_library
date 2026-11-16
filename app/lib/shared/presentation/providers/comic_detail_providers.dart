import 'package:hentai_library/shared/presentation/providers/required_provider.dart';
import 'package:riverpod/misc.dart' show FutureProviderFamily;

final FutureProviderFamily<int, String> comicResolvedPageCountProvider =
    requiredFutureProviderFamily('comicResolvedPageCountProvider');
