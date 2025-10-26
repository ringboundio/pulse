import 'package:flutter/widgets.dart';

import 'base.dart';
import 'controller.dart';
import 'data.dart';

class ChartRenderer {
  const ChartRenderer();

  void render(
    Canvas canvas,
    Size size,
    ChartSceneGraph graph,
    ChartPaintCache cache,
    ChartScratchSpace scratchSpace,
  ) {
    final ChartSpace space = graph.scene.space;
    final ChartDoubleRange domain = space.domain;
    final ChartDoubleRange measure = space.measure;

    final double scaleX = size.width / domain.span;
    final double translateX = -domain.min * scaleX;
    final double scaleY = size.height / measure.span;
    final double translateY = -measure.min * scaleY;

    final ChartTransform transform = ChartTransform(
      scaleX,
      translateX,
      scaleY,
      translateY,
      size.height,
    );

    final ChartRenderContext context = ChartRenderContext(
      canvas,
      size,
      transform,
      graph.styleSheet,
      cache,
      space.devicePixelRatio,
      scratchSpace,
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
    _renderer.render(canvas, size, graph, _cache, _scratch);
  }

  @override
  bool shouldRepaint(covariant ChartSurfacePainter oldDelegate) {
    if (!identical(oldDelegate._renderer, _renderer)) {
      return true;
    }
    if (!identical(oldDelegate._controller, _controller)) {
      return true;
    }
    if (oldDelegate._controller.revision != _controller.revision) {
      return true;
    }
    return false;
  }

  @override
  bool shouldRebuildSemantics(covariant ChartSurfacePainter oldDelegate) {
    return false;
  }
}
