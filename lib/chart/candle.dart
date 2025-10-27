import 'dart:typed_data';
import 'dart:ui';

import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/node.dart';

class ChartCandleLayer extends ChartLayer {
  ChartCandleLayer(super.key, List<ChartCandleNode> nodes)
    : nodes = List<ChartCandleNode>.unmodifiable(nodes);

  final List<ChartCandleNode> nodes;

  @override
  void paint(ChartRenderContext context) {
    final Canvas canvas = context.canvas;
    final ChartTransform transform = context.transform;
    final ChartScratchSpace scratch = context.scratchSpace;
    for (int i = 0; i < nodes.length; i += 1) {
      final ChartCandleNode node = nodes[i];
      final ChartPaintBundle bundle = context.paintCache.resolve(
        context.styleSheet,
        node.styleKey,
      );
      final Float32List values = node.geometry.values;
      for (int j = 0; j < values.length; j += 6) {
        final double domain = values[j];
        final double open = values[j + 1];
        final double high = values[j + 2];
        final double low = values[j + 3];
        final double close = values[j + 4];
        final double halfWidth = values[j + 5];

        final double centerX = transform.projectX(domain);
        final double halfWidthPixels = halfWidth * transform.scaleX;
        final double left = centerX - halfWidthPixels;
        final double right = centerX + halfWidthPixels;

        final double openY = transform.projectY(open);
        final double closeY = transform.projectY(close);
        final double highY = transform.projectY(high);
        final double lowY = transform.projectY(low);

        final double bodyTop = openY < closeY ? openY : closeY;
        final double bodyBottom = openY > closeY ? openY : closeY;

        canvas.drawLine(
          Offset(centerX, highY),
          Offset(centerX, lowY),
          bundle.stroke,
        );

        scratch.rect = Rect.fromLTRB(left, bodyTop, right, bodyBottom);
        canvas.drawRect(scratch.rect, bundle.fill);
        canvas.drawRect(scratch.rect, bundle.stroke);
      }
    }
  }
}
