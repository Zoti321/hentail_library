import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:riverpod/misc.dart' show FutureProviderFamily;

final FutureProviderFamily<int, String> comicResolvedPageCountProvider =
    injectedFutureDiFamily('comicResolvedPageCountProvider');
