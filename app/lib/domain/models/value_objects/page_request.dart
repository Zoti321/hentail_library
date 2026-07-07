/// ????????? UI ??????????????
const int kDefaultPageSize = 50;

/// [page] ? 1 ???
typedef PageRequest = ({int page, int pageSize});

extension PageRequestOps on PageRequest {
  int get offset {
    assert(page >= 1);
    assert(pageSize >= 1);
    return (page - 1) * pageSize;
  }
}

PageRequest pageRequest({int page = 1, int pageSize = kDefaultPageSize}) {
  assert(page >= 1);
  assert(pageSize >= 1);
  return (page: page, pageSize: pageSize);
}
