import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

abstract class InputEvent {
  const InputEvent();
}

abstract class InputRouter {
  bool dispatch({required InputEvent event});
}

class InputFocusChange {
  const InputFocusChange(this.node);
  final InputFocusNode node;
}

class InputFocusNode {
  const InputFocusNode({
    required this.id,
    required this.profile,
    required this.onFocusGained,
    required this.onFocusLost,
  });

  final String id;
  final InputProfile profile;
  final ValueChanged<InputFocusChange> onFocusGained;
  final ValueChanged<InputFocusChange> onFocusLost;
}

typedef FocusRequest = void Function({required InputFocusNode node});
typedef ShortcutInvoke =
    bool Function({required String actionId, required String scopeId});

class InputDispatchContext {
  const InputDispatchContext({
    required this.focusNode,
    required this.requestFocusCallback,
    required this.releaseFocusCallback,
    required this.shortcutCallback,
    required this.router,
  });

  final InputFocusNode focusNode;
  final FocusRequest requestFocusCallback;
  final FocusRequest releaseFocusCallback;
  final ShortcutInvoke shortcutCallback;
  final InputRouter router;

  void requestFocus({required InputFocusNode node}) =>
      requestFocusCallback(node: node);

  void releaseFocus({required InputFocusNode node}) =>
      releaseFocusCallback(node: node);

  bool triggerShortcut({required String id}) =>
      shortcutCallback(actionId: id, scopeId: focusNode.id);

  bool dispatch({required InputEvent event}) => router.dispatch(event: event);
}

class InputProfile {
  const InputProfile({
    required this.keyboard,
    required this.pointer,
    required this.gesture,
    required this.settings,
    required this.deviceCalibration,
  });

  final KeyboardProfile keyboard;
  final PointerProfile pointer;
  final GestureProfile gesture;
  final InputSettings settings;
  final DeviceCalibration deviceCalibration;

  PointerInputEvent buildPointerEvent({required PointerEvent event}) {
    final OffsetPkg pan = settings.packagePan(
      delta: _extractPointerPan(event: event),
      deviceUnit: deviceCalibration.panUnit,
      intensity: settings.panIntensity,
    );

    final ScalarPkg zoom = settings.packageZoom(
      value: _extractPointerZoom(event: event),
      deviceUnit: deviceCalibration.zoomUnit,
      intensity: settings.zoomIntensity,
    );

    final ScalarPkg scrub = settings.packageScalar(
      value: _extractPointerScrub(event: event),
      deviceUnit: deviceCalibration.scrubUnit,
      intensity: settings.scrubIntensity,
    );

    return PointerInputEvent(event: event, pan: pan, zoom: zoom, scrub: scrub);
  }

  Offset _extractPointerPan({required PointerEvent event}) {
    if (event is PointerScrollEvent) {
      return event.scrollDelta;
    }
    if (event is PointerMoveEvent) {
      return event.delta;
    }
    if (event is PointerPanZoomUpdateEvent) {
      return event.panDelta;
    }
    return Offset.zero;
  }

  double _extractPointerZoom({required PointerEvent event}) {
    if (event is PointerPanZoomUpdateEvent) {
      return event.scale - 1.0;
    }
    return 0.0;
  }

  double _extractPointerScrub({required PointerEvent event}) {
    final Offset pan = _extractPointerPan(event: event);
    return pan.dx;
  }

  ScaleUpdateGestureInputEvent buildScaleUpdateEvent({
    required ScaleUpdateDetails details,
  }) {
    final OffsetPkg pan = settings.packagePan(
      delta: details.focalPointDelta,
      deviceUnit: deviceCalibration.panUnit,
      intensity: settings.panIntensity,
    );

    final ScalarPkg zoom = settings.packageZoom(
      value: details.scale - 1.0,
      deviceUnit: deviceCalibration.zoomUnit,
      intensity: settings.zoomIntensity,
    );

    final ScalarPkg scrub = settings.packageScalar(
      value: details.horizontalScale - 1.0,
      deviceUnit: deviceCalibration.scrubUnit,
      intensity: settings.scrubIntensity,
    );

    return ScaleUpdateGestureInputEvent(
      details: details,
      pan: pan,
      zoom: zoom,
      scrub: scrub,
    );
  }
}

