/// 默认漫画库分页大小（设置 UI 未开放前由接口层使用）。
const int kDefaultPageSize = 50;

/// 分页请求（[page] 从 1 开始）。
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
