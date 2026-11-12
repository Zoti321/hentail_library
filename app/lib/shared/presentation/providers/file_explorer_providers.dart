import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/application/contracts/file_explorer.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

final Provider<FileExplorerCommand> showInFileExplorerProvider =
    requiredProvider('showInFileExplorerProvider');

final Provider<FileExplorerCommand> openDirectoryInFileExplorerProvider =
    requiredProvider('openDirectoryInFileExplorerProvider');
