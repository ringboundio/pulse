import 'dart:math';

import 'package:flutter/foundation.dart';

class DevelopmentViewport extends ChangeNotifier {
  DevelopmentViewport({
    required this.intervalMicros,
    required this.minWindowMicros,
    required this.maxWindowMicros,
    required int initialStartMicros,
    required int initialWindowMicros,
  }) : _startMicros = initialStartMicros,
       _windowMicros = _clampWindow(
         window: initialWindowMicros,
         minWindow: minWindowMicros,
         maxWindow: maxWindowMicros,
         interval: intervalMicros,
       );

  final int intervalMicros;
  final int minWindowMicros;
  final int maxWindowMicros;
  int _startMicros;
  int _windowMicros;

  int get startMicros => _startMicros;

  int get endMicros => _startMicros + _windowMicros;

  int get windowMicros => _windowMicros;

  double get centerMicros => _startMicros + _windowMicros / 2.0;

  void reset({required int startMicros, required int windowMicros}) {
    final int clampedWindow = _clampWindow(
      window: windowMicros,
      minWindow: minWindowMicros,
      maxWindow: maxWindowMicros,
      interval: intervalMicros,
    );
    final int clampedStart = startMicros >= 0 ? startMicros : 0;
    if (clampedStart == _startMicros && clampedWindow == _windowMicros) {
      return;
    }
    _startMicros = clampedStart;
    _windowMicros = clampedWindow;
    notifyListeners();
  }

  void shiftMicros(int delta) {
    if (delta == 0) {
      return;
    }
    final int proposed = _startMicros + delta;
    final int clamped = proposed >= 0 ? proposed : 0;
    if (clamped == _startMicros) {
      return;
    }
    _startMicros = clamped;
    notifyListeners();
  }

  void shiftByFraction(double fraction) {
    if (fraction == 0.0) {
      return;
    }
    final double delta = _windowMicros * fraction;
    shiftMicros(delta.round());
  }

  void zoomByFactor(double factor) {
    if (factor <= 0.0 || factor == 1.0) {
      return;
    }
    final double scaledWindow = _windowMicros * factor;
    final int candidate = scaledWindow.round();
    _applyWindow(candidate, anchorMicros: centerMicros);
  }

  void scaleAround(double anchorMicros, double factor) {
    if (factor <= 0.0) {
      return;
    }
    final double scaledWindow = _windowMicros * factor;
    final int candidate = scaledWindow.round();
    _applyWindow(candidate, anchorMicros: anchorMicros);
  }

  void jumpToEnd(int endMicros) {
    final int targetEnd = endMicros >= 0 ? endMicros : 0;
    final int proposedStart = targetEnd - _windowMicros;
    final int start = proposedStart >= 0 ? proposedStart : 0;
    if (start == _startMicros) {
      return;
    }
    _startMicros = start;
    notifyListeners();
  }

  static int _clampWindow({
    required int window,
    required int minWindow,
    required int maxWindow,
    required int interval,
  }) {
    final int minimumBase = max(interval, minWindow);
    final int maximumBase = max(minimumBase, maxWindow);
    int clamped = window;
    if (clamped < minimumBase) {
      clamped = minimumBase;
    }
    if (clamped > maximumBase) {
      clamped = maximumBase;
    }
    return clamped;
  }

  void _applyWindow(int candidate, {required double anchorMicros}) {
    final int clampedWindow = _clampWindow(
      window: candidate,
      minWindow: minWindowMicros,
      maxWindow: maxWindowMicros,
      interval: intervalMicros,
    );
    final double anchorRatio = _windowMicros > 0
        ? (anchorMicros - _startMicros) / _windowMicros
        : 0.5;
    final double nextStart = anchorMicros - clampedWindow * anchorRatio;
    final int startCandidate = nextStart.round();
    final int clampedStart = startCandidate >= 0 ? startCandidate : 0;
    if (clampedStart == _startMicros && clampedWindow == _windowMicros) {
      return;
    }
    _startMicros = clampedStart;
    _windowMicros = clampedWindow;
    notifyListeners();
  }
}
