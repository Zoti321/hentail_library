import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';

PageLayoutSpec _resolve(double width, LayoutInputMode mode) {
  return PageLayoutSpec.resolve(
    LayoutContext(viewportWidth: width, inputMode: mode),
  );
}

const double _compactWidth = 390;
const double _mediumWidth = 700;
const double _expandedWidth = 1024;
const double _largeWidth = 1200; // below the 1280 content cap
const double _extraLargeWidth = 1920;

final List<WindowSizeClass> _allClasses = WindowSizeClass.values;

void main() {
  group('LayoutContext', () {
    test('fromPlatform maps desktop to pointer and mobile to touch', () {
      expect(
        LayoutContext.fromPlatform(viewportWidth: 800, desktop: true).inputMode,
        LayoutInputMode.pointer,
      );
      expect(
        LayoutContext.fromPlatform(
          viewportWidth: 800,
          desktop: false,
        ).inputMode,
        LayoutInputMode.touch,
      );
    });

    test('sizeClass follows the shared breakpoints', () {
      expect(
        const LayoutContext(
          viewportWidth: Breakpoints.medium - 1,
          inputMode: LayoutInputMode.touch,
        ).sizeClass,
        WindowSizeClass.compact,
      );
      expect(
        const LayoutContext(
          viewportWidth: Breakpoints.extraLarge,
          inputMode: LayoutInputMode.touch,
        ).sizeClass,
        WindowSizeClass.extraLarge,
      );
    });
  });

  group('horizontalInset (touch)', () {
    final LayoutInputMode mode = LayoutInputMode.touch;

    test('uses per-class margins below the content cap', () {
      expect(_resolve(_compactWidth, mode).horizontalInset, 16);
      expect(_resolve(_mediumWidth, mode).horizontalInset, 24);
      expect(_resolve(_expandedWidth, mode).horizontalInset, 32);
      expect(_resolve(_largeWidth, mode).horizontalInset, 40);
    });

    test('centres content beyond the 1280 cap on extra-large windows', () {
      // margin 40, padded 1920 - 80 = 1840, cap 1280 → inset 40 + 280.
      expect(_resolve(_extraLargeWidth, mode).horizontalInset, 320);
    });
  });

  group('horizontalInset (pointer)', () {
    final LayoutInputMode mode = LayoutInputMode.pointer;

    test('is tighter than touch in every class', () {
      expect(_resolve(_compactWidth, mode).horizontalInset, 16);
      expect(_resolve(_mediumWidth, mode).horizontalInset, 20);
      expect(_resolve(_expandedWidth, mode).horizontalInset, 24);
      expect(_resolve(_largeWidth, mode).horizontalInset, 32);
    });

    test('caps and centres content on extra-large windows', () {
      // margin 32, padded 1920 - 64 = 1856, cap 1280 → inset 32 + 288.
      expect(_resolve(_extraLargeWidth, mode).horizontalInset, 320);
    });
  });

  group('header and body spacing', () {
    test('pinned header vertical inset is 12 on touch and 8 on pointer', () {
      expect(
        _resolve(_expandedWidth, LayoutInputMode.touch).headerVerticalInset,
        12,
      );
      expect(
        _resolve(_expandedWidth, LayoutInputMode.pointer).headerVerticalInset,
        8,
      );
    });

    test('header-to-body gap grows with class on touch', () {
      expect(
        _resolve(_compactWidth, LayoutInputMode.touch).headerToBodyGap,
        16,
      );
      expect(_resolve(_mediumWidth, LayoutInputMode.touch).headerToBodyGap, 20);
      expect(
        _resolve(_expandedWidth, LayoutInputMode.touch).headerToBodyGap,
        24,
      );
    });

    test('header-to-body gap is tighter on pointer', () {
      expect(
        _resolve(_compactWidth, LayoutInputMode.pointer).headerToBodyGap,
        12,
      );
      expect(
        _resolve(_expandedWidth, LayoutInputMode.pointer).headerToBodyGap,
        16,
      );
    });

    test('pinned header extent is vertical insets plus toolbar row', () {
      final PageLayoutSpec touch = _resolve(
        _expandedWidth,
        LayoutInputMode.touch,
      );
      final PageLayoutSpec pointer = _resolve(
        _expandedWidth,
        LayoutInputMode.pointer,
      );
      expect(
        touch.pinnedHeaderExtent,
        12 * 2 + PageLayoutSpec.toolbarRowHeight,
      );
      expect(
        pointer.pinnedHeaderExtent,
        8 * 2 + PageLayoutSpec.toolbarRowHeight,
      );
    });
  });

  group('list and state spacing', () {
    test('list item gap is roomier on touch than pointer', () {
      expect(_resolve(_compactWidth, LayoutInputMode.touch).listItemGap, 12);
      expect(_resolve(_expandedWidth, LayoutInputMode.touch).listItemGap, 16);
      for (final double width in <double>[
        _compactWidth,
        _mediumWidth,
        _expandedWidth,
        _largeWidth,
        _extraLargeWidth,
      ]) {
        expect(_resolve(width, LayoutInputMode.pointer).listItemGap, 8);
      }
    });

    test('state top inset is 48 on touch and 32 on pointer', () {
      for (final WindowSizeClass cls in _allClasses) {
        final double width = _widthFor(cls);
        expect(_resolve(width, LayoutInputMode.touch).stateTopInset, 48);
        expect(_resolve(width, LayoutInputMode.pointer).stateTopInset, 32);
      }
    });
  });

  group('title typography', () {
    test('font size follows window class and is shared across inputs', () {
      for (final LayoutInputMode mode in LayoutInputMode.values) {
        expect(_resolve(_compactWidth, mode).titleFontSize, 24);
        expect(_resolve(_mediumWidth, mode).titleFontSize, 24);
        expect(_resolve(_expandedWidth, mode).titleFontSize, 28);
        expect(_resolve(_largeWidth, mode).titleFontSize, 32);
        expect(_resolve(_extraLargeWidth, mode).titleFontSize, 32);
      }
    });

    test('weight is bold only on compact', () {
      expect(
        _resolve(_compactWidth, LayoutInputMode.touch).titleFontWeight,
        FontWeight.w700,
      );
      expect(
        _resolve(_mediumWidth, LayoutInputMode.touch).titleFontWeight,
        FontWeight.w600,
      );
    });
  });

  group('invariants across all size classes', () {
    final List<double> widths = <double>[
      _compactWidth,
      _mediumWidth,
      _expandedWidth,
      _largeWidth,
      _extraLargeWidth,
    ];

    test('pointer spacing never exceeds touch spacing', () {
      for (final double width in widths) {
        final PageLayoutSpec touch = _resolve(width, LayoutInputMode.touch);
        final PageLayoutSpec pointer = _resolve(width, LayoutInputMode.pointer);
        expect(
          pointer.horizontalInset,
          lessThanOrEqualTo(touch.horizontalInset),
        );
        expect(
          pointer.headerVerticalInset,
          lessThanOrEqualTo(touch.headerVerticalInset),
        );
        expect(
          pointer.headerToBodyGap,
          lessThanOrEqualTo(touch.headerToBodyGap),
        );
        expect(
          pointer.bodyBottomInset,
          lessThanOrEqualTo(touch.bodyBottomInset),
        );
        expect(pointer.listItemGap, lessThanOrEqualTo(touch.listItemGap));
        expect(pointer.stateTopInset, lessThanOrEqualTo(touch.stateTopInset));
      }
    });

    test('margins and gaps never shrink as the window grows', () {
      for (final LayoutInputMode mode in LayoutInputMode.values) {
        double? previousGap;
        for (final WindowSizeClass cls in _allClasses) {
          final double width = _widthFor(cls);
          final PageLayoutSpec spec = _resolve(width, mode);
          if (previousGap != null) {
            expect(spec.headerToBodyGap, greaterThanOrEqualTo(previousGap));
          }
          previousGap = spec.headerToBodyGap;
        }
      }
    });

    test('resolve is pure: same inputs give equal specs', () {
      final PageLayoutSpec a = _resolve(
        _expandedWidth,
        LayoutInputMode.pointer,
      );
      final PageLayoutSpec b = _resolve(
        _expandedWidth,
        LayoutInputMode.pointer,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}

double _widthFor(WindowSizeClass cls) {
  return switch (cls) {
    WindowSizeClass.compact => _compactWidth,
    WindowSizeClass.medium => _mediumWidth,
    WindowSizeClass.expanded => _expandedWidth,
    WindowSizeClass.large => _largeWidth,
    WindowSizeClass.extraLarge => _extraLargeWidth,
  };
}
