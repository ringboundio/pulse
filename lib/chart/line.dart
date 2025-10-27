import 'dart:typed_data';
import 'dart:ui';

import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/node.dart';

class ChartLineLayer extends ChartLayer {
  ChartLineLayer(super.key, List<ChartLineNode> nodes)
    : nodes = List<ChartLineNode>.unmodifiable(nodes);

  final List<ChartLineNode> nodes;

  @override
  void paint(ChartRenderContext context) {
    final Canvas canvas = context.canvas;
    final Path path = context.scratchSpace.primaryPath;
    for (int i = 0; i < nodes.length; i += 1) {
      final ChartLineNode node = nodes[i];
      node.geometry.writeToPath(path, context.transform);
      final ChartPaintBundle bundle = context.paintCache.resolve(
        context.styleSheet,
        node.styleKey,
      );
      if (bundle.dashPattern.isEmpty) {
        canvas.drawPath(path, bundle.stroke);
      } else {
        _drawDashedPath(canvas, path, bundle);
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, ChartPaintBundle bundle) {
    final PathMetrics metrics = path.computeMetrics();
    final Float64List pattern = bundle.dashPattern;
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
          final Path dashedSegment = metric.extractPath(
            distance,
            clamped,
            startWithMoveTo: true,
          );
          canvas.drawPath(dashedSegment, bundle.stroke);
        }
        distance = clamped;
        index += 1;
        draw = !draw;
      }
    }
  }
}
