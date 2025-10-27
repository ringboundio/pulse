import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Verifies paint cache invalidates bundles only on sheet revision changes.
  test('ChartPaintCache reuses bundles until revision changes', () {
    final ChartStyleKey styleKey = ChartStyleKey('grid');
    final ChartPaintStyle style = ChartPaintStyle(
      strokeColor: const Color(0xFF99A2B0),
      strokeWidth: 1.0,
      strokeCap: StrokeCap.square,
      strokeJoin: StrokeJoin.miter,
      dashPattern: Float64List(0),
      fillColor: const Color(0x00000000),
    );
    final ChartStyleSheet sheet = ChartStyleSheet(5, <ChartStyleEntry>[
      ChartStyleEntry(styleKey, style),
    ]);

    final ChartPaintCache cache = ChartPaintCache();
    final ChartPaintBundle first = cache.resolve(sheet, styleKey);
    final ChartPaintBundle second = cache.resolve(sheet, styleKey);
    expect(identical(first, second), isTrue);

    final ChartStyleSheet updatedSheet = sheet.override(
      key: styleKey,
      style: ChartPaintStyle(
        strokeColor: const Color(0xFF111111),
        strokeWidth: 1.5,
        strokeCap: StrokeCap.square,
        strokeJoin: StrokeJoin.miter,
        dashPattern: Float64List(0),
        fillColor: const Color(0x00000000),
      ),
    );
    final ChartPaintBundle third = cache.resolve(updatedSheet, styleKey);
    expect(identical(first, third), isFalse);
  });
}
