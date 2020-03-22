// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import '../flutter_test_alternative.dart';

import 'rendering_tester.dart';

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/35426.
  test('RenderSliverFloatingPersistentHeader maxScrollObstructionExtent is 0', () {
    final TestRenderSliverFloatingPersistentHeader header = TestRenderSliverFloatingPersistentHeader(child: RenderSizedBox(const Size(400.0, 100.0)));
    final RenderViewport root = RenderViewport(
      axisDirection: AxisDirection.down,
      crossAxisDirection: AxisDirection.right,
      offset: ViewportOffset.zero(),
      cacheExtent: 0,
      children: <RenderSliver>[
        header,
      ],
    );
    layout(root);

    expect(header.geometry.maxScrollObstructionExtent, 0);
  });
}

class TestRenderSliverFloatingPersistentHeader extends RenderSliverFloatingPersistentHeader {
  TestRenderSliverFloatingPersistentHeader({
    RenderBox child,
  }) : super(child: child);

  @override
  double get maxExtent => 200;

  @override
  double get minExtent => 100;
}
