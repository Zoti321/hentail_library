import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/ui/contracts/author_detail_commands.dart';

final Provider<OpenAuthorByIdCommand> openAuthorByIdCommandProvider =
    injectedDi('openAuthorByIdCommandProvider');
final Provider<OpenAuthorByNameCommand> openAuthorByNameCommandProvider =
    injectedDi('openAuthorByNameCommandProvider');
