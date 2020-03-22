// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('!chrome') // This test is not intended to run on the web.
import 'package:flutter/foundation.dart';
import '../flutter_test_alternative.dart';

void main() {
  test('isWeb is false for flutter tester', () {
    expect(kIsWeb, false);
  });
}
