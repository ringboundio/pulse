import 'dart:typed_data';
import 'dart:ui';

import 'package:pulse/chart/foundation.dart';

class ChartPoint {
  const ChartPoint(this.domain, this.measure);

  final double domain;
  final double measure;
}

class ChartPolylineGeometry {
  ChartPolylineGeometry(Float32List source)
    : positions = Float32List(source.length),
      _projectedPositions = Float32List(0),
      _cachedPath = Path() {
    final int length = source.length;
    for (int i = 0; i < length; i += 1) {
      positions[i] = source[i];
    }
  }

  final Float32List positions;
  Float32List _projectedPositions;
  final Path _cachedPath;
  int _cachedTransformKey = -1;
  bool _pathCacheValid = false;
  final Map<Float64List, Path> _dashedCache = <Float64List, Path>{};
  int _dashedCacheTransformKey = -1;

  factory ChartPolylineGeometry.fromPoints(List<ChartPoint> points) {
    final int count = points.length;
    final Float32List buffer = Float32List(count * 2);
    int index = 0;
    for (int i = 0; i < count; i += 1) {
      final ChartPoint point = points[i];
      buffer[index] = point.domain;
      buffer[index + 1] = point.measure;
      index += 2;
    }
    return ChartPolylineGeometry(buffer);
  }

  Path pathForTransform(ChartTransform transform) {
    _ensureCache(transform);
    return _cachedPath;
  }

  Float32List projectedPositionsForTransform(ChartTransform transform) {
    _ensureCache(transform);
    return _projectedPositions;
  }

  Path dashedPathForTransform(ChartTransform transform, Float64List pattern) {
    _ensureCache(transform);
    final int transformKey = _cachedTransformKey;
    if (_dashedCacheTransformKey != transformKey) {
      _dashedCache.clear();
      _dashedCacheTransformKey = transformKey;
    }
    if (identical(pattern, ChartPaintBundle.solidDashPattern)) {
      _dashedCache[pattern] = _cachedPath;
      return _cachedPath;
    }
    final Path? cached = _dashedCache[pattern];
    if (cached != null) {
      return cached;
    }
    return _dashedCache[pattern] = _buildDashedPath(_cachedPath, pattern);
  }

  void _ensureCache(ChartTransform transform) {
    final int key = transform.cacheKey;
    if (_pathCacheValid && _cachedTransformKey == key) {
      return;
    }

    final int length = positions.length;
    if (_projectedPositions.length != length) {
      _projectedPositions = Float32List(length);
    }
    final Float32List projected = _projectedPositions;
    for (int i = 0; i < length; i += 2) {
      final double domain = positions[i];
      final double measure = positions[i + 1];
      projected[i] = (domain * transform.scaleX) + transform.translateX;
      final double rawY = (measure * transform.scaleY) + transform.translateY;
      projected[i + 1] = transform.height - rawY;
    }

    final Float32List pathPositions = projected;

    final Path path = _cachedPath;
    path.reset();
    if (pathPositions.length >= 2) {
      path.moveTo(pathPositions[0], pathPositions[1]);
      for (int i = 2; i < pathPositions.length; i += 2) {
        path.lineTo(pathPositions[i], pathPositions[i + 1]);
      }
    }

    _cachedTransformKey = key;
    _pathCacheValid = true;
  }

  Path _buildDashedPath(Path source, Float64List pattern) {
    final Path results = Path();
    final PathMetrics metrics = source.computeMetrics();
    final int patternLength = pattern.length;
    for (final PathMetric metric in metrics) {
      double distance = 0.0;
      int index = 0;
      bool draw = true;
      while (distance < metric.length) {
        if (index == patternLength) {
          index = 0;
        }
        final double segment = pattern[index];
        final double nextDistance = distance + segment;
        final double clamped = nextDistance < metric.length
            ? nextDistance
            : metric.length;
        if (draw) {
          results.addPath(
            metric.extractPath(distance, clamped, startWithMoveTo: true),
            Offset.zero,
          );
        }
        distance = clamped;
        index += 1;
        draw = !draw;
      }
    }
    return results;
  }
}

class ChartAreaNode extends ChartNode {
  ChartAreaNode(super.key, super.styleKey, this.upper, this.baseline);

  final ChartPolylineGeometry upper;
  final double baseline;
  final Path _fillPath = Path();
  int _fillTransformKey = -1;
  bool _fillCacheValid = false;

