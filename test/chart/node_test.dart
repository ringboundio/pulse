import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/node.dart';
import 'package:pulse/chart/style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Ensures area node produces a closed fill path for painting.
  test('ChartAreaNode fill path is closed', () {
    final Float32List coordinates = Float32List(6);
    coordinates[0] = 0.0;
    coordinates[1] = 1.0;
    coordinates[2] = 5.0;
    coordinates[3] = 3.0;
    coordinates[4] = 10.0;
    coordinates[5] = 2.0;
    final ChartPolylineGeometry upper = ChartPolylineGeometry(coordinates);
    final ChartAreaNode node = ChartAreaNode(
      ChartNodeKey('area'),
      ChartStyleKey('area-style'),
      upper,
      0.0,
    );
    final Path fill = Path();
    final ChartTransform transform = ChartTransform(
      scaleX: 1.0,
      translateX: 0.0,
      scaleY: 1.0,
      translateY: 0.0,
      height: 100.0,
    );
    node.writeFill(fill, transform);

    final PathMetrics metrics = fill.computeMetrics();
    int closedCount = 0;
    for (final PathMetric metric in metrics) {
      if (metric.isClosed) {
        closedCount += 1;
      }
    }
    expect(closedCount, greaterThan(0));
  });
}
