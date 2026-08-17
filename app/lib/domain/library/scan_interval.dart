/// Per-Library Scan interval (Komga-aligned presets).
enum ScanInterval { disabled, hourly, every6Hours, every12Hours, daily, weekly }

extension ScanIntervalX on ScanInterval {
  Duration? get period {
    return switch (this) {
      ScanInterval.disabled => null,
      ScanInterval.hourly => const Duration(hours: 1),
      ScanInterval.every6Hours => const Duration(hours: 6),
      ScanInterval.every12Hours => const Duration(hours: 12),
      ScanInterval.daily => const Duration(days: 1),
      ScanInterval.weekly => const Duration(days: 7),
    };
  }
}
