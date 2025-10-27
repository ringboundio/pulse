import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'package:pulse/development/viewport.dart';
import 'package:pulse/input/core.dart';

class DevelopmentKeyboardProfile extends KeyboardProfile {
  DevelopmentKeyboardProfile({required DevelopmentViewport viewport})
    : _bindings = _createBindings(viewport);

  final List<KeyboardBinding> _bindings;

  static List<KeyboardBinding> _createBindings(DevelopmentViewport viewport) {
    return <KeyboardBinding>[
      KeyboardBinding(
        chord: const KeyboardChord(
          key: LogicalKeyboardKey.arrowLeft,
          control: false,
          alt: false,
          shift: false,
          meta: false,
        ),
        actionId: 'view.shift.left',
        handler: () {
          viewport.shiftByFraction(-0.12);
        },
      ),
      KeyboardBinding(
        chord: const KeyboardChord(
          key: LogicalKeyboardKey.arrowRight,
          control: false,
          alt: false,
          shift: false,
          meta: false,
        ),
        actionId: 'view.shift.right',
        handler: () {
          viewport.shiftByFraction(0.12);
        },
      ),
      KeyboardBinding(
        chord: const KeyboardChord(
          key: LogicalKeyboardKey.equal,
          control: false,
          alt: false,
          shift: false,
          meta: false,
        ),
        actionId: 'view.zoom.in',
        handler: () {
          viewport.zoomByFactor(0.8);
        },
      ),
      KeyboardBinding(
        chord: const KeyboardChord(
          key: LogicalKeyboardKey.minus,
          control: false,
          alt: false,
          shift: false,
          meta: false,
        ),
        actionId: 'view.zoom.out',
        handler: () {
          viewport.zoomByFactor(1.25);
        },
      ),
      KeyboardBinding(
        chord: const KeyboardChord(
          key: LogicalKeyboardKey.keyR,
          control: false,
          alt: false,
          shift: false,
          meta: false,
        ),
        actionId: 'view.reset',
        handler: () {
          viewport.reset(startMicros: 0, windowMicros: viewport.windowMicros);
        },
      ),
    ];
  }

  @override
  Iterable<KeyboardBinding> get bindings => _bindings;

  @override
  bool handleEvent({
    required KeyboardInputEvent event,
    required InputDispatchContext context,
  }) {
    if (!event.isKeyDown) {
      return false;
    }
    for (int index = 0; index < _bindings.length; index += 1) {
      final KeyboardBinding binding = _bindings[index];
      if (binding.chord == event.chord) {
        binding.handler();
        return true;
      }
    }
    return false;
  }
}

class DevelopmentPointerProfile extends PointerProfile {
  DevelopmentPointerProfile({required DevelopmentViewport viewport})
    : _viewport = viewport;

  final DevelopmentViewport _viewport;

  @override
  bool handleEvent({
    required PointerInputEvent event,
    required InputDispatchContext context,
  }) {
    context.requestFocus(node: context.focusNode);
    final PointerEvent rawEvent = event.event;
    if (rawEvent is PointerScrollEvent) {
      final double horizontal = rawEvent.scrollDelta.dx;
      final double vertical = rawEvent.scrollDelta.dy;
      bool handled = false;
      if (horizontal != 0.0) {
        _viewport.shiftByFraction(-horizontal.sign * 0.08);
        handled = true;
      }
      if (vertical != 0.0) {
        final double magnitude = vertical.abs();
        final double normalized = 1.0 + (magnitude / 480.0);
        final double factor = vertical > 0.0 ? normalized : 1.0 / normalized;
        _viewport.zoomByFactor(factor);
        handled = true;
      }
      return handled;
    }

    if (rawEvent is PointerPanZoomUpdateEvent) {
      final double panDelta = rawEvent.panDelta.dx;
      final double zoomDelta = rawEvent.scale - 1.0;
      if (panDelta != 0.0) {
        _viewport.shiftByFraction(-panDelta.sign * 0.06);
      }
      if (zoomDelta != 0.0) {
        final double factor = zoomDelta > 0.0
            ? 1.0 / (1.0 + zoomDelta.abs())
            : 1.0 + zoomDelta.abs();
        _viewport.zoomByFactor(factor);
      }
      return true;
    }

    if (rawEvent is PointerMoveEvent && rawEvent.down) {
      final double deltaX = rawEvent.delta.dx;
      if (deltaX != 0.0) {
        _viewport.shiftByFraction(-deltaX.sign * 0.04);
        return true;
      }
    }

    return false;
  }
}

class DevelopmentGestureProfile extends GestureProfile {
  DevelopmentGestureProfile({required DevelopmentViewport viewport})
    : _viewport = viewport;

  final DevelopmentViewport _viewport;

  @override
  bool handleEvent({
    required GestureInputEvent event,
    required InputDispatchContext context,
  }) {
    if (event is ScaleUpdateGestureInputEvent) {
      final Offset pan = event.pan.expected;
      final double scrub = event.scrub.expected;
      final double zoom = event.zoom.expected;
      bool handled = false;
      if (pan.dx != 0.0) {
        _viewport.shiftByFraction(-pan.dx / 320.0);
        handled = true;
      }
      if (scrub != 0.0) {
        _viewport.shiftByFraction(-scrub / 360.0);
        handled = true;
      }
      if (zoom != 0.0) {
        final double factor = exp(-zoom);
        _viewport.zoomByFactor(factor);
        handled = true;
      }
      return handled;
    }
    if (event is TapDownGestureInputEvent) {
      context.requestFocus(node: context.focusNode);
      return true;
    }
    return false;
  }
}
