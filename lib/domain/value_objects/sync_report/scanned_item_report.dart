import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/enums/enums.dart';

part 'scanned_item_report.freezed.dart';

/// 单条扫描结果，用于报告。
@freezed
abstract class ScannedItemReport with _$ScannedItemReport {
  const factory ScannedItemReport({
    required String path,
    required ScannedItemType type,
    int? pageCount,
    String? title,
  }) = _ScannedItemReport;
}
