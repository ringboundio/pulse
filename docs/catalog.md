<div style="font-size:2em;font-weight:bold;margin-bottom:0.5em;">Library Catalog</div>

Generated on 2025-10-29 08:51 UTC by `go run ./tool/cmd/catalog`.

<table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;">
  <tr>
    <td>
      <table class="catalog-table" style="width:100%">
        <colgroup>
          <col class="col-status" style="width: 1.09%">
          <col class="col-file" style="width: 14.29%">
          <col class="col-public-types" style="width: 12.82%">
          <col class="col-private-types" style="width: 11.72%">
          <col class="col-public-funcs" style="width: 19.78%">
          <col class="col-private-funcs" style="width: 17.58%">
          <col class="col-file-test" style="width: 11.36%">
          <col class="col-related-tests" style="width: 11.36%">
        </colgroup>
        <thead>
          <tr>
            <th scope="col"> 📋 </th>
            <th scope="col">File</th>
            <th scope="col">Public types</th>
            <th scope="col">Private types</th>
            <th scope="col">Public functions</th>
            <th scope="col">Private functions</th>
            <th scope="col">File test</th>
            <th scope="col">Related tests</th>
          </tr>
        </thead>
        <tbody>
        <tr>
          <td>—</td>
          <td><a href="../lib/buffer/channel.dart"><code>lib/buffer/channel.dart</code></a></td>
          <td><a href="../lib/buffer/channel.dart#L374"><code>abstract class BufferCommand</code></a><br><a href="../lib/buffer/channel.dart#L407"><code>abstract class BufferDataProvider</code></a><br><a href="../lib/buffer/channel.dart#L281"><code>abstract class BufferEvent</code></a><br><a href="../lib/buffer/channel.dart#L119"><code>abstract class BufferSampleSeries</code></a><br><a href="../lib/buffer/channel.dart#L26"><code>class BufferConfig</code></a><br><a href="../lib/buffer/channel.dart#L401"><code>class BufferDisposeCommand</code></a><br><a href="../lib/buffer/channel.dart#L20"><code>class BufferEndpoint</code></a><br><a href="../lib/buffer/channel.dart#L14"><code>class BufferInterval</code></a><br><a href="../lib/buffer/channel.dart#L361"><code>class BufferLogEvent</code></a><br><a href="../lib/buffer/channel.dart#L38"><code>class BufferPolicy</code></a><br><a href="../lib/buffer/channel.dart#L49"><code>class BufferRange</code></a><br><a href="../lib/buffer/channel.dart#L283"><code>class BufferReadyEvent</code></a><br><a href="../lib/buffer/channel.dart#L64"><code>class BufferSample</code></a><br><a href="../lib/buffer/channel.dart#L82"><code>class BufferSampleCodec</code></a><br><a href="../lib/buffer/channel.dart#L289"><code>class BufferSamplesEvent</code></a><br><a href="../lib/buffer/channel.dart#L395"><code>class BufferSendRangeCommand</code></a><br><a href="../lib/buffer/channel.dart#L376"><code>class BufferSetConfigCommand</code></a><br><a href="../lib/buffer/channel.dart#L388"><code>class BufferSetPolicyCommand</code></a><br><a href="../lib/buffer/channel.dart#L8"><code>class BufferSymbol</code></a><br><a href="../lib/buffer/channel.dart#L368"><code>class BufferTerminatedEvent</code></a><br><a href="../lib/buffer/channel.dart#L6"><code>enum BufferLogLevel</code></a><br><a href="../lib/buffer/channel.dart#L3"><code>typedef BufferCommandPort</code></a><br><a href="../lib/buffer/channel.dart#L5"><code>typedef BufferEventPort</code></a></td>
          <td><a href="../lib/buffer/channel.dart#L161"><code>class _EmptyBufferSampleSeries</code></a><br><a href="../lib/buffer/channel.dart#L233"><code>class _EncodedBufferSampleSeries</code></a><br><a href="../lib/buffer/channel.dart#L198"><code>class _ListBufferSampleSeries</code></a></td>
          <td><a href="../lib/buffer/channel.dart#L56"><code>BufferRange.expand()</code></a><br><a href="../lib/buffer/channel.dart#L106"><code>BufferSampleCodec.readSample()</code></a><br><a href="../lib/buffer/channel.dart#L96"><code>BufferSampleCodec.writeSample()</code></a><br><a href="../lib/buffer/channel.dart#L140"><code>BufferSampleSeries.materializeAt()</code></a></td>
          <td><a href="../lib/buffer/channel.dart#L344"><code>BufferSamplesEvent._ensureMaterializedData()</code></a><br><a href="../lib/buffer/channel.dart#L187"><code>_EmptyBufferSampleSeries.closeAt()</code></a><br><a href="../lib/buffer/channel.dart#L171"><code>_EmptyBufferSampleSeries.epochMicrosAt()</code></a><br><a href="../lib/buffer/channel.dart#L179"><code>_EmptyBufferSampleSeries.highAt()</code></a><br><a href="../lib/buffer/channel.dart#L183"><code>_EmptyBufferSampleSeries.lowAt()</code></a><br><a href="../lib/buffer/channel.dart#L175"><code>_EmptyBufferSampleSeries.openAt()</code></a><br><a href="../lib/buffer/channel.dart#L191"><code>_EmptyBufferSampleSeries.volumeAt()</code></a><br><a href="../lib/buffer/channel.dart#L242"><code>_EncodedBufferSampleSeries._offset()</code></a><br><a href="../lib/buffer/channel.dart#L270"><code>_EncodedBufferSampleSeries.closeAt()</code></a><br><a href="../lib/buffer/channel.dart#L246"><code>_EncodedBufferSampleSeries.epochMicrosAt()</code></a><br><a href="../lib/buffer/channel.dart#L258"><code>_EncodedBufferSampleSeries.highAt()</code></a><br><a href="../lib/buffer/channel.dart#L264"><code>_EncodedBufferSampleSeries.lowAt()</code></a><br><a href="../lib/buffer/channel.dart#L252"><code>_EncodedBufferSampleSeries.openAt()</code></a><br><a href="../lib/buffer/channel.dart#L276"><code>_EncodedBufferSampleSeries.volumeAt()</code></a><br><a href="../lib/buffer/channel.dart#L220"><code>_ListBufferSampleSeries.closeAt()</code></a><br><a href="../lib/buffer/channel.dart#L208"><code>_ListBufferSampleSeries.epochMicrosAt()</code></a><br><a href="../lib/buffer/channel.dart#L214"><code>_ListBufferSampleSeries.highAt()</code></a><br><a href="../lib/buffer/channel.dart#L217"><code>_ListBufferSampleSeries.lowAt()</code></a><br><a href="../lib/buffer/channel.dart#L226"><code>_ListBufferSampleSeries.materializeAt()</code></a><br><a href="../lib/buffer/channel.dart#L211"><code>_ListBufferSampleSeries.openAt()</code></a><br><a href="../lib/buffer/channel.dart#L223"><code>_ListBufferSampleSeries.volumeAt()</code></a></td>
          <td><a href="../test/buffer/channel_test.dart"><code>test/buffer/channel_test.dart</code></a></td>
          <td><a href="../test/buffer/client_test.dart"><code>test/buffer/client_test.dart</code></a></td>
        </tr>
        <tr>
          <td>—</td>
          <td><a href="../lib/buffer/client.dart"><code>lib/buffer/client.dart</code></a></td>
          <td><a href="../lib/buffer/client.dart#L6"><code>abstract class BufferClient</code></a></td>
          <td><a href="../lib/buffer/client.dart#L34"><code>class _IsolateBufferClient</code></a></td>
          <td>—</td>
          <td><a href="../lib/buffer/client.dart#L164"><code>_IsolateBufferClient._disposeStreams()</code></a><br><a href="../lib/buffer/client.dart#L130"><code>_IsolateBufferClient._enqueue()</code></a><br><a href="../lib/buffer/client.dart#L139"><code>_IsolateBufferClient._handleEvent()</code></a><br><a href="../lib/buffer/client.dart#L174"><code>_IsolateBufferClient.dispose()</code></a></td>
          <td><a href="../test/buffer/client_test.dart"><code>test/buffer/client_test.dart</code></a></td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/buffer/sample_store.dart"><code>lib/buffer/sample_store.dart</code></a></td>
          <td><a href="../lib/buffer/sample_store.dart#L15"><code>class BufferSampleStore</code></a><br><a href="../lib/buffer/sample_store.dart#L5"><code>class BufferSampleWindowEncoding</code></a></td>
          <td><a href="../lib/buffer/sample_store.dart#L360"><code>class _ColumnBufferSampleSeries</code></a></td>
          <td><a href="../lib/buffer/sample_store.dart#L37"><code>BufferSampleStore.clear()</code></a><br><a href="../lib/buffer/sample_store.dart#L136"><code>BufferSampleStore.covers()</code></a><br><a href="../lib/buffer/sample_store.dart#L112"><code>BufferSampleStore.encodeWindow()</code></a><br><a href="../lib/buffer/sample_store.dart#L72"><code>BufferSampleStore.extractSeries()</code></a><br><a href="../lib/buffer/sample_store.dart#L95"><code>BufferSampleStore.extractWindow()</code></a><br><a href="../lib/buffer/sample_store.dart#L45"><code>BufferSampleStore.merge()</code></a><br><a href="../lib/buffer/sample_store.dart#L170"><code>BufferSampleStore.toList()</code></a><br><a href="../lib/buffer/sample_store.dart#L151"><code>BufferSampleStore.trim()</code></a></td>
          <td><a href="../lib/buffer/sample_store.dart#L188"><code>BufferSampleStore._appendSorted()</code></a><br><a href="../lib/buffer/sample_store.dart#L255"><code>BufferSampleStore._ensureColumnCaches()</code></a><br><a href="../lib/buffer/sample_store.dart#L294"><code>BufferSampleStore._ensurePackedCache()</code></a><br><a href="../lib/buffer/sample_store.dart#L323"><code>BufferSampleStore._ensureSorted()</code></a><br><a href="../lib/buffer/sample_store.dart#L177"><code>BufferSampleStore._insert()</code></a><br><a href="../lib/buffer/sample_store.dart#L250"><code>BufferSampleStore._invalidateCaches()</code></a><br><a href="../lib/buffer/sample_store.dart#L236"><code>BufferSampleStore._lowerBound()</code></a><br><a href="../lib/buffer/sample_store.dart#L201"><code>BufferSampleStore._mergeWith()</code></a><br><a href="../lib/buffer/sample_store.dart#L340"><code>BufferSampleStore._writePackedTo()</code></a><br><a href="../lib/buffer/sample_store.dart#L391"><code>_ColumnBufferSampleSeries._index()</code></a><br><a href="../lib/buffer/sample_store.dart#L407"><code>_ColumnBufferSampleSeries.closeAt()</code></a><br><a href="../lib/buffer/sample_store.dart#L395"><code>_ColumnBufferSampleSeries.epochMicrosAt()</code></a><br><a href="../lib/buffer/sample_store.dart#L401"><code>_ColumnBufferSampleSeries.highAt()</code></a><br><a href="../lib/buffer/sample_store.dart#L404"><code>_ColumnBufferSampleSeries.lowAt()</code></a><br><a href="../lib/buffer/sample_store.dart#L413"><code>_ColumnBufferSampleSeries.materializeAt()</code></a><br><a href="../lib/buffer/sample_store.dart#L398"><code>_ColumnBufferSampleSeries.openAt()</code></a><br><a href="../lib/buffer/sample_store.dart#L410"><code>_ColumnBufferSampleSeries.volumeAt()</code></a></td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/buffer/worker.dart"><code>lib/buffer/worker.dart</code></a></td>
          <td><a href="../lib/buffer/worker.dart#L6"><code>class BufferWorkerBootstrap</code></a></td>
          <td><a href="../lib/buffer/worker.dart#L24"><code>class _BufferWorker</code></a><br><a href="../lib/buffer/worker.dart#L223"><code>class _ConfigState</code></a><br><a href="../lib/buffer/worker.dart#L233"><code>class _RangeSlot</code></a></td>
          <td><a href="../lib/buffer/worker.dart#L16"><code>bufferWorkerMain()</code></a></td>
          <td><a href="../lib/buffer/worker.dart#L159"><code>_BufferWorker._emitWindow()</code></a><br><a href="../lib/buffer/worker.dart#L65"><code>_BufferWorker._handleCommand()</code></a><br><a href="../lib/buffer/worker.dart#L144"><code>_BufferWorker._handleDispose()</code></a><br><a href="../lib/buffer/worker.dart#L71"><code>_BufferWorker._handlePayload()</code></a><br><a href="../lib/buffer/worker.dart#L110"><code>_BufferWorker._handleSendRange()</code></a><br><a href="../lib/buffer/worker.dart#L92"><code>_BufferWorker._handleSetConfig()</code></a><br><a href="../lib/buffer/worker.dart#L102"><code>_BufferWorker._handleSetPolicy()</code></a><br><a href="../lib/buffer/worker.dart#L131"><code>_BufferWorker._scheduleHalo()</code></a><br><a href="../lib/buffer/worker.dart#L151"><code>_BufferWorker._trimToRetention()</code></a><br><a href="../lib/buffer/worker.dart#L59"><code>_BufferWorker.run()</code></a><br><a href="../lib/buffer/worker.dart#L228"><code>_ConfigState.assign()</code></a><br><a href="../lib/buffer/worker.dart#L230"><code>_ConfigState.require()</code></a><br><a href="../lib/buffer/worker.dart#L243"><code>_RangeSlot.assign()</code></a><br><a href="../lib/buffer/worker.dart#L248"><code>_RangeSlot.clear()</code></a><br><a href="../lib/buffer/worker.dart#L252"><code>_RangeSlot.value()</code></a></td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/chart/area.dart"><code>lib/chart/area.dart</code></a></td>
          <td><a href="../lib/chart/area.dart#L5"><code>class ChartAreaLayer</code></a></td>
          <td>—</td>
          <td><a href="../lib/chart/area.dart#L13"><code>ChartAreaLayer.paint()</code></a></td>
          <td>—</td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/chart/bar.dart"><code>lib/chart/bar.dart</code></a></td>
          <td><a href="../lib/chart/bar.dart#L5"><code>class ChartBarLayer</code></a></td>
          <td>—</td>
          <td><a href="../lib/chart/bar.dart#L18"><code>ChartBarLayer.paint()</code></a></td>
          <td><a href="../lib/chart/bar.dart#L45"><code>ChartBarLayer._render()</code></a></td>
          <td>—</td>
          <td><a href="../test/chart/painter_test.dart"><code>test/chart/painter_test.dart</code></a></td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/chart/candle.dart"><code>lib/chart/candle.dart</code></a></td>
          <td><a href="../lib/chart/candle.dart#L5"><code>class ChartCandleLayer</code></a></td>
          <td>—</td>
          <td><a href="../lib/chart/candle.dart#L13"><code>ChartCandleLayer.paint()</code></a></td>
          <td>—</td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>—</td>
          <td><a href="../lib/chart/controller.dart"><code>lib/chart/controller.dart</code></a></td>
          <td><a href="../lib/chart/controller.dart#L5"><code>class ChartController</code></a></td>
          <td>—</td>
          <td><a href="../lib/chart/controller.dart#L21"><code>ChartController.setGraph()</code></a><br><a href="../lib/chart/controller.dart#L26"><code>ChartController.setScene()</code></a><br><a href="../lib/chart/controller.dart#L31"><code>ChartController.setStyleSheet()</code></a></td>
          <td><a href="../lib/chart/controller.dart#L44"><code>ChartController._advance()</code></a></td>
          <td><a href="../test/chart/controller_test.dart"><code>test/chart/controller_test.dart</code></a></td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/chart/data.dart"><code>lib/chart/data.dart</code></a></td>
          <td><a href="../lib/chart/data.dart#L3"><code>class ChartDoubleRange</code></a><br><a href="../lib/chart/data.dart#L21"><code>class ChartScene</code></a><br><a href="../lib/chart/data.dart#L48"><code>class ChartSceneBuilder</code></a><br><a href="../lib/chart/data.dart#L29"><code>class ChartSceneGraph</code></a><br><a href="../lib/chart/data.dart#L12"><code>class ChartSpace</code></a></td>
          <td>—</td>
          <td><a href="../lib/chart/data.dart#L54"><code>ChartSceneBuilder.addLayer()</code></a><br><a href="../lib/chart/data.dart#L58"><code>ChartSceneBuilder.build()</code></a><br><a href="../lib/chart/data.dart#L35"><code>ChartSceneGraph.withScene()</code></a><br><a href="../lib/chart/data.dart#L43"><code>ChartSceneGraph.withStyleOverride()</code></a><br><a href="../lib/chart/data.dart#L39"><code>ChartSceneGraph.withStyleSheet()</code></a></td>
          <td>—</td>
          <td>—</td>
          <td><a href="../test/chart/controller_test.dart"><code>test/chart/controller_test.dart</code></a><br><a href="../test/chart/painter_test.dart"><code>test/chart/painter_test.dart</code></a></td>
        </tr>
        <tr>
          <td>—</td>
          <td><a href="../lib/chart/foundation.dart"><code>lib/chart/foundation.dart</code></a></td>
          <td><a href="../lib/chart/foundation.dart#L201"><code>abstract class ChartLayer</code></a><br><a href="../lib/chart/foundation.dart#L194"><code>abstract class ChartNode</code></a><br><a href="../lib/chart/foundation.dart#L16"><code>class ChartLayerKey</code></a><br><a href="../lib/chart/foundation.dart#L33"><code>class ChartNodeKey</code></a><br><a href="../lib/chart/foundation.dart#L119"><code>class ChartPaintBundle</code></a><br><a href="../lib/chart/foundation.dart#L170"><code>class ChartPaintCache</code></a><br><a href="../lib/chart/foundation.dart#L163"><code>class ChartPaintCacheEntry</code></a><br><a href="../lib/chart/foundation.dart#L99"><code>class ChartRenderContext</code></a><br><a href="../lib/chart/foundation.dart#L82"><code>class ChartScratchSpace</code></a><br><a href="../lib/chart/foundation.dart#L50"><code>class ChartTransform</code></a><br><a href="../lib/chart/foundation.dart#L5"><code>typedef ChartPathPainter</code></a></td>
          <td>—</td>
          <td><a href="../lib/chart/foundation.dart#L158"><code>ChartPaintBundle.strokePath()</code></a><br><a href="../lib/chart/foundation.dart#L176"><code>ChartPaintCache.resolve()</code></a><br><a href="../lib/chart/foundation.dart#L92"><code>ChartScratchSpace.reset()</code></a><br><a href="../lib/chart/foundation.dart#L77"><code>ChartTransform.project()</code></a><br><a href="../lib/chart/foundation.dart#L68"><code>ChartTransform.projectX()</code></a><br><a href="../lib/chart/foundation.dart#L72"><code>ChartTransform.projectY()</code></a></td>
          <td><a href="../lib/chart/foundation.dart#L7"><code>_noopPathPainter()</code></a><br><a href="../lib/chart/foundation.dart#L9"><code>_strokePainterFor()</code></a></td>
          <td><a href="../test/chart/foundation_test.dart"><code>test/chart/foundation_test.dart</code></a></td>
          <td><a href="../test/chart/controller_test.dart"><code>test/chart/controller_test.dart</code></a><br><a href="../test/chart/node_test.dart"><code>test/chart/node_test.dart</code></a><br><a href="../test/chart/painter_test.dart"><code>test/chart/painter_test.dart</code></a></td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/chart/grid.dart"><code>lib/chart/grid.dart</code></a></td>
          <td><a href="../lib/chart/grid.dart#L6"><code>class ChartGridLayer</code></a></td>
          <td>—</td>
          <td><a href="../lib/chart/grid.dart#L30"><code>ChartGridLayer.paint()</code></a></td>
          <td>—</td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/chart/line.dart"><code>lib/chart/line.dart</code></a></td>
          <td><a href="../lib/chart/line.dart#L5"><code>class ChartLineLayer</code></a></td>
          <td>—</td>
          <td><a href="../lib/chart/line.dart#L13"><code>ChartLineLayer.paint()</code></a></td>
          <td>—</td>
          <td>—</td>
          <td><a href="../test/chart/controller_test.dart"><code>test/chart/controller_test.dart</code></a><br><a href="../test/chart/painter_test.dart"><code>test/chart/painter_test.dart</code></a></td>
        </tr>
        <tr>
          <td>—</td>
          <td><a href="../lib/chart/node.dart"><code>lib/chart/node.dart</code></a></td>
          <td><a href="../lib/chart/node.dart#L138"><code>class ChartAreaNode</code></a><br><a href="../lib/chart/node.dart#L185"><code>class ChartBarGeometry</code></a><br><a href="../lib/chart/node.dart#L200"><code>class ChartBarNode</code></a><br><a href="../lib/chart/node.dart#L244"><code>class ChartCandleGeometry</code></a><br><a href="../lib/chart/node.dart#L260"><code>class ChartCandleNode</code></a><br><a href="../lib/chart/node.dart#L179"><code>class ChartLineNode</code></a><br><a href="../lib/chart/node.dart#L5"><code>class ChartPoint</code></a><br><a href="../lib/chart/node.dart#L12"><code>class ChartPolylineGeometry</code></a></td>
          <td>—</td>
          <td><a href="../lib/chart/node.dart#L147"><code>ChartAreaNode.fillPathForTransform()</code></a><br><a href="../lib/chart/node.dart#L208"><code>ChartBarNode.pathForTransform()</code></a><br><a href="../lib/chart/node.dart#L269"><code>ChartCandleNode.bodyPathForTransform()</code></a><br><a href="../lib/chart/node.dart#L274"><code>ChartCandleNode.wickPathForTransform()</code></a><br><a href="../lib/chart/node.dart#L54"><code>ChartPolylineGeometry.dashedPathForTransform()</code></a><br><a href="../lib/chart/node.dart#L44"><code>ChartPolylineGeometry.pathForTransform()</code></a><br><a href="../lib/chart/node.dart#L49"><code>ChartPolylineGeometry.projectedPositionsForTransform()</code></a></td>
          <td><a href="../lib/chart/node.dart#L279"><code>ChartCandleNode._ensurePaths()</code></a><br><a href="../lib/chart/node.dart#L106"><code>ChartPolylineGeometry._buildDashedPath()</code></a><br><a href="../lib/chart/node.dart#L72"><code>ChartPolylineGeometry._ensureCache()</code></a></td>
          <td><a href="../test/chart/node_test.dart"><code>test/chart/node_test.dart</code></a></td>
          <td><a href="../test/chart/controller_test.dart"><code>test/chart/controller_test.dart</code></a><br><a href="../test/chart/painter_test.dart"><code>test/chart/painter_test.dart</code></a></td>
        </tr>
        <tr>
          <td>—</td>
          <td><a href="../lib/chart/painter.dart"><code>lib/chart/painter.dart</code></a></td>
          <td><a href="../lib/chart/painter.dart#L6"><code>class ChartRenderer</code></a><br><a href="../lib/chart/painter.dart#L51"><code>class ChartSurface</code></a><br><a href="../lib/chart/painter.dart#L71"><code>class ChartSurfacePainter</code></a></td>
          <td>—</td>
          <td><a href="../lib/chart/painter.dart#L63"><code>ChartSurface.build()</code></a><br><a href="../lib/chart/painter.dart#L84"><code>ChartSurfacePainter.paint()</code></a><br><a href="../lib/chart/painter.dart#L103"><code>ChartSurfacePainter.shouldRebuildSemantics()</code></a><br><a href="../lib/chart/painter.dart#L96"><code>ChartSurfacePainter.shouldRepaint()</code></a></td>
          <td>—</td>
          <td><a href="../test/chart/painter_test.dart"><code>test/chart/painter_test.dart</code></a></td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/chart/style.dart"><code>lib/chart/style.dart</code></a></td>
          <td><a href="../lib/chart/style.dart#L20"><code>class ChartPaintStyle</code></a><br><a href="../lib/chart/style.dart#L38"><code>class ChartStyleEntry</code></a><br><a href="../lib/chart/style.dart#L3"><code>class ChartStyleKey</code></a><br><a href="../lib/chart/style.dart#L45"><code>class ChartStyleSheet</code></a></td>
          <td>—</td>
          <td><a href="../lib/chart/style.dart#L52"><code>ChartStyleSheet.contains()</code></a><br><a href="../lib/chart/style.dart#L61"><code>ChartStyleSheet.resolve()</code></a></td>
          <td>—</td>
          <td>—</td>
          <td><a href="../test/chart/controller_test.dart"><code>test/chart/controller_test.dart</code></a><br><a href="../test/chart/foundation_test.dart"><code>test/chart/foundation_test.dart</code></a><br><a href="../test/chart/node_test.dart"><code>test/chart/node_test.dart</code></a><br><a href="../test/chart/painter_test.dart"><code>test/chart/painter_test.dart</code></a></td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/development/bench/benchmark.dart"><code>lib/development/bench/benchmark.dart</code></a></td>
          <td><a href="../lib/development/bench/benchmark.dart#L5"><code>class BenchmarkConfig</code></a><br><a href="../lib/development/bench/benchmark.dart#L31"><code>class BenchmarkDefinition</code></a><br><a href="../lib/development/bench/benchmark.dart#L47"><code>class BenchmarkResult</code></a><br><a href="../lib/development/bench/benchmark.dart#L72"><code>class BenchmarkRunner</code></a><br><a href="../lib/development/bench/benchmark.dart#L28"><code>typedef BenchmarkBody</code></a><br><a href="../lib/development/bench/benchmark.dart#L25"><code>typedef BenchmarkSetup</code></a><br><a href="../lib/development/bench/benchmark.dart#L29"><code>typedef BenchmarkTag</code></a><br><a href="../lib/development/bench/benchmark.dart#L27"><code>typedef BenchmarkTeardown</code></a></td>
          <td>—</td>
          <td><a href="../lib/development/bench/benchmark.dart#L170"><code>blackHole()</code></a><br><a href="../lib/development/bench/benchmark.dart#L188"><code>drainBlackHole()</code></a></td>
          <td>—</td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/development/bench/buffer_bench.dart"><code>lib/development/bench/buffer_bench.dart</code></a></td>
          <td>—</td>
          <td><a href="../lib/development/bench/buffer_bench.dart#L167"><code>class _BufferWorkerHarness</code></a><br><a href="../lib/development/bench/buffer_bench.dart#L127"><code>class _DatasetBufferProvider</code></a><br><a href="../lib/development/bench/buffer_bench.dart#L150"><code>class _WindowToken</code></a></td>
          <td><a href="../lib/development/bench/buffer_bench.dart#L10"><code>buildBufferBenchmarks()</code></a></td>
          <td>—</td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/development/bench/chart_bench.dart"><code>lib/development/bench/chart_bench.dart</code></a></td>
          <td>—</td>
          <td>—</td>
          <td><a href="../lib/development/bench/chart_bench.dart#L12"><code>buildChartBenchmarks()</code></a></td>
          <td><a href="../lib/development/bench/chart_bench.dart#L82"><code>createContext()</code></a></td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/development/bench/dataset.dart"><code>lib/development/bench/dataset.dart</code></a></td>
          <td><a href="../lib/development/bench/dataset.dart#L169"><code>class BufferBenchmarkDataset</code></a><br><a href="../lib/development/bench/dataset.dart#L14"><code>class ChartBenchmarkDataset</code></a></td>
          <td>—</td>
          <td><a href="../lib/development/bench/dataset.dart#L202"><code>BufferBenchmarkDataset.createSampleStore()</code></a><br><a href="../lib/development/bench/dataset.dart#L65"><code>ChartBenchmarkDataset.createBarGeometry()</code></a><br><a href="../lib/development/bench/dataset.dart#L52"><code>ChartBenchmarkDataset.createBaselineGeometry()</code></a><br><a href="../lib/development/bench/dataset.dart#L61"><code>ChartBenchmarkDataset.createCandleGeometry()</code></a><br><a href="../lib/development/bench/dataset.dart#L48"><code>ChartBenchmarkDataset.createPolylineGeometry()</code></a></td>
          <td><a href="../lib/development/bench/dataset.dart#L235"><code>BufferBenchmarkDataset._buildQueryRange()</code></a><br><a href="../lib/development/bench/dataset.dart#L208"><code>BufferBenchmarkDataset._buildSamples()</code></a><br><a href="../lib/development/bench/dataset.dart#L242"><code>BufferBenchmarkDataset._buildTrimRange()</code></a><br><a href="../lib/development/bench/dataset.dart#L122"><code>ChartBenchmarkDataset._buildBarBuffer()</code></a><br><a href="../lib/development/bench/dataset.dart#L95"><code>ChartBenchmarkDataset._buildCandleBuffer()</code></a><br><a href="../lib/development/bench/dataset.dart#L84"><code>ChartBenchmarkDataset._buildPolylineBuffer()</code></a><br><a href="../lib/development/bench/dataset.dart#L73"><code>ChartBenchmarkDataset._buildPolylinePoints()</code></a><br><a href="../lib/development/bench/dataset.dart#L141"><code>ChartBenchmarkDataset._buildStyleEntries()</code></a></td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/development/bench/input_bench.dart"><code>lib/development/bench/input_bench.dart</code></a></td>
          <td>—</td>
          <td><a href="../lib/development/bench/input_bench.dart#L231"><code>class _CountingKeyboardProfile</code></a><br><a href="../lib/development/bench/input_bench.dart#L260"><code>class _RecordingGestureProfile</code></a><br><a href="../lib/development/bench/input_bench.dart#L247"><code>class _RecordingPointerProfile</code></a></td>
          <td><a href="../lib/development/bench/input_bench.dart#L8"><code>buildInputBenchmarks()</code></a></td>
          <td>—</td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/development/bench/main.dart"><code>lib/development/bench/main.dart</code></a></td>
          <td>—</td>
          <td>—</td>
          <td>—</td>
          <td><a href="../lib/development/bench/main.dart#L115"><code>_formatDuration()</code></a><br><a href="../lib/development/bench/main.dart#L45"><code>_printReport()</code></a><br><a href="../lib/development/bench/main.dart#L67"><code>repeat()</code></a><br><a href="../lib/development/bench/main.dart#L71"><code>separator()</code></a></td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/development/charting.dart"><code>lib/development/charting.dart</code></a></td>
          <td><a href="../lib/development/charting.dart#L123"><code>class DevelopmentChartAssembler</code></a><br><a href="../lib/development/charting.dart#L15"><code>class DevelopmentChartStyles</code></a></td>
          <td>—</td>
          <td><a href="../lib/development/charting.dart#L151"><code>DevelopmentChartAssembler.bootstrapGraph()</code></a><br><a href="../lib/development/charting.dart#L161"><code>DevelopmentChartAssembler.styleSheet()</code></a><br><a href="../lib/development/charting.dart#L33"><code>DevelopmentChartStyles.sheet()</code></a></td>
          <td><a href="../lib/development/charting.dart#L314"><code>DevelopmentChartAssembler._buildCandleLayer()</code></a><br><a href="../lib/development/charting.dart#L360"><code>DevelopmentChartAssembler._buildCloseLineLayer()</code></a><br><a href="../lib/development/charting.dart#L249"><code>DevelopmentChartAssembler._buildGridLayer()</code></a><br><a href="../lib/development/charting.dart#L381"><code>DevelopmentChartAssembler._determineHalfWidth()</code></a></td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/development/environment.dart"><code>lib/development/environment.dart</code></a></td>
          <td><a href="../lib/development/environment.dart#L18"><code>class DevelopmentEnvironment</code></a></td>
          <td>—</td>
          <td><a href="../lib/development/environment.dart#L113"><code>DevelopmentEnvironment.dispose()</code></a><br><a href="../lib/development/environment.dart#L102"><code>DevelopmentEnvironment.updateDevicePixelRatio()</code></a></td>
          <td><a href="../lib/development/environment.dart#L133"><code>DevelopmentEnvironment._handleLog()</code></a><br><a href="../lib/development/environment.dart#L123"><code>DevelopmentEnvironment._handleSamples()</code></a><br><a href="../lib/development/environment.dart#L128"><code>DevelopmentEnvironment._handleViewportChange()</code></a><br><a href="../lib/development/environment.dart#L144"><code>DevelopmentEnvironment._refreshChart()</code></a><br><a href="../lib/development/environment.dart#L137"><code>DevelopmentEnvironment._requestActiveRange()</code></a><br><a href="../lib/development/environment.dart#L222"><code>handleFocusGain()</code></a><br><a href="../lib/development/environment.dart#L224"><code>handleFocusLost()</code></a></td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/development/input_profiles.dart"><code>lib/development/input_profiles.dart</code></a></td>
          <td><a href="../lib/development/input_profiles.dart#L164"><code>class DevelopmentGestureProfile</code></a><br><a href="../lib/development/input_profiles.dart#L8"><code>class DevelopmentKeyboardProfile</code></a><br><a href="../lib/development/input_profiles.dart#L106"><code>class DevelopmentPointerProfile</code></a></td>
          <td>—</td>
          <td>—</td>
          <td><a href="../lib/development/input_profiles.dart#L14"><code>DevelopmentKeyboardProfile._createBindings()</code></a></td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/development/main.dart"><code>lib/development/main.dart</code></a></td>
          <td><a href="../lib/development/main.dart#L19"><code>class DevelopmentApp</code></a><br><a href="../lib/development/main.dart#L43"><code>class DevelopmentShell</code></a></td>
          <td><a href="../lib/development/main.dart#L121"><code>class _DevelopmentContent</code></a><br><a href="../lib/development/main.dart#L197"><code>class _DevelopmentMetric</code></a><br><a href="../lib/development/main.dart#L157"><code>class _DevelopmentStatusBar</code></a></td>
          <td><a href="../lib/development/main.dart#L27"><code>DevelopmentApp.build()</code></a><br><a href="../lib/development/main.dart#L51"><code>DevelopmentShell.build()</code></a></td>
          <td><a href="../lib/development/main.dart#L128"><code>_DevelopmentContent.build()</code></a><br><a href="../lib/development/main.dart#L205"><code>_DevelopmentMetric.build()</code></a><br><a href="../lib/development/main.dart#L164"><code>_DevelopmentStatusBar.build()</code></a></td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/development/provider.dart"><code>lib/development/provider.dart</code></a></td>
          <td><a href="../lib/development/provider.dart#L5"><code>class DevelopmentBufferDataProvider</code></a></td>
          <td>—</td>
          <td>—</td>
          <td><a href="../lib/development/provider.dart#L100"><code>_initialPriceForSymbol()</code></a><br><a href="../lib/development/provider.dart#L109"><code>_seasonalAdjustment()</code></a><br><a href="../lib/development/provider.dart#L86"><code>_seedForSymbol()</code></a></td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/development/viewport.dart"><code>lib/development/viewport.dart</code></a></td>
          <td><a href="../lib/development/viewport.dart#L4"><code>class DevelopmentViewport</code></a></td>
          <td>—</td>
          <td><a href="../lib/development/viewport.dart#L88"><code>DevelopmentViewport.jumpToEnd()</code></a><br><a href="../lib/development/viewport.dart#L79"><code>DevelopmentViewport.scaleAround()</code></a><br><a href="../lib/development/viewport.dart#L62"><code>DevelopmentViewport.shiftByFraction()</code></a><br><a href="../lib/development/viewport.dart#L49"><code>DevelopmentViewport.shiftMicros()</code></a><br><a href="../lib/development/viewport.dart#L70"><code>DevelopmentViewport.zoomByFactor()</code></a></td>
          <td>—</td>
          <td>—</td>
          <td>—</td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/input/core.dart"><code>lib/input/core.dart</code></a></td>
          <td><a href="../lib/input/core.dart#L473"><code>abstract class GestureInputEvent</code></a><br><a href="../lib/input/core.dart#L455"><code>abstract class GestureProfile</code></a><br><a href="../lib/input/core.dart#L3"><code>abstract class InputEvent</code></a><br><a href="../lib/input/core.dart#L7"><code>abstract class InputRouter</code></a><br><a href="../lib/input/core.dart#L256"><code>abstract class KeyboardProfile</code></a><br><a href="../lib/input/core.dart#L421"><code>abstract class PointerProfile</code></a><br><a href="../lib/input/core.dart#L153"><code>class DeviceCalibration</code></a><br><a href="../lib/input/core.dart#L493"><code>class DoubleTapGestureInputEvent</code></a><br><a href="../lib/input/core.dart#L463"><code>class EmptyGestureProfile</code></a><br><a href="../lib/input/core.dart#L266"><code>class EmptyKeyboardProfile</code></a><br><a href="../lib/input/core.dart#L429"><code>class EmptyPointerProfile</code></a><br><a href="../lib/input/core.dart#L34"><code>class InputDispatchContext</code></a><br><a href="../lib/input/core.dart#L11"><code>class InputFocusChange</code></a><br><a href="../lib/input/core.dart#L16"><code>class InputFocusNode</code></a><br><a href="../lib/input/core.dart#L61"><code>class InputProfile</code></a><br><a href="../lib/input/core.dart#L165"><code>class InputSettings</code></a><br><a href="../lib/input/core.dart#L348"><code>class KeyboardBinding</code></a><br><a href="../lib/input/core.dart#L360"><code>class KeyboardChord</code></a><br><a href="../lib/input/core.dart#L276"><code>class KeyboardInputEvent</code></a><br><a href="../lib/input/core.dart#L228"><code>class OffsetPkg</code></a><br><a href="../lib/input/core.dart#L439"><code>class PointerInputEvent</code></a><br><a href="../lib/input/core.dart#L242"><code>class ScalarPkg</code></a><br><a href="../lib/input/core.dart#L519"><code>class ScaleEndGestureInputEvent</code></a><br><a href="../lib/input/core.dart#L499"><code>class ScaleStartGestureInputEvent</code></a><br><a href="../lib/input/core.dart#L505"><code>class ScaleUpdateGestureInputEvent</code></a><br><a href="../lib/input/core.dart#L296"><code>class ShortcutRegistration</code></a><br><a href="../lib/input/core.dart#L303"><code>class ShortcutsRegistry</code></a><br><a href="../lib/input/core.dart#L489"><code>class TapCancelGestureInputEvent</code></a><br><a href="../lib/input/core.dart#L477"><code>class TapDownGestureInputEvent</code></a><br><a href="../lib/input/core.dart#L483"><code>class TapUpGestureInputEvent</code></a><br><a href="../lib/input/core.dart#L345"><code>typedef ActionId</code></a><br><a href="../lib/input/core.dart#L347"><code>typedef BindingHandler</code></a><br><a href="../lib/input/core.dart#L30"><code>typedef FocusRequest</code></a><br><a href="../lib/input/core.dart#L32"><code>typedef ShortcutInvoke</code></a></td>
          <td>—</td>
          <td><a href="../lib/input/core.dart#L401"><code>KeyboardChord.toString()</code></a><br><a href="../lib/input/core.dart#L318"><code>ShortcutsRegistry.clearScope()</code></a><br><a href="../lib/input/core.dart#L322"><code>ShortcutsRegistry.invoke()</code></a><br><a href="../lib/input/core.dart#L309"><code>ShortcutsRegistry.register()</code></a></td>
          <td>—</td>
          <td>—</td>
          <td><a href="../test/input/router_test.dart"><code>test/input/router_test.dart</code></a></td>
        </tr>
        <tr>
          <td>🧪</td>
          <td><a href="../lib/input/manager.dart"><code>lib/input/manager.dart</code></a></td>
          <td><a href="../lib/input/manager.dart#L6"><code>class InputFocusManager</code></a></td>
          <td>—</td>
          <td><a href="../lib/input/manager.dart#L57"><code>InputFocusManager.clearFocus()</code></a></td>
          <td><a href="../lib/input/manager.dart#L76"><code>InputFocusManager._refreshKeyboardShortcuts()</code></a></td>
          <td>—</td>
          <td><a href="../test/input/router_test.dart"><code>test/input/router_test.dart</code></a></td>
        </tr>
        <tr>
          <td>—</td>
          <td><a href="../lib/input/router.dart"><code>lib/input/router.dart</code></a></td>
          <td><a href="../lib/input/router.dart#L6"><code>class StandardInputRouter</code></a></td>
          <td>—</td>
          <td><a href="../lib/input/router.dart#L32"><code>StandardInputRouter.routeTapCancel()</code></a></td>
          <td>—</td>
          <td><a href="../test/input/router_test.dart"><code>test/input/router_test.dart</code></a></td>
          <td>—</td>
        </tr>
        </tbody>
      </table>
    </td>
  </tr>
  <tr>
    <td>
      <table class="catalog-quality" style="width:100%">
        <colgroup>
          <col class="col-quality-intent" style="width: 22.76%">
          <col class="col-quality-stray" style="width: 28.73%">
          <col class="col-quality-todo" style="width: 26.21%">
          <col class="col-quality-duplicate" style="width: 22.30%">
        </colgroup>
        <thead>
          <tr>
            <th scope="col">Intent</th>
            <th scope="col">Stray</th>
            <th scope="col">TODO</th>
            <th scope="col">Duplicate</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><em>Add a brief intent comment to each <code>test</code> or <code>testWidgets</code> block so future readers know what it covers.</em></td>
            <td><em>Mirror the <code>lib/</code> path (e.g., <code>lib/foo/bar.dart</code> → <code>test/foo/bar_test.dart</code>) and import the target file to keep tests discoverable.</em></td>
            <td><em>Only uppercase 'TODO' in block comments or leading '//' comment lines are recognized; inline comments are ignored.</em></td>
            <td><em>Consider consolidating helpers that share a signature or renaming them to highlight their intent.</em></td>
          </tr>
          <tr>
            <td><span aria-hidden="true">&nbsp;</span></td>
            <td><span aria-hidden="true">&nbsp;</span></td>
            <td><span aria-hidden="true">&nbsp;</span></td>
            <td><code>BufferSample materializeAt(int index)</code><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L140"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L226"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/sample_store.dart#L413"><code>lib/buffer/sample_store.dart</code></a><br><code>Path pathForTransform(ChartTransform transform)</code><br>&nbsp;&nbsp;<a href="../lib/chart/node.dart#L208"><code>lib/chart/node.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/chart/node.dart#L44"><code>lib/chart/node.dart</code></a><br><code>Widget build(BuildContext context)</code><br>&nbsp;&nbsp;<a href="../lib/chart/painter.dart#L63"><code>lib/chart/painter.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/development/main.dart#L128"><code>lib/development/main.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/development/main.dart#L164"><code>lib/development/main.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/development/main.dart#L205"><code>lib/development/main.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/development/main.dart#L27"><code>lib/development/main.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/development/main.dart#L51"><code>lib/development/main.dart</code></a><br><code>double closeAt(int index)</code><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L187"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L220"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L270"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/sample_store.dart#L407"><code>lib/buffer/sample_store.dart</code></a><br><code>double highAt(int index)</code><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L179"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L214"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L258"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/sample_store.dart#L401"><code>lib/buffer/sample_store.dart</code></a><br><code>double lowAt(int index)</code><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L183"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L217"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L264"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/sample_store.dart#L404"><code>lib/buffer/sample_store.dart</code></a><br><code>double openAt(int index)</code><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L175"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L211"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L252"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/sample_store.dart#L398"><code>lib/buffer/sample_store.dart</code></a><br><code>double volumeAt(int index)</code><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L191"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L223"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L276"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/sample_store.dart#L410"><code>lib/buffer/sample_store.dart</code></a><br><code>int epochMicrosAt(int index)</code><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L171"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L208"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/channel.dart#L246"><code>lib/buffer/channel.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/sample_store.dart#L395"><code>lib/buffer/sample_store.dart</code></a><br><code>void clear()</code><br>&nbsp;&nbsp;<a href="../lib/buffer/sample_store.dart#L37"><code>lib/buffer/sample_store.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/buffer/worker.dart#L248"><code>lib/buffer/worker.dart</code></a><br><code>void dispose()</code><br>&nbsp;&nbsp;<a href="../lib/buffer/client.dart#L174"><code>lib/buffer/client.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/development/environment.dart#L113"><code>lib/development/environment.dart</code></a><br><code>void main()</code><br>&nbsp;&nbsp;<a href="../test/buffer/channel_test.dart#L4"><code>test/buffer/channel_test.dart</code></a><br>&nbsp;&nbsp;<a href="../test/buffer/client_test.dart#L5"><code>test/buffer/client_test.dart</code></a><br>&nbsp;&nbsp;<a href="../test/chart/controller_test.dart#L12"><code>test/chart/controller_test.dart</code></a><br>&nbsp;&nbsp;<a href="../test/chart/foundation_test.dart#L8"><code>test/chart/foundation_test.dart</code></a><br>&nbsp;&nbsp;<a href="../test/chart/node_test.dart#L9"><code>test/chart/node_test.dart</code></a><br>&nbsp;&nbsp;<a href="../test/chart/painter_test.dart#L13"><code>test/chart/painter_test.dart</code></a><br>&nbsp;&nbsp;<a href="../test/input/router_test.dart#L71"><code>test/input/router_test.dart</code></a><br><code>void paint(ChartRenderContext context)</code><br>&nbsp;&nbsp;<a href="../lib/chart/area.dart#L13"><code>lib/chart/area.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/chart/bar.dart#L18"><code>lib/chart/bar.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/chart/candle.dart#L13"><code>lib/chart/candle.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/chart/grid.dart#L30"><code>lib/chart/grid.dart</code></a><br>&nbsp;&nbsp;<a href="../lib/chart/line.dart#L13"><code>lib/chart/line.dart</code></a></td>
          </tr>
        </tbody>
      </table>
    </td>
  </tr>
</table>
