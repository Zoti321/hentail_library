import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/entity/sync_report/scanned_item_report.dart';

part 'sync_report.freezed.dart';

/// 扫描完成报告。
@freezed
abstract class SyncReport with _$SyncReport {
  const factory SyncReport({
    required List<ScannedItemReport> scannedItems,
    required int addedCount,
    required int removedCount,
    @Default(false) bool cancelled,
  }) = _SyncReport;
}
