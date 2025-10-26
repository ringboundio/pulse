import 'package:flutter/services.dart';

import 'package:pulse/input/input.dart';
import 'package:pulse/input/profile.dart';

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
