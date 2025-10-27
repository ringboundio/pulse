import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'package:pulse/input/core.dart';
import 'package:pulse/input/manager.dart';

class StandardInputRouter implements InputRouter {
  StandardInputRouter({required this.focusManager});

  final InputFocusManager focusManager;

  bool routeKeyEvent({required KeyEvent keyEvent}) {
    final KeyboardInputEvent event = KeyboardInputEvent.fromKeyEvent(keyEvent);
    return dispatch(event: event);
  }

  bool routePointerEvent({required PointerEvent pointerEvent}) {
    final InputProfile profile = focusManager.activeNode.profile;
    final PointerInputEvent event = profile.buildPointerEvent(
      event: pointerEvent,
    );
    return dispatch(event: event);
  }

  bool routeTapDown({required TapDownDetails details}) {
    return dispatch(event: TapDownGestureInputEvent(details));
  }

  bool routeTapUp({required TapUpDetails details}) {
    return dispatch(event: TapUpGestureInputEvent(details));
  }

  bool routeTapCancel() {
    return dispatch(event: const TapCancelGestureInputEvent());
  }

  bool routeDoubleTap({required TapDownDetails details}) {
    return dispatch(event: DoubleTapGestureInputEvent(details));
  }

  bool routeScaleStart({required ScaleStartDetails details}) {
    return dispatch(event: ScaleStartGestureInputEvent(details));
  }

  bool routeScaleUpdate({required ScaleUpdateDetails details}) {
    final InputProfile profile = focusManager.activeNode.profile;
    final ScaleUpdateGestureInputEvent event = profile.buildScaleUpdateEvent(
      details: details,
    );
    return dispatch(event: event);
  }

  bool routeScaleEnd({required ScaleEndDetails details}) {
    return dispatch(event: ScaleEndGestureInputEvent(details));
  }

  @override
  bool dispatch({required InputEvent event}) {
    final InputProfile profile = focusManager.activeNode.profile;
    final InputDispatchContext context = focusManager.createDispatchContext(
      router: this,
      node: focusManager.activeNode,
    );
    if (event is PointerInputEvent) {
      return profile.pointer.handleEvent(event: event, context: context);
    }

    if (event is GestureInputEvent) {
      return profile.gesture.handleEvent(event: event, context: context);
    }

    if (event is KeyboardInputEvent) {
      return profile.keyboard.handleEvent(event: event, context: context);
    }

    return false;
  }
}
