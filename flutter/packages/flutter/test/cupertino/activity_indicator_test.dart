// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Activity indicator animate property works', (WidgetTester tester) async {

    await tester.pumpWidget(buildCupertinoActivityIndicator());
    expect(SchedulerBinding.instance.transientCallbackCount, equals(1));

    await tester.pumpWidget(buildCupertinoActivityIndicator(false));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));

    await tester.pumpWidget(Container());

    await tester.pumpWidget(buildCupertinoActivityIndicator(false));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));

    await tester.pumpWidget(buildCupertinoActivityIndicator());
    expect(SchedulerBinding.instance.transientCallbackCount, equals(1));
  });

  testWidgets('Activity indicator dark mode', (WidgetTester tester) async {
    final Key key = UniqueKey();
    await tester.pumpWidget(
      Center(
        child: MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light),
          child: RepaintBoundary(
            key: key,
            child: Container(
              color: CupertinoColors.white,
              child: const CupertinoActivityIndicator(animating: false, radius: 35),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('activityIndicator.paused.light.png'),
    );

    await tester.pumpWidget(
      Center(
        child: MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: RepaintBoundary(
            key: key,
            child: Container(
              color: CupertinoColors.black,
              child: const CupertinoActivityIndicator(animating: false, radius: 35),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('activityIndicator.paused.dark.png'),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/41345.
  testWidgets('has the correct corner radius', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoActivityIndicator(animating: false, radius: 100),
    );

    expect(
      find.byType(CupertinoActivityIndicator),
      paints..rrect(rrect: const RRect.fromLTRBXY(-100, 10, -50, -10, 10, 10)),
    );
  });
}

Widget buildCupertinoActivityIndicator([ bool animating ]) {
  return MediaQuery(
    data: const MediaQueryData(platformBrightness: Brightness.light),
    child: CupertinoActivityIndicator(
      animating: animating ?? true,
    ),
  );
}
