import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'package:pulse/development/bench/benchmark.dart';
import 'package:pulse/input/core.dart';
import 'package:pulse/input/manager.dart';
import 'package:pulse/input/router.dart';

List<BenchmarkDefinition> buildInputBenchmarks() {
  final InputSettings settings = InputSettings(
    invertScroll: false,
    panIntensity: 0.85,
    zoomIntensity: 1.2,
    scrubIntensity: 0.6,
  );
  final DeviceCalibration calibration = const DeviceCalibration(
    panUnit: 1 / 480.0,
    zoomUnit: 1 / 120.0,
    scrubUnit: 1 / 360.0,
  );

  final KeyboardProfile keyboardProfile = _CountingKeyboardProfile();
  final PointerProfile pointerProfile = const _RecordingPointerProfile();
  final GestureProfile gestureProfile = const _RecordingGestureProfile();

  final InputProfile inputProfile = InputProfile(
    keyboard: keyboardProfile,
    pointer: pointerProfile,
    gesture: gestureProfile,
    settings: settings,
    deviceCalibration: calibration,
  );

  const String rootScope = 'root';

  final InputFocusNode rootNode = InputFocusNode(
    id: rootScope,
    profile: inputProfile,
    onFocusGained: (change) => blackHole(change.node.id),
    onFocusLost: (change) => blackHole(change.node.id),
  );
  final InputFocusNode chartNode = InputFocusNode(
    id: 'chart',
    profile: inputProfile,
    onFocusGained: (change) => blackHole(change.node.id),
    onFocusLost: (change) => blackHole(change.node.id),
  );
  final InputFocusNode tableNode = InputFocusNode(
    id: 'table',
    profile: inputProfile,
    onFocusGained: (change) => blackHole(change.node.id),
    onFocusLost: (change) => blackHole(change.node.id),
  );

  final ShortcutsRegistry shortcuts = ShortcutsRegistry(rootScope: rootScope);
  final InputFocusManager focusManager = InputFocusManager(
    rootNode: rootNode,
    shortcuts: shortcuts,
  );

  final StandardInputRouter router = StandardInputRouter(
    focusManager: focusManager,
  );

  final List<ShortcutRegistration> registrations = _buildShortcutRegistrations(
    scope: rootScope,
  );
  for (final ShortcutRegistration registration in registrations) {
    shortcuts.register(registration);
  }

  final PointerScrollEvent pointerScrollEvent = PointerScrollEvent(
    position: Offset.zero,
    scrollDelta: const Offset(12.0, -24.0),
  );
  final ScaleUpdateDetails scaleDetails = ScaleUpdateDetails(
    focalPoint: const Offset(320.0, 200.0),
    focalPointDelta: const Offset(4.5, -3.0),
    scale: 1.08,
    horizontalScale: 1.02,
    verticalScale: 0.97,
    rotation: 0.12,
  );

  final int keyCount = registrations.length;
  final KeyDownEvent keyEvent = KeyDownEvent(
    logicalKey: LogicalKeyboardKey.keyA,
    physicalKey: PhysicalKeyboardKey.keyA,
    timeStamp: const Duration(milliseconds: 12),
    character: 'a',
  );

  int focusIndex = 0;
  final List<InputFocusNode> focusCycle = <InputFocusNode>[
    chartNode,
    tableNode,
  ];
  int shortcutIndex = 0;

  return <BenchmarkDefinition>[
    // Packages raw pointer deltas into our pan payload to benchmark calibration
    // math in isolation.
    BenchmarkDefinition(
      name: 'input/settings_package_pan',
      body: (_) {
        final OffsetPkg pkg = settings.packagePan(
          delta: const Offset(10.0, -22.0),
          deviceUnit: calibration.panUnit,
          intensity: settings.panIntensity,
        );
        blackHole(pkg.expected.dx);
      },
    ),
    // Builds a pointer input event from a scroll gesture so we can watch the
    // normalization pipeline.
    BenchmarkDefinition(
      name: 'input/profile_build_pointer_event',
      body: (_) {
        final PointerInputEvent pointerEvent = inputProfile.buildPointerEvent(
          event: pointerScrollEvent,
        );
        blackHole(pointerEvent.pan.expected.dy);
      },
    ),
    // Converts a scale update gesture into profile outputs to track zoom path
    // cost.
    BenchmarkDefinition(
      name: 'input/profile_build_scale_event',
      body: (_) {
        final ScaleUpdateGestureInputEvent event = inputProfile
            .buildScaleUpdateEvent(details: scaleDetails);
        blackHole(event.zoom.expected);
      },
    ),
    // Routes a pointer event through the standard router to measure dispatch
    // with focus targeting.
    BenchmarkDefinition(
      name: 'input/router_route_pointer',
      body: (_) {
        focusManager.requestFocus(node: chartNode);
        final bool handled = router.routePointerEvent(
          pointerEvent: pointerScrollEvent,
        );
        blackHole(handled);
      },
    ),
    // Routes scale updates through the router so we capture gesture dispatch
    // overhead.
    BenchmarkDefinition(
      name: 'input/router_route_scale_update',
      body: (_) {
        focusManager.requestFocus(node: chartNode);
        final bool handled = router.routeScaleUpdate(details: scaleDetails);
        blackHole(handled);
      },
    ),
    // Sends keyboard events into the router to monitor shortcut path latency.
    BenchmarkDefinition(
      name: 'input/router_route_key',
      body: (_) {
        final bool handled = router.routeKeyEvent(keyEvent: keyEvent);
        blackHole(handled);
      },
    ),
    // Walks the focus manager through focus/clear cycles to ensure transitions
    // stay fast.
    BenchmarkDefinition(
      name: 'input/focus_manager_request',
      body: (_) {
        focusIndex = (focusIndex + 1) % focusCycle.length;
        focusManager.requestFocus(node: focusCycle[focusIndex]);
        focusManager.clearFocus();
        blackHole(focusManager.activeNode.id);
      },
    ),
    // Invokes registered shortcuts sequentially so we can detect regressions in
    // lookup and handler execution.
    BenchmarkDefinition(
      name: 'input/shortcuts_invoke',
      body: (_) {
        final ShortcutRegistration registration = registrations[shortcutIndex];
        shortcutIndex = (shortcutIndex + 1) % keyCount;
        final bool invoked = shortcuts.invoke(
          registration.binding.actionId,
          registration.scope,
        );
        blackHole(invoked);
      },
    ),
  ];
}

