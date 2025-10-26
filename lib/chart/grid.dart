import 'dart:typed_data';
import 'dart:ui';

import 'base.dart';
import 'style.dart';

class ChartGridLayer extends ChartLayer {
  ChartGridLayer(
    super.key,
    Float32List domainLines,
    Float32List measureLines,
    this.domainStyleKey,
    this.measureStyleKey,
  ) : domainPositions = Float32List(domainLines.length),
      measurePositions = Float32List(measureLines.length) {
    for (int i = 0; i < domainLines.length; i += 1) {
      domainPositions[i] = domainLines[i];
    }
    for (int i = 0; i < measureLines.length; i += 1) {
      measurePositions[i] = measureLines[i];
    }
  }

  final Float32List domainPositions;
  final Float32List measurePositions;
  final ChartStyleKey domainStyleKey;
  final ChartStyleKey measureStyleKey;

  @override
  void paint(ChartRenderContext context) {
    final Canvas canvas = context.canvas;
    final ChartTransform transform = context.transform;
    final Size size = context.size;

    final ChartPaintBundle domainPaint = context.paintCache.resolve(
      context.styleSheet,
      domainStyleKey,
    );
    for (int i = 0; i < domainPositions.length; i += 1) {
      final double x = transform.projectX(domainPositions[i]);
      canvas.drawLine(
        Offset(x, 0.0),
        Offset(x, size.height),
        domainPaint.stroke,
      );
    }

    final ChartPaintBundle measurePaint = context.paintCache.resolve(
      context.styleSheet,
      measureStyleKey,
    );
    for (int i = 0; i < measurePositions.length; i += 1) {
      final double y = transform.projectY(measurePositions[i]);
      canvas.drawLine(
        Offset(0.0, y),
        Offset(size.width, y),
        measurePaint.stroke,
      );
    }
  }
}
