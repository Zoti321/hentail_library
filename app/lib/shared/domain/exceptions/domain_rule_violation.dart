/// 违反领域不变式时抛出；纯 Dart，不含 UI / 基础设施依赖。
///
/// 应用层捕获后可映射为 [ValidationException] 等面向用户的异常。
class DomainRuleViolation implements Exception {
  const DomainRuleViolation(this.message, {this.code});

  final String message;

  /// 稳定标识，便于测试与日志分类。
  final String? code;

  @override
  String toString() =>
      'DomainRuleViolation${code != null ? '($code)' : ''}: $message';
}
