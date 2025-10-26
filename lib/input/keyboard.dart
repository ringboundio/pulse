import 'package:flutter/services.dart';

import 'package:pulse/input/input.dart';

abstract class KeyboardProfile {
  const KeyboardProfile();
  bool handleEvent({
    required KeyboardInputEvent event,
    required InputDispatchContext context,
  });

  Iterable<KeyboardBinding> get bindings => const [];
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
  final List<ShortcutRegistration> _registrations = [];

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
    // First, search for a match in the current scope.
    for (final registration in _registrations) {
      if (registration.binding.actionId == actionId &&
          registration.scope == scope) {
        registration.binding.handler();
        return true;
      }
    }

    // If no scoped match was found, and we are not already in the root scope,
    // search for a match in the root scope.
    if (scope != rootScope) {
      for (final registration in _registrations) {
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
    final hardware = HardwareKeyboard.instance;
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
      if (key.debugName is String) {
        keyName = key.debugName as String;
      } else {
        keyName = 'Key ${key.keyId}';
      }
    }

    final modifiers = <String>[];
    if (control) modifiers.add('Ctrl');
    if (alt) modifiers.add('Alt');
    if (shift) modifiers.add('Shift');
    if (meta) modifiers.add('Meta');
    modifiers.add(keyName);
    return modifiers.join('+');
  }
}
