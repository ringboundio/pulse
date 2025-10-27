import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/style.dart';

class ChartDoubleRange {
  ChartDoubleRange(this.min, this.max) : assert(max > min);

  final double min;
  final double max;

  double get span => max - min;
}

class ChartSpace {
  ChartSpace(this.domain, this.measure, this.devicePixelRatio)
    : assert(devicePixelRatio > 0.0);

  final ChartDoubleRange domain;
  final ChartDoubleRange measure;
  final double devicePixelRatio;
}

class ChartScene {
  ChartScene(this.space, List<ChartLayer> layers)
    : layers = List<ChartLayer>.unmodifiable(layers);

  final ChartSpace space;
  final List<ChartLayer> layers;
}

class ChartSceneGraph {
  ChartSceneGraph(this.scene, this.styleSheet);

  final ChartScene scene;
  final ChartStyleSheet styleSheet;

  ChartSceneGraph withScene(ChartScene updatedScene) {
    return ChartSceneGraph(updatedScene, styleSheet);
  }

  ChartSceneGraph withStyleSheet(ChartStyleSheet sheet) {
    return ChartSceneGraph(scene, sheet);
  }

  ChartSceneGraph withStyleOverride(ChartStyleKey key, ChartPaintStyle style) {
    return ChartSceneGraph(scene, styleSheet.override(key: key, style: style));
  }
}

class ChartSceneBuilder {
  ChartSceneBuilder(this.space) : _layers = <ChartLayer>[];

  final ChartSpace space;
  final List<ChartLayer> _layers;

  void addLayer(ChartLayer layer) {
    _layers.add(layer);
  }

  ChartScene build() {
    return ChartScene(space, List<ChartLayer>.unmodifiable(_layers));
  }
}
