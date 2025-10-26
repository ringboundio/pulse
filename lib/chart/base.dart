import 'dart:typed_data';
import 'dart:ui';

import 'style.dart';

class ChartLayerKey {
  const ChartLayerKey(this.value);

  final String value;

  @override
  bool operator ==(Object other) {
    if (other is! ChartLayerKey) {
      return false;
    }
    return other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

class ChartNodeKey {
  const ChartNodeKey(this.value);

  final String value;

  @override
  bool operator ==(Object other) {
    if (other is! ChartNodeKey) {
      return false;
    }
    return other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

class ChartTransform {
  const ChartTransform(
    this.scaleX,
    this.translateX,
    this.scaleY,
    this.translateY,
    this.height,
  );

  final double scaleX;
  final double translateX;
  final double scaleY;
  final double translateY;
  final double height;

  double projectX(double domain) {
    return (domain * scaleX) + translateX;
  }

  double projectY(double measure) {
    final double raw = (measure * scaleY) + translateY;
    return height - raw;
  }

  Offset project(double domain, double measure) {
    return Offset(projectX(domain), projectY(measure));
  }
}

class ChartScratchSpace {
  ChartScratchSpace()
    : primaryPath = Path(),
      secondaryPath = Path(),
      rect = Rect.zero;

  final Path primaryPath;
  final Path secondaryPath;
  Rect rect;

  void reset() {
    primaryPath.reset();
    secondaryPath.reset();
    rect = Rect.zero;
  }
}

class ChartRenderContext {
  ChartRenderContext(
    this.canvas,
    this.size,
    this.transform,
    this.styleSheet,
    this.paintCache,
    this.devicePixelRatio,
    this.scratchSpace,
  );

  final Canvas canvas;
  final Size size;
  final ChartTransform transform;
  final ChartStyleSheet styleSheet;
  final ChartPaintCache paintCache;
  final double devicePixelRatio;
  final ChartScratchSpace scratchSpace;
}

class ChartPaintBundle {
  ChartPaintBundle(this.stroke, this.fill, this.dashPattern);

  final Paint stroke;
  final Paint fill;
  final Float64List dashPattern;

  factory ChartPaintBundle.fromStyle(ChartPaintStyle style) {
    final Paint strokePaint = Paint();
    strokePaint.color = style.strokeColor;
    strokePaint.strokeWidth = style.strokeWidth;
    strokePaint.strokeCap = style.strokeCap;
    strokePaint.strokeJoin = style.strokeJoin;
    strokePaint.style = PaintingStyle.stroke;
    strokePaint.isAntiAlias = true;

    final Paint fillPaint = Paint();
    fillPaint.color = style.fillColor;
    fillPaint.style = PaintingStyle.fill;
    fillPaint.isAntiAlias = true;

    final int dashLength = style.dashPattern.length;
    final Float64List dashPattern = Float64List(dashLength);
    for (int i = 0; i < dashLength; i += 1) {
      dashPattern[i] = style.dashPattern[i];
    }

    return ChartPaintBundle(strokePaint, fillPaint, dashPattern);
  }
}

class ChartPaintCacheEntry {
  ChartPaintCacheEntry(this.key, this.bundle);

  final ChartStyleKey key;
  final ChartPaintBundle bundle;
}

class ChartPaintCache {
  ChartPaintCache() : _revision = -1, _entries = <ChartPaintCacheEntry>[];

  final List<ChartPaintCacheEntry> _entries;
  int _revision;

  ChartPaintBundle resolve(ChartStyleSheet sheet, ChartStyleKey key) {
    if (_revision != sheet.revision) {
      _revision = sheet.revision;
      _entries.clear();
    }
    for (final ChartPaintCacheEntry entry in _entries) {
      if (entry.key == key) {
        return entry.bundle;
      }
    }
    final ChartPaintStyle style = sheet.resolve(key);
    final ChartPaintBundle bundle = ChartPaintBundle.fromStyle(style);
    _entries.add(ChartPaintCacheEntry(key, bundle));
    return bundle;
  }
}

abstract class ChartNode {
  ChartNode(this.key, this.styleKey);

  final ChartNodeKey key;
  final ChartStyleKey styleKey;
}

abstract class ChartLayer {
  ChartLayer(this.key);

  final ChartLayerKey key;

  void paint(ChartRenderContext context);
}
