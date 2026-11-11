import 'package:hentai_library/shared/di/app_navigator_provider.dart';
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
    _ref
        .read(appNavigatorProvider)
        .openReader(
          comicId: comicId,
          incognito: incognito,
          keepControlsOpen: keepControlsOpen,
          startFromFirstPage: startFromFirstPage,
        );
  }
}

ReaderLaunchPort createReaderLaunchPort(Ref ref) =>
    ReaderLaunchPortAdapter(ref);
