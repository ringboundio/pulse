import 'package:flutter/gestures.dart';

import 'package:pulse/input/gesture.dart';
import 'package:pulse/input/keyboard.dart';
import 'package:pulse/input/pointer.dart';

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