class DeviceCalibration {
  const DeviceCalibration({
    required this.panUnit,
    required this.zoomUnit,
    required this.scrubUnit,
  });

  final double panUnit;
  final double zoomUnit;
  final double scrubUnit;
}

class InputSettings {
  const InputSettings({
    required this.invertScroll,
    required this.panIntensity,
    required this.zoomIntensity,
    required this.scrubIntensity,
  });

  final bool invertScroll;
  final double panIntensity;
  final double zoomIntensity;
  final double scrubIntensity;

  OffsetPkg packagePan({
    required Offset delta,
    required double deviceUnit,
    required double intensity,
  }) {
    final Offset adjusted = invertScroll
        ? Offset(delta.dx, delta.dy * -1.0)
        : delta;

    final Offset normalized = adjusted * deviceUnit;
    return OffsetPkg(
      original: delta,
      normalized: normalized,
      expected: normalized * intensity,
      intensity: intensity,
    );
  }

  ScalarPkg packageZoom({
    required double value,
    required double deviceUnit,
    required double intensity,
  }) {
    final double normalized = value * deviceUnit;
    return ScalarPkg(
      original: value,
      normalized: normalized,
      expected: normalized * intensity,
      intensity: intensity,
    );
  }

  ScalarPkg packageScalar({
    required double value,
    required double deviceUnit,
    required double intensity,
  }) {
    final double normalized = value * deviceUnit;
    return ScalarPkg(
      original: value,
      normalized: normalized,
      expected: normalized * intensity,
      intensity: intensity,
    );
  }
}

class OffsetPkg {
  const OffsetPkg({
    required this.original,
    required this.normalized,
    required this.expected,
    required this.intensity,
  });

  final Offset original;
  final Offset normalized;
  final Offset expected;
  final double intensity;
}

class ScalarPkg {
  const ScalarPkg({
    required this.original,
    required this.normalized,
    required this.expected,
    required this.intensity,
  });

  final double original;
  final double normalized;
  final double expected;
  final double intensity;
}

abstract class KeyboardProfile {
  const KeyboardProfile();
  bool handleEvent({
    required KeyboardInputEvent event,
    required InputDispatchContext context,
  });

  Iterable<KeyboardBinding> get bindings => const <KeyboardBinding>[];
}

class EmptyKeyboardProfile extends KeyboardProfile {
  const EmptyKeyboardProfile();

  @override
  bool handleEvent({
    required KeyboardInputEvent event,
    required InputDispatchContext context,
  }) => false;
}

class KeyboardInputEvent extends InputEvent {
  KeyboardInputEvent({
    required this.chord,
    required this.isKeyDown,
    required this.event,
  }) : super();

  factory KeyboardInputEvent.fromKeyEvent(KeyEvent event) {
    return KeyboardInputEvent(
      chord: KeyboardChord.fromKeyEvent(event),
      isKeyDown: event is KeyDownEvent || event is KeyRepeatEvent,
      event: event,
    );
  }

  final KeyboardChord chord;
  final bool isKeyDown;
  final KeyEvent event;
}

class ShortcutRegistration {
  const ShortcutRegistration({required this.binding, required this.scope});

  final KeyboardBinding binding;
  final String scope;
}

class ShortcutsRegistry {
  ShortcutsRegistry({required this.rootScope});

  final String rootScope;
  final List<ShortcutRegistration> _registrations = <ShortcutRegistration>[];

  void register(ShortcutRegistration registration) {
    _registrations.removeWhere(
      (existing) =>
          existing.scope == registration.scope &&
          existing.binding.actionId == registration.binding.actionId,
    );
    _registrations.add(registration);
  }

  void clearScope(String scope) {
    _registrations.removeWhere((registration) => registration.scope == scope);
  }

  bool invoke(String actionId, String scope) {
    for (final ShortcutRegistration registration in _registrations) {
      if (registration.binding.actionId == actionId &&
          registration.scope == scope) {
        registration.binding.handler();
        return true;
      }
    }

    if (scope != rootScope) {
      for (final ShortcutRegistration registration in _registrations) {
        if (registration.binding.actionId == actionId &&
            registration.scope == rootScope) {
          registration.binding.handler();
          return true;
        }
      }
    }

    return false;
  }
}

