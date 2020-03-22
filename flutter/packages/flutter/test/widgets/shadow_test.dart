// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Shadows on BoxDecoration', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.all(50.0),
            decoration: BoxDecoration(
              boxShadow: kElevationToShadow[9],
            ),
            height: 100.0,
            width: 100.0,
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('shadow.BoxDecoration.disabled.png'),
    );
    debugDisableShadows = false;
    tester.binding.reassembleApplication();
    await tester.pump();
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('shadow.BoxDecoration.enabled.png'),
    );
    debugDisableShadows = true;
  }, skip: isBrowser);

  testWidgets('Shadows on ShapeDecoration', (WidgetTester tester) async {
    debugDisableShadows = false;
    Widget build(int elevation) {
      return Center(
        child: RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.all(150.0),
            decoration: ShapeDecoration(
              shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              shadows: kElevationToShadow[elevation],
            ),
            height: 100.0,
            width: 100.0,
          ),
        ),
      );
    }
    for (int elevation in kElevationToShadow.keys) {
      await tester.pumpWidget(build(elevation));
      await expectLater(
        find.byType(Container),
        matchesGoldenFile('shadow.ShapeDecoration.$elevation.png'),
      );
    }
    debugDisableShadows = true;
  });

  testWidgets('Shadows with PhysicalLayer', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.all(150.0),
            color: Colors.yellow[200],
            child: PhysicalModel(
              elevation: 9.0,
              color: Colors.blue[900],
              child: const SizedBox(
                height: 100.0,
                width: 100.0,
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('shadow.PhysicalModel.disabled.png'),
    );
    debugDisableShadows = false;
    tester.binding.reassembleApplication();
    await tester.pump();
    await expectLater(
      find.byType(Container),
      matchesGoldenFile('shadow.PhysicalModel.enabled.png'),
    );
    debugDisableShadows = true;
  }, skip: isBrowser);

  for (final int elevation in kElevationToShadow.keys) {
    testWidgets('Shadows with PhysicalShape $elevation', (WidgetTester tester) async {
      debugDisableShadows = false;
      Widget build(double elevation) {
        return Center(
          child: RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(150.0),
              color: Colors.yellow[200],
              child: PhysicalShape(
                color: Colors.green[900],
                clipper: ShapeBorderClipper(shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(20.0))),
                elevation: elevation,
                child: const SizedBox(
                  height: 100.0,
                  width: 100.0,
                ),
              ),
            ),
          ),
        );
      }
      await tester.pumpWidget(build(elevation.toDouble()));
      await expectLater(
        find.byType(Container),
        matchesGoldenFile('shadow.PhysicalShape.$elevation.png'),
      );
      debugDisableShadows = true;
    });
  }
}
