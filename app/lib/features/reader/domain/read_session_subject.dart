/// Session display header shared by Comic and Image set Read sessions.
///
/// [sessionKey] is opaque cache / ViewModel identity from [ReadSessionSource].
/// Do not treat it as a Comic id for Image set sessions.
final class ReadSessionSubject {
  const ReadSessionSubject({
    required this.sessionKey,
    required this.title,
    required this.pageCount,
  });

  final String sessionKey;
  final String title;
  final int pageCount;
}