typedef ActionId = String;
typedef BindingHandler = void Function();

class KeyboardBinding {
  const KeyboardBinding({
    required this.chord,
    required this.actionId,
    required this.handler,
  });

  final KeyboardChord chord;
  final ActionId actionId;
  final BindingHandler handler;
}

class KeyboardChord {
  const KeyboardChord({
    required this.key,
    required this.control,
    required this.alt,
    required this.shift,
    required this.meta,
  });

  factory KeyboardChord.fromKeyEvent(KeyEvent event) {
    final HardwareKeyboard hardware = HardwareKeyboard.instance;
    return KeyboardChord(
      key: event.logicalKey,
      control: hardware.isControlPressed,
      alt: hardware.isAltPressed,
      shift: hardware.isShiftPressed,
      meta: hardware.isMetaPressed,
    );
  }

  final LogicalKeyboardKey key;
  final bool control;
  final bool alt;
  final bool shift;
  final bool meta;

  @override
  int get hashCode => Object.hash(key, control, alt, shift, meta);

  @override
  bool operator ==(Object other) {
    return other is KeyboardChord &&
        other.key == key &&
        other.control == control &&
        other.alt == alt &&
        other.shift == shift &&
        other.meta == meta;
  }

  @override
  String toString() {
    var keyName = key.keyLabel;
    if (keyName.isEmpty) {
      final String? debugName = key.debugName;
      if (debugName != null) {
        keyName = debugName;
      } else {
        keyName = 'Key ${key.keyId}';
      }
    }

    final List<String> modifiers = <String>[];
    if (control) modifiers.add('Ctrl');
    if (alt) modifiers.add('Alt');
    if (shift) modifiers.add('Shift');
    if (meta) modifiers.add('Meta');
    modifiers.add(keyName);
    return modifiers.join('+');
  }
}

abstract class PointerProfile {
  const PointerProfile();
  bool handleEvent({
    required PointerInputEvent event,
    required InputDispatchContext context,
  });
}

class EmptyPointerProfile extends PointerProfile {
  const EmptyPointerProfile();

  @override
  bool handleEvent({
    required PointerInputEvent event,
    required InputDispatchContext context,
  }) => false;
}

class PointerInputEvent extends InputEvent {
  PointerInputEvent({
    required this.event,
    required this.pan,
    required this.zoom,
    required this.scrub,
  }) : super();

  final PointerEvent event;
  final OffsetPkg pan;
  final ScalarPkg zoom;
  final ScalarPkg scrub;

  Offset get position => event.position;
}

abstract class GestureProfile {
  const GestureProfile();
  bool handleEvent({
    required GestureInputEvent event,
    required InputDispatchContext context,
  });
}

class EmptyGestureProfile extends GestureProfile {
  const EmptyGestureProfile();

  @override
  bool handleEvent({
    required GestureInputEvent event,
    required InputDispatchContext context,
  }) => false;
}

abstract class GestureInputEvent extends InputEvent {
  const GestureInputEvent();
}

class TapDownGestureInputEvent extends GestureInputEvent {
  const TapDownGestureInputEvent(this.details);

  final TapDownDetails details;
}

class TapUpGestureInputEvent extends GestureInputEvent {
  const TapUpGestureInputEvent(this.details);

  final TapUpDetails details;
}

class TapCancelGestureInputEvent extends GestureInputEvent {
  const TapCancelGestureInputEvent();
}

class DoubleTapGestureInputEvent extends GestureInputEvent {
  const DoubleTapGestureInputEvent(this.details);

  final TapDownDetails details;
}

class ScaleStartGestureInputEvent extends GestureInputEvent {
  const ScaleStartGestureInputEvent(this.details);

  final ScaleStartDetails details;
}

class ScaleUpdateGestureInputEvent extends GestureInputEvent {
  ScaleUpdateGestureInputEvent({
    required this.details,
    required this.pan,
    required this.zoom,
    required this.scrub,
  });

  final ScaleUpdateDetails details;
  final OffsetPkg pan;
  final ScalarPkg zoom;
  final ScalarPkg scrub;
}

class ScaleEndGestureInputEvent extends GestureInputEvent {
  const ScaleEndGestureInputEvent(this.details);

  final ScaleEndDetails details;
}
