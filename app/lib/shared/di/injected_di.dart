import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show FutureProviderFamily;

/// 由 bootstrap override 注入的 DI token 构造器（ADR-0034 §3）。
///
/// `shared/di` 只声明 token，不持有实现；默认抛 [UnimplementedError]，
/// 由 `features/bootstrap/di/**` 或 owner `public/di/**` 通过 `overrideWith*` 填实。
///
/// 新增 token 必须同步补 override，否则
/// `test/gate/shared_di_override_coverage_test.dart` 会失败。
Never _missing(String name) =>
    throw UnimplementedError('$name 未注入，请在 bootstrap 中 override');

/// 同步单例 token。
Provider<T> injectedDi<T>(String name) =>
    Provider<T>((Ref ref) => _missing(name));

/// 异步单例 token。
FutureProvider<T> injectedFutureDi<T>(String name) =>
    FutureProvider<T>((Ref ref) => _missing(name));

/// 带参数（family）异步 token。
FutureProviderFamily<T, P> injectedFutureDiFamily<T, P>(String name) =>
    FutureProvider.family<T, P>((Ref ref, P arg) => _missing(name));
