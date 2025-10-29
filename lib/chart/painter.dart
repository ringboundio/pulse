import 'package:flutter/widgets.dart';

import 'package:pulse/chart/controller.dart';
import 'package:pulse/chart/data.dart';
import 'package:pulse/chart/foundation.dart';

class ChartRenderer {
  const ChartRenderer();

  void render({
    required Canvas canvas,
    required Size size,
    required ChartSceneGraph graph,
    required ChartPaintCache cache,
    required ChartScratchSpace scratchSpace,
  }) {
    final ChartSpace space = graph.scene.space;
    final ChartDoubleRange domain = space.domain;
    final ChartDoubleRange measure = space.measure;

    final double scaleX = size.width / domain.span;
    final double translateX = -domain.min * scaleX;
    final double scaleY = size.height / measure.span;
    final double translateY = -measure.min * scaleY;

    final ChartTransform transform = ChartTransform(
      scaleX: scaleX,
      translateX: translateX,
      scaleY: scaleY,
      translateY: translateY,
      height: size.height,
    );

    final ChartRenderContext context = ChartRenderContext(
      canvas: canvas,
      size: size,
      transform: transform,
      styleSheet: graph.styleSheet,
      paintCache: cache,
      devicePixelRatio: space.devicePixelRatio,
      scratchSpace: scratchSpace,
    );

    final List<ChartLayer> layers = graph.scene.layers;
    for (int i = 0; i < layers.length; i += 1) {
      scratchSpace.reset();
      layers[i].paint(context);
    }
  }
}

class ChartSurface extends StatelessWidget {
  const ChartSurface({
    super.key,
    required this.controller,
    required this.renderer,
  });

  final ChartController controller;
  final ChartRenderer renderer;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ChartSurfacePainter(controller, renderer),
      isComplex: true,
      willChange: true,
    );
  }
}

class ChartSurfacePainter extends CustomPainter {
  ChartSurfacePainter(this._controller, this._renderer)
    : _cache = ChartPaintCache(),
      _scratch = ChartScratchSpace(),
      super(repaint: _controller);

  final ChartController _controller;
  final ChartRenderer _renderer;
  final ChartPaintCache _cache;
  final ChartScratchSpace _scratch;

  @override
  void paint(Canvas canvas, Size size) {
    final ChartSceneGraph graph = _controller.graph;
    _renderer.render(
      canvas: canvas,
      size: size,
      graph: graph,
      cache: _cache,
      scratchSpace: _scratch,
    );
  }

  @override
  bool shouldRepaint(covariant ChartSurfacePainter oldDelegate) {
    return !identical(oldDelegate._renderer, _renderer) ||
        !identical(oldDelegate._controller, _controller) ||
        oldDelegate._controller.revision != _controller.revision;
  }

  @override
  bool shouldRebuildSemantics(covariant ChartSurfacePainter oldDelegate) {
    return false;
  }
}
