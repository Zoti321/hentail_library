import 'package:flutter/material.dart';

/// 库浏览 ↔ 详情、系列 ↔ 漫画详情的封面 Hero（对齐 Kazumi 共享封面飞入）。
abstract final class CatalogCoverHero {
  static Object comicTag(String comicId) => 'comic-cover:$comicId';

  static Object seriesTag(String seriesId) => 'series-cover:$seriesId';

  /// 与 Kazumi [NetworkImgLayer.heroFlightShuttleBuilder] 对齐：飞行中沿用
  /// 起/终点一侧的 child，并捕获 InheritedTheme，避免主题跳变。
  ///
  /// push 用列表侧封面（通常已解码），减轻详情侧换尺寸重解码时的闪烁。
  static Widget flightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final Hero fromHero = fromHeroContext.widget as Hero;
    final Hero toHero = toHeroContext.widget as Hero;
    final BuildContext heroContext = flightDirection == HeroFlightDirection.push
        ? fromHeroContext
        : toHeroContext;
    final Hero hero = flightDirection == HeroFlightDirection.push
        ? fromHero
        : toHero;

    return InheritedTheme.captureAll(
      heroContext,
      Material(type: MaterialType.transparency, child: hero.child),
    );
  }

  static Widget wrap({
    required Object tag,
    required Widget child,
    bool enabled = true,
  }) {
    if (!enabled) {
      return child;
    }
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      flightShuttleBuilder: flightShuttleBuilder,
      child: child,
    );
  }
}
