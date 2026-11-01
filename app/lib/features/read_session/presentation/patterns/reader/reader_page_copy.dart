/// Lab 阅读页文案（尚未进 ARB）。
abstract final class Md3eReaderPageCopy {
  static String viewportPlaceholder(int page) => '第 $page 页 · 预览画布';

  static const String viewportLoading = '正在打开…';
  static const String viewportErrorMessage = '无法打开此会话，请稍后重试。';
  static const String viewportErrorBack = '返回详情';
  static const String viewportErrorRetry = '重试';

  static String pageProgressLabel(int current, int total) =>
      '$current / $total';
}
