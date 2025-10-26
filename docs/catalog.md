# Library Catalog

Generated on 2025-10-26 21:59 UTC by `go run ./tool/cmd/catalog`.

_Legend: 🪦 unused file · ⚠️ deprecated symbol · 🧪 no dedicated test_

| Status | File | Top-level types | Exported functions | Unexported functions | File test | Related tests |
| --- | --- | --- | --- | --- | --- | --- |
| — | [`lib/buffer/channel.dart`](../lib/buffer/channel.dart) | abstract class BufferCommand<br>abstract class BufferDataProvider<br>abstract class BufferEvent<br>class BufferConfig<br>class BufferDisposeCommand<br>class BufferEndpoint<br>class BufferInterval<br>class BufferLogEvent<br>class BufferPolicy<br>class BufferRange<br>class BufferReadyEvent<br>class BufferSample<br>class BufferSamplesEvent<br>class BufferSendRangeCommand<br>class BufferSetConfigCommand<br>class BufferSetPolicyCommand<br>class BufferSymbol<br>class BufferTerminatedEvent<br>enum BufferLogLevel<br>typedef BufferCommandPort<br>typedef BufferEventPort | [`BufferRange.expand()`](../lib/buffer/channel.dart#L55) | — | [`test/buffer/channel_test.dart`](../test/buffer/channel_test.dart) | [`test/buffer/client_test.dart`](../test/buffer/client_test.dart) |
| — | [`lib/buffer/client.dart`](../lib/buffer/client.dart) | abstract class BufferClient<br>class _IsolateBufferClient | [`_IsolateBufferClient.dispose()`](../lib/buffer/client.dart#L174) | [`_IsolateBufferClient._disposeStreams()`](../lib/buffer/client.dart#L164)<br>[`_IsolateBufferClient._enqueue()`](../lib/buffer/client.dart#L130)<br>[`_IsolateBufferClient._handleEvent()`](../lib/buffer/client.dart#L139) | [`test/buffer/client_test.dart`](../test/buffer/client_test.dart) | — |
| 🧪 | [`lib/buffer/worker.dart`](../lib/buffer/worker.dart) | class BufferWorkerBootstrap<br>class _BufferWorker<br>class _ConfigState<br>class _RangeSlot<br>class _SampleStore | [`_BufferWorker.run()`](../lib/buffer/worker.dart#L57)<br>[`_ConfigState.assign()`](../lib/buffer/worker.dart#L276)<br>[`_ConfigState.require()`](../lib/buffer/worker.dart#L278)<br>[`_RangeSlot.assign()`](../lib/buffer/worker.dart#L291)<br>[`_RangeSlot.clear()`](../lib/buffer/worker.dart#L296)<br>[`_RangeSlot.value()`](../lib/buffer/worker.dart#L300)<br>[`_SampleStore.clear()`](../lib/buffer/worker.dart#L196)<br>[`_SampleStore.covers()`](../lib/buffer/worker.dart#L244)<br>[`_SampleStore.extractWindow()`](../lib/buffer/worker.dart#L231)<br>[`_SampleStore.merge()`](../lib/buffer/worker.dart#L200)<br>[`_SampleStore.trim()`](../lib/buffer/worker.dart#L259)<br>[`bufferWorkerMain()`](../lib/buffer/worker.dart#L15) | [`_BufferWorker._emitSamples()`](../lib/buffer/worker.dart#L186)<br>[`_BufferWorker._handleDispose()`](../lib/buffer/worker.dart#L173)<br>[`_BufferWorker._handlePayload()`](../lib/buffer/worker.dart#L67)<br>[`_BufferWorker._handleSendRange()`](../lib/buffer/worker.dart#L106)<br>[`_BufferWorker._handleSetConfig()`](../lib/buffer/worker.dart#L88)<br>[`_BufferWorker._handleSetPolicy()`](../lib/buffer/worker.dart#L98)<br>[`_BufferWorker._scheduleHalo()`](../lib/buffer/worker.dart#L145)<br>[`_BufferWorker._trimToRetention()`](../lib/buffer/worker.dart#L178)<br>[`_SampleStore._insert()`](../lib/buffer/worker.dart#L206)<br>[`_SampleStore._lowerBound()`](../lib/buffer/worker.dart#L216) | — | — |
| 🧪 | [`lib/chart/area.dart`](../lib/chart/area.dart) | class ChartAreaLayer | [`ChartAreaLayer.paint()`](../lib/chart/area.dart#L13) | — | — | — |
| 🪦 🧪 | [`lib/chart/bar.dart`](../lib/chart/bar.dart) | class ChartBarLayer | [`ChartBarLayer.paint()`](../lib/chart/bar.dart#L14) | — | — | — |
| 🧪 | [`lib/chart/base.dart`](../lib/chart/base.dart) | abstract class ChartLayer<br>abstract class ChartNode<br>class ChartLayerKey<br>class ChartNodeKey<br>class ChartPaintBundle<br>class ChartPaintCache<br>class ChartPaintCacheEntry<br>class ChartRenderContext<br>class ChartScratchSpace<br>class ChartTransform | [`ChartPaintCache.resolve()`](../lib/chart/base.dart#L149)<br>[`ChartScratchSpace.reset()`](../lib/chart/base.dart#L78)<br>[`ChartTransform.project()`](../lib/chart/base.dart#L63)<br>[`ChartTransform.projectX()`](../lib/chart/base.dart#L54)<br>[`ChartTransform.projectY()`](../lib/chart/base.dart#L58) | — | — | — |
| 🧪 | [`lib/chart/candle.dart`](../lib/chart/candle.dart) | class ChartCandleLayer | [`ChartCandleLayer.paint()`](../lib/chart/candle.dart#L14) | — | — | — |
| — | [`lib/chart/chart.dart`](../lib/chart/chart.dart) | — | — | — | [`test/chart/chart_test.dart`](../test/chart/chart_test.dart) | — |
| 🧪 | [`lib/chart/controller.dart`](../lib/chart/controller.dart) | class ChartController | [`ChartController.overrideStyle()`](../lib/chart/controller.dart#L36)<br>[`ChartController.setGraph()`](../lib/chart/controller.dart#L21)<br>[`ChartController.setScene()`](../lib/chart/controller.dart#L26)<br>[`ChartController.setStyleSheet()`](../lib/chart/controller.dart#L31) | [`ChartController._advance()`](../lib/chart/controller.dart#L41) | — | — |
| 🧪 | [`lib/chart/data.dart`](../lib/chart/data.dart) | class ChartDoubleRange<br>class ChartScene<br>class ChartSceneBuilder<br>class ChartSceneGraph<br>class ChartSpace | [`ChartSceneBuilder.addLayer()`](../lib/chart/data.dart#L54)<br>[`ChartSceneBuilder.build()`](../lib/chart/data.dart#L58)<br>[`ChartSceneGraph.withScene()`](../lib/chart/data.dart#L35)<br>[`ChartSceneGraph.withStyleOverride()`](../lib/chart/data.dart#L43)<br>[`ChartSceneGraph.withStyleSheet()`](../lib/chart/data.dart#L39) | — | — | — |
| 🧪 | [`lib/chart/grid.dart`](../lib/chart/grid.dart) | class ChartGridLayer | [`ChartGridLayer.paint()`](../lib/chart/grid.dart#L30) | — | — | — |
| 🧪 | [`lib/chart/line.dart`](../lib/chart/line.dart) | class ChartLineLayer | [`ChartLineLayer.paint()`](../lib/chart/line.dart#L15) | [`ChartLineLayer._drawDashedPath()`](../lib/chart/line.dart#L32) | — | — |
| 🧪 | [`lib/chart/node.dart`](../lib/chart/node.dart) | class ChartAreaNode<br>class ChartBarGeometry<br>class ChartBarNode<br>class ChartCandleGeometry<br>class ChartCandleNode<br>class ChartLineNode<br>class ChartPoint<br>class ChartPolylineGeometry | [`ChartAreaNode.writeFill()`](../lib/chart/node.dart#L61)<br>[`ChartPolylineGeometry.writeToPath()`](../lib/chart/node.dart#L36) | — | — | — |
| 🧪 | [`lib/chart/painter.dart`](../lib/chart/painter.dart) | class ChartRenderer<br>class ChartSurface<br>class ChartSurfacePainter | [`ChartRenderer.render()`](../lib/chart/painter.dart#L9)<br>[`ChartSurface.build()`](../lib/chart/painter.dart#L63)<br>[`ChartSurfacePainter.paint()`](../lib/chart/painter.dart#L84)<br>[`ChartSurfacePainter.shouldRebuildSemantics()`](../lib/chart/painter.dart#L104)<br>[`ChartSurfacePainter.shouldRepaint()`](../lib/chart/painter.dart#L90) | — | — | — |
| 🧪 | [`lib/chart/style.dart`](../lib/chart/style.dart) | class ChartPaintStyle<br>class ChartStyleEntry<br>class ChartStyleKey<br>class ChartStyleSheet | [`ChartStyleSheet.contains()`](../lib/chart/style.dart#L52)<br>[`ChartStyleSheet.override()`](../lib/chart/style.dart#L70)<br>[`ChartStyleSheet.resolve()`](../lib/chart/style.dart#L61) | — | — | — |
| 🧪 | [`lib/development/charting.dart`](../lib/development/charting.dart) | class DevelopmentChartAssembler<br>class DevelopmentChartStyles | [`DevelopmentChartAssembler.bootstrapGraph()`](../lib/development/charting.dart#L151)<br>[`DevelopmentChartAssembler.styleSheet()`](../lib/development/charting.dart#L161)<br>[`DevelopmentChartStyles.sheet()`](../lib/development/charting.dart#L33) | [`DevelopmentChartAssembler._buildCandleLayer()`](../lib/development/charting.dart#L310)<br>[`DevelopmentChartAssembler._buildCloseLineLayer()`](../lib/development/charting.dart#L357)<br>[`DevelopmentChartAssembler._buildGridLayer()`](../lib/development/charting.dart#L247)<br>[`DevelopmentChartAssembler._buildVolumeLayer()`](../lib/development/charting.dart#L270)<br>[`DevelopmentChartAssembler._determineHalfWidth()`](../lib/development/charting.dart#L374) | — | — |
| 🧪 | [`lib/development/environment.dart`](../lib/development/environment.dart) | class DevelopmentEnvironment | [`DevelopmentEnvironment.dispose()`](../lib/development/environment.dart#L115)<br>[`DevelopmentEnvironment.updateDevicePixelRatio()`](../lib/development/environment.dart#L104)<br>[`handleFocusGain()`](../lib/development/environment.dart#L224)<br>[`handleFocusLost()`](../lib/development/environment.dart#L226) | [`DevelopmentEnvironment._handleLog()`](../lib/development/environment.dart#L135)<br>[`DevelopmentEnvironment._handleSamples()`](../lib/development/environment.dart#L125)<br>[`DevelopmentEnvironment._handleViewportChange()`](../lib/development/environment.dart#L130)<br>[`DevelopmentEnvironment._refreshChart()`](../lib/development/environment.dart#L146)<br>[`DevelopmentEnvironment._requestActiveRange()`](../lib/development/environment.dart#L139) | — | — |
| 🧪 | [`lib/development/input_profiles.dart`](../lib/development/input_profiles.dart) | class DevelopmentGestureProfile<br>class DevelopmentKeyboardProfile<br>class DevelopmentPointerProfile | — | [`DevelopmentKeyboardProfile._createBindings()`](../lib/development/input_profiles.dart#L17) | — | — |
| 🪦 🧪 | [`lib/development/main.dart`](../lib/development/main.dart) | class DevelopmentApp<br>class DevelopmentShell<br>class _DevelopmentContent<br>class _DevelopmentMetric<br>class _DevelopmentStatusBar | [`DevelopmentApp.build()`](../lib/development/main.dart#L27)<br>[`DevelopmentShell.build()`](../lib/development/main.dart#L51)<br>[`_DevelopmentContent.build()`](../lib/development/main.dart#L128)<br>[`_DevelopmentMetric.build()`](../lib/development/main.dart#L205)<br>[`_DevelopmentStatusBar.build()`](../lib/development/main.dart#L164) | — | — | — |
| 🧪 | [`lib/development/provider.dart`](../lib/development/provider.dart) | class DevelopmentBufferDataProvider | — | [`_initialPriceForSymbol()`](../lib/development/provider.dart#L100)<br>[`_seasonalAdjustment()`](../lib/development/provider.dart#L109)<br>[`_seedForSymbol()`](../lib/development/provider.dart#L86)<br>[`_volumeForEpoch()`](../lib/development/provider.dart#L121) | — | — |
| 🧪 | [`lib/development/viewport.dart`](../lib/development/viewport.dart) | class DevelopmentViewport | [`DevelopmentViewport.jumpToEnd()`](../lib/development/viewport.dart#L88)<br>[`DevelopmentViewport.scaleAround()`](../lib/development/viewport.dart#L79)<br>[`DevelopmentViewport.shiftByFraction()`](../lib/development/viewport.dart#L62)<br>[`DevelopmentViewport.shiftMicros()`](../lib/development/viewport.dart#L49)<br>[`DevelopmentViewport.zoomByFactor()`](../lib/development/viewport.dart#L70) | [`DevelopmentViewport._clampWindow()`](../lib/development/viewport.dart#L99) | — | — |
| 🧪 | [`lib/input/focus_manager.dart`](../lib/input/focus_manager.dart) | class InputFocusManager | [`InputFocusManager.clearFocus()`](../lib/input/focus_manager.dart#L58) | [`InputFocusManager._refreshKeyboardShortcuts()`](../lib/input/focus_manager.dart#L77) | — | [`test/input/router_test.dart`](../test/input/router_test.dart) |
| 🧪 | [`lib/input/gesture.dart`](../lib/input/gesture.dart) | abstract class GestureProfile<br>class DoubleTapGestureInputEvent<br>class EmptyGestureProfile<br>class ScaleEndGestureInputEvent<br>class ScaleStartGestureInputEvent<br>class ScaleUpdateGestureInputEvent<br>class TapCancelGestureInputEvent<br>class TapDownGestureInputEvent<br>class TapUpGestureInputEvent<br>sealed class GestureInputEvent | — | — | — | [`test/input/router_test.dart`](../test/input/router_test.dart) |
| 🧪 | [`lib/input/input.dart`](../lib/input/input.dart) | abstract class InputEvent<br>abstract class InputRouterHandle<br>class InputDispatchContext<br>class InputFocusChange<br>class InputFocusNode<br>typedef FocusRequest<br>typedef ShortcutInvoke | — | — | — | [`test/input/router_test.dart`](../test/input/router_test.dart) |
| 🧪 | [`lib/input/keyboard.dart`](../lib/input/keyboard.dart) | abstract class KeyboardProfile<br>class EmptyKeyboardProfile<br>class KeyboardBinding<br>class KeyboardChord<br>class KeyboardInputEvent<br>class ShortcutRegistration<br>class ShortcutsRegistry<br>typedef ActionId<br>typedef BindingHandler | [`KeyboardChord.toString()`](../lib/input/keyboard.dart#L152)<br>[`ShortcutsRegistry.clearScope()`](../lib/input/keyboard.dart#L66)<br>[`ShortcutsRegistry.invoke()`](../lib/input/keyboard.dart#L70)<br>[`ShortcutsRegistry.register()`](../lib/input/keyboard.dart#L57) | — | — | [`test/input/router_test.dart`](../test/input/router_test.dart) |
| 🧪 | [`lib/input/pointer.dart`](../lib/input/pointer.dart) | abstract class PointerProfile<br>class EmptyPointerProfile<br>class PointerInputEvent | — | — | — | [`test/input/router_test.dart`](../test/input/router_test.dart) |
| 🧪 | [`lib/input/profile.dart`](../lib/input/profile.dart) | class DeviceCalibration<br>class InputProfile<br>class InputSettings<br>class OffsetPkg<br>class ScalarPkg | — | — | — | [`test/input/router_test.dart`](../test/input/router_test.dart) |
| — | [`lib/input/router.dart`](../lib/input/router.dart) | class InputRouter | [`InputRouter.routeTapCancel()`](../lib/input/router.dart#L36) | — | [`test/input/router_test.dart`](../test/input/router_test.dart) | — |

---

### Tests missing intent comments
- None

> _Every `test` and `testWidgets` block should include an intent comment explaining its purpose._

### Stray test files
- None

> _A test is considered stray if it lacks a `lib/` import or its path/name doesn't mirror the file it covers—`lib/foo/bar.dart` expects `test/foo/bar_test.dart`._

### Possibly duplicate functions
- `Widget build(BuildContext context)`
  - [`lib/chart/painter.dart`](../lib/chart/painter.dart#L63)
  - [`lib/development/main.dart`](../lib/development/main.dart#L128)
  - [`lib/development/main.dart`](../lib/development/main.dart#L164)
  - [`lib/development/main.dart`](../lib/development/main.dart#L205)
  - [`lib/development/main.dart`](../lib/development/main.dart#L27)
  - [`lib/development/main.dart`](../lib/development/main.dart#L51)
- `void clear()`
  - [`lib/buffer/worker.dart`](../lib/buffer/worker.dart#L196)
  - [`lib/buffer/worker.dart`](../lib/buffer/worker.dart#L296)
- `void dispose()`
  - [`lib/buffer/client.dart`](../lib/buffer/client.dart#L174)
  - [`lib/development/environment.dart`](../lib/development/environment.dart#L115)
- `void main()`
  - [`test/buffer/channel_test.dart`](../test/buffer/channel_test.dart#L3)
  - [`test/buffer/client_test.dart`](../test/buffer/client_test.dart#L4)
  - [`test/chart/chart_test.dart`](../test/chart/chart_test.dart#L7)
  - [`test/input/router_test.dart`](../test/input/router_test.dart#L75)
- `void paint(ChartRenderContext context)`
  - [`lib/chart/area.dart`](../lib/chart/area.dart#L13)
  - [`lib/chart/bar.dart`](../lib/chart/bar.dart#L14)
  - [`lib/chart/candle.dart`](../lib/chart/candle.dart#L14)
  - [`lib/chart/grid.dart`](../lib/chart/grid.dart#L30)
  - [`lib/chart/line.dart`](../lib/chart/line.dart#L15)

> _Functions with identical signatures may indicate duplication._

