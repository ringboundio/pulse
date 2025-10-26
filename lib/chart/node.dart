import 'dart:typed_data';
import 'dart:ui';

import 'base.dart';

class ChartPoint {
  const ChartPoint(this.domain, this.measure);

  final double domain;
  final double measure;
}

class ChartPolylineGeometry {
  ChartPolylineGeometry(Float32List source)
    : positions = Float32List(source.length) {
    final int length = source.length;
    for (int i = 0; i < length; i += 1) {
      positions[i] = source[i];
    }
  }

  final Float32List positions;

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

  void writeToPath(Path path, ChartTransform transform) {
    path.reset();
    final int length = positions.length;
    if (length == 0) {
      return;
    }
    final double firstDomain = positions[0];
    final double firstMeasure = positions[1];
    final Offset first = transform.project(firstDomain, firstMeasure);
    path.moveTo(first.dx, first.dy);
    for (int i = 2; i < length; i += 2) {
      final double domain = positions[i];
      final double measure = positions[i + 1];
      final Offset offset = transform.project(domain, measure);
      path.lineTo(offset.dx, offset.dy);
    }
  }
}

class ChartAreaNode extends ChartNode {
  ChartAreaNode(super.key, super.styleKey, this.upper, this.baseline);

  final ChartPolylineGeometry upper;
  final double baseline;

  void writeFill(Path fillPath, ChartTransform transform) {
    fillPath.reset();
    final Float32List positions = upper.positions;
    final int length = positions.length;
    if (length == 0) {
      return;
    }
    final double baselineY = transform.projectY(baseline);
    final double firstDomain = positions[0];
    final double firstMeasure = positions[1];
    final Offset first = transform.project(firstDomain, firstMeasure);
    fillPath.moveTo(first.dx, first.dy);
    for (int i = 2; i < length; i += 2) {
      final double domain = positions[i];
      final double measure = positions[i + 1];
      final Offset point = transform.project(domain, measure);
      fillPath.lineTo(point.dx, point.dy);
    }
    for (int i = length - 2; i >= 0; i -= 2) {
      final double domain = positions[i];
      final double x = transform.projectX(domain);
      fillPath.lineTo(x, baselineY);
    }
    fillPath.close();
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
}
