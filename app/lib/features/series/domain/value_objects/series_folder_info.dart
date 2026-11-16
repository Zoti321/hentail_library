import 'package:freezed_annotation/freezed_annotation.dart';

part 'series_folder_info.freezed.dart';

@freezed
abstract class SeriesFolderInfo with _$SeriesFolderInfo {
  const factory SeriesFolderInfo({required String folderPath}) =
      _SeriesFolderInfo;
}
