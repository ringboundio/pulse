import 'package:flutter/foundation.dart';

import 'package:pulse/input/input.dart';
import 'package:pulse/input/keyboard.dart';

// Shortcuts registry root scope must match root node id.
class InputFocusManager extends ChangeNotifier {
  InputFocusManager({
    required InputFocusNode rootNode,
    required ShortcutsRegistry shortcuts,
  }) : _rootNode = rootNode,
       _shortcuts = shortcuts {
    _focusStack.add(_rootNode);
    _refreshKeyboardShortcuts(_rootNode);
  }

  final InputFocusNode _rootNode;
  final List<InputFocusNode> _focusStack = <InputFocusNode>[];
  final ShortcutsRegistry _shortcuts;

  ShortcutsRegistry get shortcuts => _shortcuts;

  InputFocusNode get activeNode => _focusStack.last;

  void requestFocus({required InputFocusNode node}) {
    final InputFocusNode previous = activeNode;
    if (previous == node) {
      return;
    }

    if (node == _rootNode) {
      _focusStack
        ..clear()
        ..add(_rootNode);
    } else {
      _focusStack.remove(node);
      _focusStack.add(node);
    }
    _refreshKeyboardShortcuts(activeNode);

    previous.onFocusLost(InputFocusChange(previous));
    activeNode.onFocusGained(InputFocusChange(activeNode));
    notifyListeners();
  }

  void releaseFocus({required InputFocusNode node}) {
    if (node == _rootNode || !_focusStack.contains(node)) {
      return;
    }

    if (_focusStack.remove(node)) {
      _shortcuts.clearScope(node.id);
      node.onFocusLost(InputFocusChange(node));
      activeNode.onFocusGained(InputFocusChange(activeNode));
      notifyListeners();
    }
  }

  void clearFocus() {
    requestFocus(node: _rootNode);
  }

  InputDispatchContext createDispatchContext({
    required InputRouterHandle router,
    required InputFocusNode node,
  }) {
    return InputDispatchContext(
      focusNode: node,
      requestFocusCallback: requestFocus,
      releaseFocusCallback: releaseFocus,
      shortcutCallback: ({required String actionId, required String scopeId}) {
        return _shortcuts.invoke(actionId, scopeId);
      },
      router: router,
    );
  }

  void _refreshKeyboardShortcuts(InputFocusNode node) {
    _shortcuts.clearScope(node.id);
    for (final KeyboardBinding binding in node.profile.keyboard.bindings) {
      _shortcuts.register(
        ShortcutRegistration(binding: binding, scope: node.id),
      );
    }
  }
}