List<ShortcutRegistration> _buildShortcutRegistrations({
  required String scope,
}) {
  final List<ShortcutRegistration> registrations = <ShortcutRegistration>[];
  final List<LogicalKeyboardKey> keys = <LogicalKeyboardKey>[
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyB,
    LogicalKeyboardKey.keyC,
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.keyE,
    LogicalKeyboardKey.keyF,
    LogicalKeyboardKey.keyG,
    LogicalKeyboardKey.keyH,
  ];
  for (int index = 0; index < keys.length; index += 1) {
    final LogicalKeyboardKey key = keys[index];
    final KeyboardBinding binding = KeyboardBinding(
      chord: KeyboardChord(
        key: key,
        control: index.isEven,
        alt: false,
        shift: index.isOdd,
        meta: false,
      ),
      actionId: 'action.$index',
      handler: () {
        // Keep the handler pure to avoid skewing measurements.
        blackHole(key.keyId);
      },
    );
    registrations.add(ShortcutRegistration(binding: binding, scope: scope));
  }
  return registrations;
}

class _CountingKeyboardProfile extends KeyboardProfile {
  _CountingKeyboardProfile();

  @override
  Iterable<KeyboardBinding> get bindings => const <KeyboardBinding>[];

  @override
  bool handleEvent({
    required KeyboardInputEvent event,
    required InputDispatchContext context,
  }) {
    blackHole(event.chord.hashCode);
    return true;
  }
}

class _RecordingPointerProfile extends PointerProfile {
  const _RecordingPointerProfile();

  @override
  bool handleEvent({
    required PointerInputEvent event,
    required InputDispatchContext context,
  }) {
    blackHole(event.pan.normalized.dx);
    return true;
  }
}

class _RecordingGestureProfile extends GestureProfile {
  const _RecordingGestureProfile();

  @override
  bool handleEvent({
    required GestureInputEvent event,
    required InputDispatchContext context,
  }) {
    blackHole(event);
    return true;
  }
}
