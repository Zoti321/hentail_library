import 'package:hentai_library/features/reader/application/open_reader_args.dart';
import 'package:hentai_library/features/reader/presentation/routing/reader_route_args.dart';
import 'package:hentai_library/shared/di/app_router_provider.dart';
import 'package:hentai_library/shared/domain/ports/reader_launch_port.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReaderLaunchPortAdapter implements ReaderLaunchPort {
  ReaderLaunchPortAdapter(this._ref);

  final Ref _ref;

  @override
  Future<void> openComic({
    required String comicId,
    bool incognito = false,
    bool keepControlsOpen = false,
    bool startFromFirstPage = false,
  }) async {
    final OpenReaderArgs session = OpenReaderArgs(
      comicId: comicId,
      incognito: incognito,
      keepControlsOpen: keepControlsOpen,
      startFromFirstPage: startFromFirstPage,
    );
    _ref
        .read(appRouterProvider)
        .pushNamed(
          ReaderRouteArgs.readerRouteName,
          queryParameters: ReaderRouteArgs.fromSession(session)
              .toQueryParameters(),
        );
  }
}

ReaderLaunchPort createReaderLaunchPort(Ref ref) =>
    ReaderLaunchPortAdapter(ref);
