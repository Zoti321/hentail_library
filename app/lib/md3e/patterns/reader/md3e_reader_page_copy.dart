/// Lab 阅读页文案（尚未进 ARB）。
abstract final class Md3eReaderPageCopy {
  static String viewportPlaceholder(int page) => '第 $page 页 · 预览画布';

  static String pageProgressLabel(int current, int total) =>
      '$current / $total';
}
