import 'dart:ui';

import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/node.dart';

class ChartBarLayer extends ChartLayer {
  ChartBarLayer(super.key, List<ChartBarNode> nodes)
    : nodes = List<ChartBarNode>.unmodifiable(nodes);

  final List<ChartBarNode> nodes;
  late Picture _cachedPicture;
  bool _hasCachedPicture = false;
  int _cachedTransformKey = -1;
  int _cachedStyleRevision = -1;
  double _cachedDevicePixelRatio = double.nan;

  @override
  void paint(ChartRenderContext context) {
    final int transformKey = context.transform.cacheKey;
    final int styleRevision = context.styleSheet.revision;
    final double devicePixelRatio = context.devicePixelRatio;
    if (_hasCachedPicture &&
        _cachedTransformKey == transformKey &&
        _cachedStyleRevision == styleRevision &&
        _cachedDevicePixelRatio == devicePixelRatio) {
      context.canvas.drawPicture(_cachedPicture);
      return;
    }

    final PictureRecorder recorder = PictureRecorder();
    final Canvas recorderCanvas = Canvas(recorder);
    _render(recorderCanvas, context);

    if (_hasCachedPicture) {
      _cachedPicture.dispose();
    }
    _cachedPicture = recorder.endRecording();
    _hasCachedPicture = true;
    _cachedTransformKey = transformKey;
    _cachedStyleRevision = styleRevision;
    _cachedDevicePixelRatio = devicePixelRatio;

    context.canvas.drawPicture(_cachedPicture);
  }

  void _render(Canvas canvas, ChartRenderContext context) {
    final ChartTransform transform = context.transform;
    for (int i = 0; i < nodes.length; i += 1) {
      final ChartBarNode node = nodes[i];
      final ChartPaintBundle bundle = context.paintCache.resolve(
        context.styleSheet,
        node.styleKey,
      );
      final Path barPath = node.pathForTransform(transform);
      canvas.drawPath(barPath, bundle.fill);
      bundle.strokePath(canvas, barPath);
    }
  }
}
