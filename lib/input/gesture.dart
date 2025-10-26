import 'package:flutter/gestures.dart';

import 'package:pulse/input/input.dart';
import 'package:pulse/input/profile.dart';

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

sealed class GestureInputEvent extends InputEvent {
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
