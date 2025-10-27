import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:pulse/buffer/channel.dart';
import 'package:pulse/buffer/client.dart';
import 'package:pulse/chart/controller.dart';
import 'package:pulse/chart/data.dart';
import 'package:pulse/chart/foundation.dart';
import 'package:pulse/chart/painter.dart';
import 'package:pulse/development/charting.dart';
import 'package:pulse/development/input_profiles.dart';
import 'package:pulse/development/provider.dart';
import 'package:pulse/development/viewport.dart';
import 'package:pulse/input/core.dart';
import 'package:pulse/input/manager.dart';
import 'package:pulse/input/router.dart';

class DevelopmentEnvironment {
  DevelopmentEnvironment({
    required this.viewport,
    required this.bufferClient,
    required this.chartController,
    required this.chartRenderer,
    required this.chartAssembler,
    required this.focusManager,
    required this.router,
    required this.rootInputFocus,
    required this.shortcuts,
    required this.widgetFocusNode,
  }) : _samples = <BufferSample>[],
       _subscriptions = <StreamSubscription<dynamic>>[],
       _devicePixelRatio = 1.0,
       _initialized = false,
       _symbol = const BufferSymbol(''),
       _interval = const BufferInterval(1),
       _endpoint = BufferEndpoint(Uri.parse('about:blank')),
       _policy = const BufferPolicy(
         prefetchBackMicros: 0,
         prefetchForwardMicros: 0,
       );

  final DevelopmentViewport viewport;
  final BufferClient bufferClient;
  final ChartController chartController;
  final ChartRenderer chartRenderer;
  final DevelopmentChartAssembler chartAssembler;
  final InputFocusManager focusManager;
  final StandardInputRouter router;
  final InputFocusNode rootInputFocus;
  final ShortcutsRegistry shortcuts;
  final FocusNode widgetFocusNode;

  List<BufferSample> _samples;
  final List<StreamSubscription<dynamic>> _subscriptions;
  double _devicePixelRatio;
  bool _initialized;
  BufferSymbol _symbol;
  BufferInterval _interval;
  BufferEndpoint _endpoint;
  BufferPolicy _policy;

  int get sampleCount => _samples.length;

  BufferSymbol get symbol => _symbol;

  BufferInterval get interval => _interval;

  BufferPolicy get policy => _policy;

  void initialize({
    required BufferSymbol symbol,
    required BufferInterval interval,
    required BufferEndpoint endpoint,
    required BufferPolicy policy,
  }) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _symbol = symbol;
    _interval = interval;
    _endpoint = endpoint;
    _policy = policy;

    viewport.addListener(_handleViewportChange);
    _subscriptions.add(bufferClient.samples.listen(_handleSamples));
    _subscriptions.add(bufferClient.logs.listen(_handleLog));

    bufferClient.setConfig(
      symbol: _symbol,
      interval: _interval,
      endpoint: _endpoint,
    );
    bufferClient.setPolicy(
      prefetchBackMicros: _policy.prefetchBackMicros,
      prefetchForwardMicros: _policy.prefetchForwardMicros,
    );
    _requestActiveRange();
    _refreshChart();
  }

  void updateDevicePixelRatio(double ratio) {
    if (ratio <= 0.0) {
      return;
    }
    if ((_devicePixelRatio - ratio).abs() < 0.001) {
      return;
    }
    _devicePixelRatio = ratio;
    _refreshChart();
  }

  void dispose() {
    viewport.removeListener(_handleViewportChange);
    for (int index = 0; index < _subscriptions.length; index += 1) {
      _subscriptions[index].cancel();
    }
    _subscriptions.clear();
    bufferClient.dispose();
    widgetFocusNode.dispose();
  }

  void _handleSamples(BufferSamplesEvent event) {
    _samples = List<BufferSample>.from(event.samples);
    _refreshChart();
  }

  void _handleViewportChange() {
    _requestActiveRange();
    _refreshChart();
  }

  void _handleLog(BufferLogEvent event) {
    debugPrint('[buffer ${event.level.name}] ${event.message}');
  }

  void _requestActiveRange() {
    bufferClient.sendRange(
      startMicros: viewport.startMicros,
      endMicros: viewport.endMicros,
    );
  }

  void _refreshChart() {
    chartAssembler.updateGraph(
      samples: _samples,
      viewportStartMicros: viewport.startMicros,
      viewportEndMicros: viewport.endMicros,
      devicePixelRatio: _devicePixelRatio,
    );
  }
}

