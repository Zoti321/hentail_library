typedef AppReleaseAsset = ({String name, String downloadUrl, int size});

typedef AppReleaseInfo = ({
  String version,
  DateTime publishedAt,
  List<String> releaseNotes,
  String htmlUrl,
  List<AppReleaseAsset> assets,
});
