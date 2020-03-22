// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/web/bootstrap.dart';

import '../../src/common.dart';

void main() {
  test('generateBootstrapScript embeds urls correctly', () {
    final String result = generateBootstrapScript(
      requireUrl: 'require.js',
      mapperUrl: 'mapper.js',
      entrypoint: 'foo/bar/main.js',
    );
    // require js source is interpolated correctly.
    expect(result, contains('requireEl.src = "require.js";'));
    // stack trace mapper source is interpolated correctly.
    expect(result, contains('mapperEl.src = "mapper.js";'));
    // data-main is set to correct bootstrap module.
    expect(result, contains('requireEl.setAttribute("data-main", "main_module");'));
    // bootstrap main module has correct imports.
    expect(result, contains('require(["foo/bar/main.js", "dart_sdk"],'
      ' function(app, dart_sdk) {'));
  });

  test('generateMainModule embeds urls correctly', () {
    final String result = generateMainModule(
      entrypoint: 'foo/bar/main.js',
    );
    // bootstrap main module has correct defined module.
    expect(result, contains('define("main_module", ["foo/bar/main.js", "dart_sdk"], '
      'function(app, dart_sdk) {'));
  });
}
