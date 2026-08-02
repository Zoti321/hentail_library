typedef RefreshSeriesProgress = ({
  int current,
  int total,
  String? comicId,
  int succeeded,
  int failed,
});

typedef RefreshSeriesResult = ({
  int succeeded,
  int failed,
});
