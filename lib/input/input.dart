import 'package:flutter/foundation.dart';
import 'package:pulse/input/profile.dart';

abstract class InputEvent {
  const InputEvent();
}

abstract class InputRouterHandle {
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
  final InputRouterHandle router;

  void requestFocus({required InputFocusNode node}) =>
      requestFocusCallback(node: node);

  void releaseFocus({required InputFocusNode node}) =>
      releaseFocusCallback(node: node);

  bool triggerShortcut({required String id}) =>
      shortcutCallback(actionId: id, scopeId: focusNode.id);

  bool dispatch({required InputEvent event}) => router.dispatch(event: event);
}
