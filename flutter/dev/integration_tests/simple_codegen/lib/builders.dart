// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:build/build.dart';

/// The builder factory used by the `build.yaml` script.
Builder simpleBuilder(BuilderOptions options) => SimpleBuilder();

/// A trivial builder which copies the contents of a `spec` file into a `dart` file.
class SimpleBuilder extends Builder {
  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{'.spec' : <String>['.dart']};


  @override
  Future<void> build(BuildStep buildStep) async {
    final AssetId output = buildStep.inputId.changeExtension('.dart');
    final String contents = await buildStep.readAsString(buildStep.inputId);
    buildStep.writeAsString(output, contents);
  }
}
