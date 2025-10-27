import 'dart:typed_data';
import 'dart:ui';

import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/node.dart';

class ChartBarLayer extends ChartLayer {
  ChartBarLayer(super.key, List<ChartBarNode> nodes)
    : nodes = List<ChartBarNode>.unmodifiable(nodes);

  final List<ChartBarNode> nodes;

  @override
  void paint(ChartRenderContext context) {
    final Canvas canvas = context.canvas;
    final ChartTransform transform = context.transform;
    final ChartScratchSpace scratch = context.scratchSpace;
    for (int i = 0; i < nodes.length; i += 1) {
      final ChartBarNode node = nodes[i];
      final ChartPaintBundle bundle = context.paintCache.resolve(
        context.styleSheet,
        node.styleKey,
      );
      final Float32List values = node.geometry.values;
      for (int j = 0; j < values.length; j += 4) {
        final double centerDomain = values[j];
        final double lowMeasure = values[j + 1];
        final double highMeasure = values[j + 2];
        final double halfWidth = values[j + 3];

        final double centerX = transform.projectX(centerDomain);
        final double halfWidthPixels = halfWidth * transform.scaleX;
        final double left = centerX - halfWidthPixels;
        final double right = centerX + halfWidthPixels;
        final double top = transform.projectY(highMeasure);
        final double bottom = transform.projectY(lowMeasure);

        scratch.rect = Rect.fromLTRB(left, top, right, bottom);
        canvas.drawRect(scratch.rect, bundle.fill);
        if (bundle.stroke.strokeWidth > 0.0) {
          canvas.drawRect(scratch.rect, bundle.stroke);
        }
      }
    }
  }
}
