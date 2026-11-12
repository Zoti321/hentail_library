import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';
import 'package:hentai_library/shared/ui/contracts/author_detail_commands.dart';

final Provider<OpenAuthorByIdCommand> openAuthorByIdCommandProvider =
    requiredProvider('openAuthorByIdCommandProvider');
final Provider<OpenAuthorByNameCommand> openAuthorByNameCommandProvider =
    requiredProvider('openAuthorByNameCommandProvider');