Future<DevelopmentEnvironment> buildDevelopmentEnvironment() async {
  const int intervalMicros = 60000000;
  const BufferInterval interval = BufferInterval(intervalMicros);
  const BufferSymbol symbol = BufferSymbol('DEV.SIM');
  final BufferEndpoint endpoint = BufferEndpoint(
    Uri.parse('https://dev.simulated.pulse'),
  );
  const BufferPolicy policy = BufferPolicy(
    prefetchBackMicros: intervalMicros * 180,
    prefetchForwardMicros: intervalMicros * 180,
  );

  final DevelopmentBufferDataProvider provider =
      DevelopmentBufferDataProvider();
  final BufferClient client = await BufferClient.spawn(provider: provider);

  final DevelopmentViewport viewport = DevelopmentViewport(
    intervalMicros: interval.microseconds,
    minWindowMicros: interval.microseconds * 30,
    maxWindowMicros: interval.microseconds * 720,
    initialStartMicros: 0,
    initialWindowMicros: interval.microseconds * 180,
  );

  final DevelopmentChartStyles styles = DevelopmentChartStyles();
  final ChartSceneGraph bootstrapGraph = ChartSceneGraph(
    ChartScene(
      ChartSpace(ChartDoubleRange(0.0, 1.0), ChartDoubleRange(0.0, 1.0), 1.0),
      <ChartLayer>[],
    ),
    styles.sheet(),
  );
  final ChartController chartController = ChartController(bootstrapGraph);
  final DevelopmentChartAssembler assembler = DevelopmentChartAssembler(
    controller: chartController,
    styles: styles,
  );

  final DeviceCalibration calibration = DeviceCalibration(
    panUnit: 1.0,
    zoomUnit: 1.0,
    scrubUnit: 1.0,
  );
  final InputSettings settings = InputSettings(
    invertScroll: false,
    panIntensity: 1.0,
    zoomIntensity: 1.0,
    scrubIntensity: 1.0,
  );

  final DevelopmentKeyboardProfile keyboardProfile = DevelopmentKeyboardProfile(
    viewport: viewport,
  );
  final DevelopmentPointerProfile pointerProfile = DevelopmentPointerProfile(
    viewport: viewport,
  );
  final DevelopmentGestureProfile gestureProfile = DevelopmentGestureProfile(
    viewport: viewport,
  );

  final InputProfile inputProfile = InputProfile(
    keyboard: keyboardProfile,
    pointer: pointerProfile,
    gesture: gestureProfile,
    settings: settings,
    deviceCalibration: calibration,
  );

  void handleFocusGain(InputFocusChange change) {}
  void handleFocusLost(InputFocusChange change) {}

  final InputFocusNode rootInputFocus = InputFocusNode(
    id: 'development.root',
    profile: inputProfile,
    onFocusGained: handleFocusGain,
    onFocusLost: handleFocusLost,
  );
  final ShortcutsRegistry shortcuts = ShortcutsRegistry(
    rootScope: rootInputFocus.id,
  );
  final InputFocusManager focusManager = InputFocusManager(
    rootNode: rootInputFocus,
    shortcuts: shortcuts,
  );
  final StandardInputRouter router = StandardInputRouter(
    focusManager: focusManager,
  );

  final DevelopmentEnvironment environment = DevelopmentEnvironment(
    viewport: viewport,
    bufferClient: client,
    chartController: chartController,
    chartRenderer: const ChartRenderer(),
    chartAssembler: assembler,
    focusManager: focusManager,
    router: router,
    rootInputFocus: rootInputFocus,
    shortcuts: shortcuts,
    widgetFocusNode: FocusNode(debugLabel: 'development.widget.focus'),
  );

  environment.initialize(
    symbol: symbol,
    interval: interval,
    endpoint: endpoint,
    policy: policy,
  );

  return environment;
}
