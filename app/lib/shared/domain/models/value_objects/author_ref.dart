/// 跨模块的 Author **引用投影**（ADR-0034 §6 / ADR-0024）。
///
/// `id` 是 Author 稳定身份；`name` 是当前显示名的只读投影，**不是**关联对象。
/// `id == null` 表示"仅有名字"的中间态（扫描结果 / 用户新输入），不可作为引用传播。
///
/// 消费方只读本类型，需要完整 Author（外链、认证态、形象）时走
/// `shared/presentation/providers/author_detail_providers.dart` 或 comic_metadata 的字典 Provider。
class AuthorRef {
  const AuthorRef({this.id, required this.name});

  /// 仅名字构造（无稳定身份）。
  const AuthorRef.byName(this.name) : id = null;

  final int? id;
  final String name;

  /// 有稳定身份时可直接跳到 Author 详情；否则需按名解析。
  bool get hasIdentity => id != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthorRef && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'AuthorRef($id, $name)';
}
