import 'dart:typed_data';
import 'dart:ui';

import 'package:pulse/chart/style.dart';

typedef ChartPathPainter = void Function(Canvas canvas, Path path);

void _noopPathPainter(Canvas canvas, Path path) {}

ChartPathPainter _strokePainterFor(Paint stroke) {
  if (stroke.strokeWidth <= 0.0 || stroke.color.a == 0.0) {
    return _noopPathPainter;
  }
  return (Canvas canvas, Path path) => canvas.drawPath(path, stroke);
}

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
  const ChartTransform({
    required this.scaleX,
    required this.translateX,
    required this.scaleY,
    required this.translateY,
    required this.height,
  });

  final double scaleX;
  final double translateX;
  final double scaleY;
  final double translateY;
  final double height;

  int get cacheKey =>
      Object.hash(scaleX, translateX, scaleY, translateY, height);

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
  ChartRenderContext({
    required this.canvas,
    required this.size,
    required this.transform,
    required this.styleSheet,
    required this.paintCache,
    required this.devicePixelRatio,
    required this.scratchSpace,
  });

  final Canvas canvas;
  final Size size;
  final ChartTransform transform;
  final ChartStyleSheet styleSheet;
  final ChartPaintCache paintCache;
  final double devicePixelRatio;
  final ChartScratchSpace scratchSpace;
}

class ChartPaintBundle {
  ChartPaintBundle({
    required this.stroke,
    required this.fill,
    required this.dashPattern,
    required ChartPathPainter strokePainter,
  }) : _strokePainter = strokePainter;

  final Paint stroke;
  final Paint fill;
  final Float64List dashPattern;
  final ChartPathPainter _strokePainter;

  static final Float64List solidDashPattern = Float64List(0);

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

    return ChartPaintBundle(
      stroke: strokePaint,
      fill: fillPaint,
      dashPattern: style.dashPattern.isEmpty
          ? solidDashPattern
          : Float64List.fromList(style.dashPattern),
      strokePainter: _strokePainterFor(strokePaint),
    );
  }

  void strokePath(Canvas canvas, Path path) {
    _strokePainter(canvas, path);
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
    final ChartPaintBundle bundle = ChartPaintBundle.fromStyle(
      sheet.resolve(key),
    );
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
