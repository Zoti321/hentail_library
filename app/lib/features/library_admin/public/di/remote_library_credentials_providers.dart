import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/features/library_admin/domain/remote_library_credentials_port.dart';

final Provider<RemoteLibraryCredentialsPort>
remoteLibraryCredentialsPortProvider = injectedDi(
  'remoteLibraryCredentialsPortProvider',
);
