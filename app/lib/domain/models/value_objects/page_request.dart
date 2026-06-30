/// 默认漫画库分页大小（设置 UI 未开放前由接口层使用）。
const int kDefaultPageSize = 50;

/// 分页请求（[page] 从 1 开始）。
class PageRequest {
  const PageRequest({this.page = 1, this.pageSize = kDefaultPageSize})
    : assert(page >= 1),
      assert(pageSize >= 1);

  final int page;
  final int pageSize;

  int get offset => (page - 1) * pageSize;
}
