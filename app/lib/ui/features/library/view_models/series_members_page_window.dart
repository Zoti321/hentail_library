/// 全量成员数对应的浏览态总页数（#121）。
int seriesMembersTotalPages({required int totalCount, required int pageSize}) {
  if (totalCount <= 0 || pageSize <= 0) {
    return 1;
  }
  return (totalCount + pageSize - 1) ~/ pageSize;
}
