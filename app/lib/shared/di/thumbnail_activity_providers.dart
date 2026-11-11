import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';

/// 后台缩略图队列是否活跃（#512）。
///
/// 消费方是 library_admin 与 home，投影方是 comic；两侧归属都会制造禁止边或
/// public 环，因此 token 留 shared（ADR-0045 可达性豁免）。
final Provider<bool> thumbnailBackgroundActiveStateProvider = injectedDi(
  'thumbnailBackgroundActiveStateProvider',
);
