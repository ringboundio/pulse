import 'package:flutter/foundation.dart';

import 'package:pulse/chart/data.dart';
import 'package:pulse/chart/style.dart';

class ChartController extends ChangeNotifier {
  ChartController(ChartSceneGraph initialGraph)
    : _graph = initialGraph,
      _revision = 0;

  ChartSceneGraph _graph;
  int _revision;

  ChartSceneGraph get graph {
    return _graph;
  }

  int get revision {
    return _revision;
  }

  void setGraph(ChartSceneGraph graph) {
    _graph = graph;
    _advance();
  }

  void setScene(ChartScene scene) {
    _graph = _graph.withScene(scene);
    _advance();
  }

  void setStyleSheet(ChartStyleSheet sheet) {
    _graph = _graph.withStyleSheet(sheet);
    _advance();
  }

  void overrideStyle({
    required ChartStyleKey key,
    required ChartPaintStyle style,
  }) {
    _graph = _graph.withStyleOverride(key, style);
    _advance();
  }

  void _advance() {
    _revision += 1;
    notifyListeners();
  }
}
