// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class MemoryPressureObserver with WidgetsBindingObserver {
  bool sawMemoryPressure = false;

  @override
  void didHaveMemoryPressure() {
    sawMemoryPressure = true;
  }
}

class AppLifecycleStateObserver with WidgetsBindingObserver {
  AppLifecycleState lifecycleState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    lifecycleState = state;
  }
}

class PushRouteObserver with WidgetsBindingObserver {
  String pushedRoute;

  @override
  Future<bool> didPushRoute(String route) async {
    pushedRoute = route;
    return true;
  }
}

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('didHaveMemoryPressure callback', (WidgetTester tester) async {
    final MemoryPressureObserver observer = MemoryPressureObserver();
    WidgetsBinding.instance.addObserver(observer);
    final ByteData message = const JSONMessageCodec().encodeMessage(
      <String, dynamic>{'type': 'memoryPressure'});
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/system', message, (_) { });
    expect(observer.sawMemoryPressure, true);
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgets('handleLifecycleStateChanged callback', (WidgetTester tester) async {
    final BinaryMessenger defaultBinaryMessenger = ServicesBinding.instance.defaultBinaryMessenger;
    final AppLifecycleStateObserver observer = AppLifecycleStateObserver();
    WidgetsBinding.instance.addObserver(observer);

    ByteData message = const StringCodec().encodeMessage('AppLifecycleState.paused');
    await defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
    expect(observer.lifecycleState, AppLifecycleState.paused);

    message = const StringCodec().encodeMessage('AppLifecycleState.resumed');
    await defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
    expect(observer.lifecycleState, AppLifecycleState.resumed);

    message = const StringCodec().encodeMessage('AppLifecycleState.inactive');
    await defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
    expect(observer.lifecycleState, AppLifecycleState.inactive);


    message = const StringCodec().encodeMessage('AppLifecycleState.detached');
    await defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
    // TODO(chunhtai): this should be detached once the issue is fixed
    // https://github.com/flutter/flutter/issues/39832
    // The binding drops detached message for now.
    expect(observer.lifecycleState, AppLifecycleState.inactive);
  });

  testWidgets('didPushRoute callback', (WidgetTester tester) async {
    final PushRouteObserver observer = PushRouteObserver();
    WidgetsBinding.instance.addObserver(observer);

    const String testRouteName = 'testRouteName';
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRoute', testRouteName));
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    expect(observer.pushedRoute, testRouteName);

    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgets('Application lifecycle affects frame scheduling', (WidgetTester tester) async {
    final BinaryMessenger defaultBinaryMessenger = ServicesBinding.instance.defaultBinaryMessenger;
    ByteData message;
    expect(tester.binding.hasScheduledFrame, isFalse);

    message = const StringCodec().encodeMessage('AppLifecycleState.paused');
    await defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
    expect(tester.binding.hasScheduledFrame, isFalse);

    message = const StringCodec().encodeMessage('AppLifecycleState.resumed');
    await defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    message = const StringCodec().encodeMessage('AppLifecycleState.inactive');
    await defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
    expect(tester.binding.hasScheduledFrame, isFalse);

    message = const StringCodec().encodeMessage('AppLifecycleState.paused');
    await defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
    expect(tester.binding.hasScheduledFrame, isFalse);

    tester.binding.scheduleFrame();
    expect(tester.binding.hasScheduledFrame, isFalse);

    tester.binding.scheduleForcedFrame();
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    int frameCount = 0;
    tester.binding.addPostFrameCallback((Duration duration) { frameCount += 1; });
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(frameCount, 0);

    tester.binding.scheduleWarmUpFrame(); // this actually tests flutter_test's implementation
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(frameCount, 1);
  });

  testWidgets('scheduleFrameCallback error control test', (WidgetTester tester) async {
    FlutterError error;
    try {
      tester.binding.scheduleFrameCallback(null, rescheduling: true);
    } on FlutterError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error.diagnostics.length, 3);
    expect(error.diagnostics.last.level, DiagnosticLevel.hint);
    expect(
      error.diagnostics.last.toStringDeep(),
      equalsIgnoringHashCodes(
        'If this is the initial registration of the callback, or if the\n'
        'callback is asynchronous, then do not use the "rescheduling"\n'
        'argument.\n'
      ),
    );
    expect(
      error.toStringDeep(),
      'FlutterError\n'
      '   scheduleFrameCallback called with rescheduling true, but no\n'
      '   callback is in scope.\n'
      '   The "rescheduling" argument should only be set to true if the\n'
      '   callback is being reregistered from within the callback itself,\n'
      '   and only then if the callback itself is entirely synchronous.\n'
      '   If this is the initial registration of the callback, or if the\n'
      '   callback is asynchronous, then do not use the "rescheduling"\n'
      '   argument.\n'
    );
  });
}
