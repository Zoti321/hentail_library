import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/catalog_selection_notifier.dart';
import 'package:hentai_library/shared/domain/ports/catalog_selection_command_port.dart';

class _CatalogSelectionCommandAdapter implements CatalogSelectionCommandPort {
  _CatalogSelectionCommandAdapter(this._ref);

  final Ref _ref;

  @override
  void exit() => _ref.read(catalogSelectionProvider.notifier).exit();
}

/// 适配器工厂：由 bootstrap 通过 `shared/di` 的端口 Provider `overrideWith` 注入（#267）。
CatalogSelectionCommandPort createCatalogSelectionCommandPort(Ref ref) =>
    _CatalogSelectionCommandAdapter(ref);
