part of 'theme.dart';

@immutable
class AppTextTokens {
  final double labelXs;
  final double bodySm;
  final double bodyMd;
  final double bodyLg;
  final double titleSm;
  final double titleMd;
  final double titleLg;

  const AppTextTokens({
    required this.labelXs,
    required this.bodySm,
    required this.bodyMd,
    required this.bodyLg,
    required this.titleSm,
    required this.titleMd,
    required this.titleLg,
  });

  AppTextTokens lerp(AppTextTokens other, double t) {
    return AppTextTokens(
      labelXs: _lerpDouble(labelXs, other.labelXs, t),
      bodySm: _lerpDouble(bodySm, other.bodySm, t),
      bodyMd: _lerpDouble(bodyMd, other.bodyMd, t),
      bodyLg: _lerpDouble(bodyLg, other.bodyLg, t),
      titleSm: _lerpDouble(titleSm, other.titleSm, t),
      titleMd: _lerpDouble(titleMd, other.titleMd, t),
      titleLg: _lerpDouble(titleLg, other.titleLg, t),
    );
  }
}
