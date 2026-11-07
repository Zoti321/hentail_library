class LibraryChange {
  const LibraryChange({
    this.tagsWritten = false,
    this.authorsWritten = false,
    this.parodiesWritten = false,
    this.charactersWritten = false,
    this.metadataSaved = false,
  });

  final bool tagsWritten;
  final bool authorsWritten;
  final bool parodiesWritten;
  final bool charactersWritten;

  final bool metadataSaved;

  bool get dictionariesWritten =>
      tagsWritten || authorsWritten || parodiesWritten || charactersWritten;

  bool get isEmpty => !dictionariesWritten && !metadataSaved;

  LibraryChange merge(LibraryChange other) {
    return LibraryChange(
      tagsWritten: tagsWritten || other.tagsWritten,
      authorsWritten: authorsWritten || other.authorsWritten,
      parodiesWritten: parodiesWritten || other.parodiesWritten,
      charactersWritten: charactersWritten || other.charactersWritten,
      metadataSaved: metadataSaved || other.metadataSaved,
    );
  }
}
