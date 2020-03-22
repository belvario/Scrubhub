// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('$WidgetsBinding initializes with $LiveTestWidgetsFlutterBinding when FLUTTER_TEST = "false"', () {
    TestWidgetsFlutterBinding.ensureInitialized(<String, String>{'FLUTTER_TEST': 'false'});
    expect(WidgetsBinding.instance, isInstanceOf<LiveTestWidgetsFlutterBinding>());
  }, onPlatform: const <String, dynamic>{
    'browser': <Skip>[Skip('Browser will not use the live binding')]
  });
}
