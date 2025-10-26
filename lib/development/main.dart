import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pulse/chart/painter.dart';
import 'package:pulse/development/environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final DevelopmentEnvironment environment =
      await buildDevelopmentEnvironment();
  runApp(
    DevelopmentApp(
      key: ValueKey<String>('pulse.development.app'),
      environment: environment,
    ),
  );
}

class DevelopmentApp extends StatelessWidget {
  const DevelopmentApp({required Key key, required this.environment})
    : super(key: key);

  final DevelopmentEnvironment environment;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pulse Development Suite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF11151C),
      ),
      home: DevelopmentShell(
        key: ValueKey<String>('pulse.development.shell'),
        environment: environment,
      ),
    );
  }
}

class DevelopmentShell extends StatelessWidget {
  const DevelopmentShell({required Key key, required this.environment})
    : super(key: key);

  final DevelopmentEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    environment.updateDevicePixelRatio(mediaQuery.devicePixelRatio);

    return Focus(
      focusNode: environment.widgetFocusNode,
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        final bool handled = environment.router.routeKeyEvent(keyEvent: event);
        return handled ? KeyEventResult.handled : KeyEventResult.ignored;
      },
      child: Listener(
        onPointerSignal: (PointerSignalEvent event) {
          environment.router.routePointerEvent(pointerEvent: event);
        },
        onPointerHover: (PointerHoverEvent event) {
          environment.router.routePointerEvent(pointerEvent: event);
        },
        onPointerDown: (PointerDownEvent event) {
          environment.router.routePointerEvent(pointerEvent: event);
        },
        onPointerMove: (PointerMoveEvent event) {
          environment.router.routePointerEvent(pointerEvent: event);
        },
        onPointerUp: (PointerUpEvent event) {
          environment.router.routePointerEvent(pointerEvent: event);
        },
        onPointerPanZoomStart: (PointerPanZoomStartEvent event) {
          environment.router.routePointerEvent(pointerEvent: event);
        },
        onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
          environment.router.routePointerEvent(pointerEvent: event);
        },
        onPointerPanZoomEnd: (PointerPanZoomEndEvent event) {
          environment.router.routePointerEvent(pointerEvent: event);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails details) {
            environment.router.routeTapDown(details: details);
          },
          onTapUp: (TapUpDetails details) {
            environment.router.routeTapUp(details: details);
          },
          onTapCancel: () {
            environment.router.routeTapCancel();
          },
          onDoubleTapDown: (TapDownDetails details) {
            environment.router.routeDoubleTap(details: details);
          },
          onScaleStart: (ScaleStartDetails details) {
            environment.router.routeScaleStart(details: details);
          },
          onScaleUpdate: (ScaleUpdateDetails details) {
            environment.router.routeScaleUpdate(details: details);
          },
          onScaleEnd: (ScaleEndDetails details) {
            environment.router.routeScaleEnd(details: details);
          },
          child: ColoredBox(
            color: const Color(0xFF0B1016),
            child: SafeArea(
              child: _DevelopmentContent(environment: environment),
            ),
          ),
        ),
      ),
    );
  }
}

class _DevelopmentContent extends StatelessWidget {
  const _DevelopmentContent({required this.environment});

  final DevelopmentEnvironment environment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _DevelopmentStatusBar(environment: environment),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF121A23), Color(0xFF151E28)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ChartSurface(
                  controller: environment.chartController,
                  renderer: environment.chartRenderer,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DevelopmentStatusBar extends StatelessWidget {
  const _DevelopmentStatusBar({required this.environment});

  final DevelopmentEnvironment environment;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: environment.viewport,
      builder: (BuildContext context, _) {
        final int start = environment.viewport.startMicros;
        final int end = environment.viewport.endMicros;
        final int window = environment.viewport.windowMicros;
        final int count = environment.sampleCount;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF1A212B), width: 1.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _DevelopmentMetric(
                label: 'Symbol',
                value: environment.symbol.value,
              ),
              _DevelopmentMetric(label: 'Window μs', value: window.toString()),
              _DevelopmentMetric(label: 'Start μs', value: start.toString()),
              _DevelopmentMetric(label: 'End μs', value: end.toString()),
              _DevelopmentMetric(label: 'Samples', value: count.toString()),
            ],
          ),
        );
      },
    );
  }
}

class _DevelopmentMetric extends StatelessWidget {
  const _DevelopmentMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7B8290),
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFE6EBF3),
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