  Path fillPathForTransform(ChartTransform transform) {
    final int key = transform.cacheKey;
    if (_fillCacheValid && _fillTransformKey == key) {
      return _fillPath;
    }

    final Float32List projected = upper.projectedPositionsForTransform(
      transform,
    );
    final int length = projected.length;
    final Path path = _fillPath;
    path.reset();
    if (length >= 2) {
      final double baselineY =
          transform.height -
          ((baseline * transform.scaleY) + transform.translateY);
      path.moveTo(projected[0], projected[1]);
      for (int i = 2; i < length; i += 2) {
        path.lineTo(projected[i], projected[i + 1]);
      }
      for (int i = length - 2; i >= 0; i -= 2) {
        path.lineTo(projected[i], baselineY);
      }
      path.close();
    }

    _fillTransformKey = key;
    _fillCacheValid = true;
    return path;
  }
}

class ChartLineNode extends ChartNode {
  ChartLineNode(super.key, super.styleKey, this.geometry);

  final ChartPolylineGeometry geometry;
}

class ChartBarGeometry {
  ChartBarGeometry(Float32List source) : values = Float32List(source.length) {
    final int length = source.length;
    for (int i = 0; i < length; i += 1) {
      values[i] = source[i];
    }
  }

  final Float32List values;

  int get barCount {
    return values.length ~/ 4;
  }
}

class ChartBarNode extends ChartNode {
  ChartBarNode(super.key, super.styleKey, this.geometry);

  final ChartBarGeometry geometry;
  final Path _barPath = Path();
  int _transformKey = -1;
  bool _barCacheValid = false;

  Path pathForTransform(ChartTransform transform) {
    final int key = transform.cacheKey;
    if (_barCacheValid && _transformKey == key) {
      return _barPath;
    }

    final Path path = _barPath;
    path.reset();
    final Float32List values = geometry.values;
    for (int j = 0; j < values.length; j += 4) {
      final double centerDomain = values[j];
      final double lowMeasure = values[j + 1];
      final double highMeasure = values[j + 2];
      final double halfWidth = values[j + 3];

      final double centerX =
          (centerDomain * transform.scaleX) + transform.translateX;
      final double halfWidthPixels = halfWidth * transform.scaleX;
      final double left = centerX - halfWidthPixels;
      final double right = centerX + halfWidthPixels;
      final double top =
          transform.height -
          ((highMeasure * transform.scaleY) + transform.translateY);
      final double bottom =
          transform.height -
          ((lowMeasure * transform.scaleY) + transform.translateY);

      path.addRect(Rect.fromLTRB(left, top, right, bottom));
    }

    _transformKey = key;
    _barCacheValid = true;
    return path;
  }
}

class ChartCandleGeometry {
  ChartCandleGeometry(Float32List source)
    : values = Float32List(source.length) {
    final int length = source.length;
    for (int i = 0; i < length; i += 1) {
      values[i] = source[i];
    }
  }

  final Float32List values;

  int get candleCount {
    return values.length ~/ 6;
  }
}

class ChartCandleNode extends ChartNode {
  ChartCandleNode(super.key, super.styleKey, this.geometry);

  final ChartCandleGeometry geometry;
  final Path _bodyPath = Path();
  final Path _wickPath = Path();
  int _transformKey = -1;
  bool _cacheValid = false;

  Path bodyPathForTransform(ChartTransform transform) {
    _ensurePaths(transform);
    return _bodyPath;
  }

  Path wickPathForTransform(ChartTransform transform) {
    _ensurePaths(transform);
    return _wickPath;
  }

  void _ensurePaths(ChartTransform transform) {
    final int key = transform.cacheKey;
    if (_cacheValid && _transformKey == key) {
      return;
    }

    _bodyPath.reset();
    _wickPath.reset();
    final Float32List values = geometry.values;
    for (int j = 0; j < values.length; j += 6) {
      final double domain = values[j];
      final double open = values[j + 1];
      final double high = values[j + 2];
      final double low = values[j + 3];
      final double close = values[j + 4];
      final double halfWidth = values[j + 5];

      final double centerX = (domain * transform.scaleX) + transform.translateX;
      final double halfWidthPixels = halfWidth * transform.scaleX;
      final double left = centerX - halfWidthPixels;
      final double right = centerX + halfWidthPixels;

      final double openY =
          transform.height - ((open * transform.scaleY) + transform.translateY);
      final double closeY =
          transform.height -
          ((close * transform.scaleY) + transform.translateY);
      final double highY =
          transform.height - ((high * transform.scaleY) + transform.translateY);
      final double lowY =
          transform.height - ((low * transform.scaleY) + transform.translateY);

      final double bodyTop = openY < closeY ? openY : closeY;
      final double bodyBottom = openY > closeY ? openY : closeY;

      _wickPath.moveTo(centerX, highY);
      _wickPath.lineTo(centerX, lowY);

      _bodyPath.addRect(Rect.fromLTRB(left, bodyTop, right, bodyBottom));
    }

    _transformKey = key;
    _cacheValid = true;
  }
}
