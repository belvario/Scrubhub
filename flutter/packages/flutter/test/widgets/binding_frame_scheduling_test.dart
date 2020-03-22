// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' show window;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('Instantiating WidgetsFlutterBinding does neither schedule a frame nor register frame callbacks', () async {
    // Regression test for https://github.com/flutter/flutter/issues/39494.

    // Preconditions.
    expect(WidgetsBinding.instance, isNull);
    expect(window.onBeginFrame, isNull);
    expect(window.onDrawFrame, isNull);

    // Instantiation does nothing with regards to frame scheduling.
    final WidgetsFlutterBinding binding = WidgetsFlutterBinding.ensureInitialized();
    expect(binding.hasScheduledFrame, isFalse);
    expect(window.onBeginFrame, isNull);
    expect(window.onDrawFrame, isNull);

    // Framework starts with detached statue. Sends resumed signal to enable frame.
    final ByteData message = const StringCodec().encodeMessage('AppLifecycleState.resumed');
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });

    // Frame callbacks are registered lazily when a frame is scheduled.
    binding.scheduleFrame();
    expect(window.onBeginFrame, isNotNull);
    expect(window.onDrawFrame, isNotNull);
  });
}
