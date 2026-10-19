import 'package:json_annotation/json_annotation.dart';

/// App-level Auto-play mode preference (not a Read session mode).
///
/// Controls what happens after a full interval dwell on the last spread.
@JsonEnum(alwaysCreate: true)
enum AutoPlayMode {
  /// Stop autoplay after the last spread.
  @JsonValue('comicOnce')
  comicOnce,

  /// Jump to page 1 and keep autoplay.
  @JsonValue('comicLoop')
  comicLoop,

  /// Advance to the next Series volume when available; otherwise stop.
  /// Without Series reading context, behaves like [comicOnce].
  @JsonValue('seriesOnce')
  seriesOnce,

  /// Advance to the next volume, or the first volume when on the last;
  /// keep autoplay. Without Series reading context, behaves like [comicLoop].
  @JsonValue('seriesLoop')
  seriesLoop,
}

const AutoPlayMode kDefaultAutoPlayMode = AutoPlayMode.comicOnce;

const Map<AutoPlayMode, String> _$AutoPlayModeEnumMap = <AutoPlayMode, String>{
  AutoPlayMode.comicOnce: 'comicOnce',
  AutoPlayMode.comicLoop: 'comicLoop',
  AutoPlayMode.seriesOnce: 'seriesOnce',
  AutoPlayMode.seriesLoop: 'seriesLoop',
};

AutoPlayMode autoPlayModeFromJson(Object? json) {
  if (json is String) {
    for (final MapEntry<AutoPlayMode, String> entry
        in _$AutoPlayModeEnumMap.entries) {
      if (entry.value == json) {
        return entry.key;
      }
    }
  }
  return kDefaultAutoPlayMode;
}

String autoPlayModeToJson(AutoPlayMode mode) => _$AutoPlayModeEnumMap[mode]!;
