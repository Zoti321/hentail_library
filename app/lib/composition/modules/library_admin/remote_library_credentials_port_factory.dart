import 'package:hentai_library/features/library_admin/infrastructure/adapters/remote_credentials_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/library_admin/domain/remote_library_credentials_port.dart';

RemoteLibraryCredentialsPort createRemoteLibraryCredentialsPort(
  LibraryRepository libraryRepository,
) => RemoteLibraryCredentialsFrbAdapter(libraryRepository);
