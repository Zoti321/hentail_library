import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/shared/domain/ports/catalog_selection_command_port.dart';

class _CatalogSelectionCommandAdapter implements CatalogSelectionCommandPort {
  _CatalogSelectionCommandAdapter(this._ref);

  final Ref _ref;

  @override
  void exit() => _ref.read(catalogSelectionProvider.notifier).exit();
}

CatalogSelectionCommandPort createCatalogSelectionCommandPort(Ref ref) =>
    _CatalogSelectionCommandAdapter(ref);
