/// 系列连载状态（用户可编辑；sync 不覆盖）。
enum SerializationStatus {
  unknown,
  ongoing,
  ended,
  hiatus;

  static SerializationStatus fromRust(String raw) {
    return switch (raw) {
      'ongoing' => SerializationStatus.ongoing,
      'ended' => SerializationStatus.ended,
      'hiatus' => SerializationStatus.hiatus,
      _ => SerializationStatus.unknown,
    };
  }

  String toRust() => name;
}
