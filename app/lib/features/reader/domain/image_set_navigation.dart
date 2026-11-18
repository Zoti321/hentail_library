/// One non-empty Image set reachable by cross–Image set navigation.
class ImageSetNavItem {
  const ImageSetNavItem({required this.imageSetId, required this.title});

  final String imageSetId;
  final String title;
}

/// Non-empty Image sets of one library in Image set catalog order around the
/// current set. Previous/next stop at the ends (no wrap).
class ImageSetNavigation {
  const ImageSetNavigation({required this.items, required this.currentIndex});

  factory ImageSetNavigation.around(
    List<ImageSetNavItem> items,
    String currentImageSetId,
  ) => ImageSetNavigation(
    items: List<ImageSetNavItem>.unmodifiable(items),
    currentIndex: items.indexWhere(
      (ImageSetNavItem item) => item.imageSetId == currentImageSetId,
    ),
  );

  final List<ImageSetNavItem> items;

  /// `-1` when the current set is no longer in the catalog.
  final int currentIndex;

  bool get hasPrevious => currentIndex > 0;

  bool get hasNext => currentIndex >= 0 && currentIndex < items.length - 1;

  ImageSetNavItem? get previous => hasPrevious ? items[currentIndex - 1] : null;

  ImageSetNavItem? get next => hasNext ? items[currentIndex + 1] : null;

  bool contains(String imageSetId) =>
      items.any((ImageSetNavItem item) => item.imageSetId == imageSetId);
}
