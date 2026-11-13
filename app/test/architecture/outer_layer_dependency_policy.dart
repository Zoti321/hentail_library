bool allowsOuterLayerDependency(String source, String target) {
  final presentation =
      source.contains('/presentation/') ||
      source.startsWith('shared/ui/') ||
      source.startsWith('design-system/');
  final infrastructure =
      source.startsWith('infrastructure/') ||
      source.contains('/infrastructure/');
  return !((target.startsWith('composition/') &&
          source != 'main.dart' &&
          !source.startsWith('composition/')) ||
      (presentation &&
          (target.startsWith('infrastructure/') ||
              target.contains('/infrastructure/') ||
              target.startsWith('src/'))) ||
      (infrastructure &&
          (target.contains('/presentation/') ||
              target.startsWith('shared/ui/') ||
              target.startsWith('design-system/'))) ||
      (source.startsWith('infrastructure/') &&
          target.startsWith('features/')) ||
      (source.startsWith('shared/') && target.startsWith('infrastructure/')));
}
