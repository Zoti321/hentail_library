/// Per Local Image set library opt-in gates (ADR-0064).
class ImageSetLibraryGates {
  const ImageSetLibraryGates({
    required this.resourceMutation,
    required this.managedLayout,
  });

  final bool resourceMutation;
  final bool managedLayout;
}
