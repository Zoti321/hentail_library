import 'package:hentai_library/features/read_session/domain/read_session.dart';
import 'package:hentai_library/features/read_session/presentation/routing/reader_route_args.dart';
import 'package:hentai_library/shared/di/app_router_provider.dart';
import 'package:hentai_library/shared/domain/ports/read_session_launch_port.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadSessionLaunchPortAdapter implements ReadSessionLaunchPort {
  ReadSessionLaunchPortAdapter(this._ref);

  final Ref _ref;

  @override
  Future<void> openComic({
    required String comicId,
    bool incognito = false,
    bool keepControlsOpen = false,
    bool startFromFirstPage = false,
  }) async {
    final ReadSessionRouteParams session = ReadSessionRouteParams(
      comicId: comicId,
      incognito: incognito,
      keepControlsOpen: keepControlsOpen,
      startFromFirstPage: startFromFirstPage,
    );
    _ref
        .read(appRouterProvider)
        .pushNamed(
          ReaderRouteArgs.readerRouteName,
          queryParameters: ReaderRouteArgs.fromSession(
            session,
          ).toQueryParameters(),
        );
  }
}

ReadSessionLaunchPort createReadSessionLaunchPort(Ref ref) =>
    ReadSessionLaunchPortAdapter(ref);
