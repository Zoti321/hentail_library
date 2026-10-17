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
}
