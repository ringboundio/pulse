import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/input/focus_manager.dart';
import 'package:pulse/input/gesture.dart';
import 'package:pulse/input/input.dart';
import 'package:pulse/input/keyboard.dart';
import 'package:pulse/input/pointer.dart';
import 'package:pulse/input/profile.dart';
import 'package:pulse/input/router.dart';

class _TrackingKeyboardProfile extends KeyboardProfile {
  const _TrackingKeyboardProfile(this.log);

  final _RouterLog log;

  @override
  bool handleEvent({
    required KeyboardInputEvent event,
    required InputDispatchContext context,
  }) {
    log.keyboardEvents += 1;
    log.lastKeyboardChord = event.chord;
    return log.keyboardShouldConsume;
  }

  @override
  Iterable<KeyboardBinding> get bindings => const <KeyboardBinding>[];
}

class _TrackingPointerProfile extends PointerProfile {
  const _TrackingPointerProfile(this.log);

  final _RouterLog log;

  @override
  bool handleEvent({
    required PointerInputEvent event,
    required InputDispatchContext context,
  }) {
    log.pointerEvents += 1;
    log.lastPointerPosition = event.position;
    return log.pointerShouldConsume;
  }
}

class _TrackingGestureProfile extends GestureProfile {
  const _TrackingGestureProfile(this.log);

  final _RouterLog log;

  @override
  bool handleEvent({
    required GestureInputEvent event,
    required InputDispatchContext context,
  }) {
    log.gestureEvents += 1;
    log.lastGestureType = event.runtimeType;
    return log.gestureShouldConsume;
  }
}

class _RouterLog {
  int keyboardEvents = 0;
  int pointerEvents = 0;
  int gestureEvents = 0;
  KeyboardChord? lastKeyboardChord;
  Offset? lastPointerPosition;
  Type? lastGestureType;
  bool keyboardShouldConsume = false;
  bool pointerShouldConsume = false;
  bool gestureShouldConsume = false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Validates router forwards pointer, gesture, and keyboard events to the active profile.
  test('InputRouter delegates event handling to active profile', () {
    final _RouterLog log = _RouterLog();
    final InputProfile profile = InputProfile(
      keyboard: _TrackingKeyboardProfile(log),
      pointer: _TrackingPointerProfile(log),
      gesture: _TrackingGestureProfile(log),
      settings: const InputSettings(
        invertScroll: false,
        panIntensity: 1.0,
        zoomIntensity: 1.0,
        scrubIntensity: 1.0,
      ),
      deviceCalibration: const DeviceCalibration(
        panUnit: 1.0,
        zoomUnit: 1.0,
        scrubUnit: 1.0,
      ),
    );

    final InputFocusNode root = InputFocusNode(
      id: 'root',
      profile: profile,
      onFocusGained: (_) {},
      onFocusLost: (_) {},
    );

    final ShortcutsRegistry shortcuts = ShortcutsRegistry(rootScope: 'root');
    final InputFocusManager focusManager = InputFocusManager(
      rootNode: root,
      shortcuts: shortcuts,
    );
    final InputRouter router = InputRouter(focusManager: focusManager);

    focusManager.requestFocus(node: root);

    final PointerInputEvent pointerEvent = profile.buildPointerEvent(
      event: const PointerMoveEvent(position: Offset(10, 20)),
    );

    expect(router.dispatch(event: pointerEvent), isFalse);
    expect(log.pointerEvents, 1);
    expect(log.lastPointerPosition, const Offset(10, 20));

    final GestureInputEvent gestureEvent = TapDownGestureInputEvent(
      TapDownDetails(globalPosition: const Offset(8, 4)),
    );
    expect(router.dispatch(event: gestureEvent), isFalse);
    expect(log.gestureEvents, 1);
    expect(log.lastGestureType, TapDownGestureInputEvent);

    final KeyboardInputEvent keyboardEvent = KeyboardInputEvent(
      chord: const KeyboardChord(
        key: LogicalKeyboardKey.keyA,
        control: false,
        alt: false,
        shift: false,
        meta: false,
      ),
      isKeyDown: true,
      event: KeyDownEvent(
        logicalKey: LogicalKeyboardKey.keyA,
        physicalKey: PhysicalKeyboardKey.keyA,
        timeStamp: Duration.zero,
      ),
    );
    expect(router.dispatch(event: keyboardEvent), isFalse);
    expect(log.keyboardEvents, 1);
    expect(log.lastKeyboardChord?.key, LogicalKeyboardKey.keyA);
  });

  // Ensures router returns true when profiles consume events and propagates focus callbacks.
  test('InputRouter respects profile consumption and focus change', () {
    final _RouterLog log = _RouterLog()
      ..pointerShouldConsume = true
      ..gestureShouldConsume = true
      ..keyboardShouldConsume = true;

    bool focusGained = false;
    bool focusLost = false;

    final InputProfile profile = InputProfile(
      keyboard: _TrackingKeyboardProfile(log),
      pointer: _TrackingPointerProfile(log),
      gesture: _TrackingGestureProfile(log),
      settings: const InputSettings(
        invertScroll: false,
        panIntensity: 1.0,
        zoomIntensity: 1.0,
        scrubIntensity: 1.0,
      ),
      deviceCalibration: const DeviceCalibration(
        panUnit: 1.0,
        zoomUnit: 1.0,
        scrubUnit: 1.0,
      ),
    );

    final InputFocusNode root = InputFocusNode(
      id: 'root',
      profile: profile,
      onFocusGained: (_) {
        focusGained = true;
      },
      onFocusLost: (_) {
        focusLost = true;
      },
    );

    final InputFocusNode secondary = InputFocusNode(
      id: 'secondary',
      profile: profile,
      onFocusGained: (_) {
        focusGained = true;
      },
      onFocusLost: (_) {
        focusLost = true;
      },
    );

    final ShortcutsRegistry shortcuts = ShortcutsRegistry(rootScope: 'root');
    final InputFocusManager focusManager = InputFocusManager(
      rootNode: root,
      shortcuts: shortcuts,
    );
    final InputRouter router = InputRouter(focusManager: focusManager);

    focusManager.requestFocus(node: root);
    focusManager.requestFocus(node: secondary);

    expect(focusGained, isTrue);
    expect(focusLost, isTrue);

    final PointerInputEvent pointerEvent = profile.buildPointerEvent(
      event: const PointerDownEvent(position: Offset(1, 2)),
    );
    expect(router.dispatch(event: pointerEvent), isTrue);

    final GestureInputEvent gestureEvent = ScaleStartGestureInputEvent(
      ScaleStartDetails(localFocalPoint: Offset.zero),
    );
    expect(router.dispatch(event: gestureEvent), isTrue);

    final KeyboardInputEvent keyboardEvent = KeyboardInputEvent(
      chord: const KeyboardChord(
        key: LogicalKeyboardKey.keyB,
        control: true,
        alt: false,
        shift: false,
        meta: false,
      ),
      isKeyDown: false,
      event: KeyUpEvent(
        logicalKey: LogicalKeyboardKey.keyB,
        physicalKey: PhysicalKeyboardKey.keyB,
        timeStamp: Duration.zero,
      ),
    );
    expect(router.dispatch(event: keyboardEvent), isTrue);

    expect(log.pointerEvents, 1);
    expect(log.gestureEvents, 1);
    expect(log.keyboardEvents, 1);
  });
}
