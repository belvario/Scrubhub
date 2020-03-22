// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/test/test_compiler.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/testbed.dart';

void main() {
  group(TestCompiler, () {
    Testbed testbed;
    FakeTestCompiler testCompiler;
    MockResidentCompiler residentCompiler;

    setUp(() {
      testbed = Testbed(
        setup: () async {
          fs.file('pubspec.yaml').createSync();
          fs.file('.packages').createSync();
          fs.file('test/foo.dart').createSync(recursive: true);
          residentCompiler = MockResidentCompiler();
          testCompiler = FakeTestCompiler(
            BuildMode.debug,
            false,
            FlutterProject.current(),
            residentCompiler,
          );
        },
      );
    });

    test('Reports a dill file when compile is successful', () => testbed.run(() async {
      when(residentCompiler.recompile(
        'test/foo.dart',
        <Uri>[Uri.parse('test/foo.dart')],
        outputPath: testCompiler.outputDill.path,
      )).thenAnswer((Invocation invocation) async {
        fs.file('abc.dill').createSync();
        return const CompilerOutput('abc.dill', 0, <Uri>[]);
      });

      expect(await testCompiler.compile('test/foo.dart'), 'test/foo.dart.dill');
      expect(fs.file('test/foo.dart.dill').existsSync(), true);
    }));

    test('Reports null when a compile fails', () => testbed.run(() async {
      when(residentCompiler.recompile(
        'test/foo.dart',
        <Uri>[Uri.parse('test/foo.dart')],
        outputPath: testCompiler.outputDill.path,
      )).thenAnswer((Invocation invocation) async {
        fs.file('abc.dill').createSync();
        return const CompilerOutput('abc.dill', 1, <Uri>[]);
      });

      expect(await testCompiler.compile('test/foo.dart'), null);
      expect(fs.file('test/foo.dart.dill').existsSync(), false);
      verify(residentCompiler.shutdown()).called(1);
    }));

    test('Disposing test compiler shuts down backing compiler', () => testbed.run(() async {
      testCompiler.compiler = residentCompiler;
      expect(testCompiler.compilerController.isClosed, false);
      await testCompiler.dispose();
      expect(testCompiler.compilerController.isClosed, true);
      verify(residentCompiler.shutdown()).called(1);
    }));
  });
}

/// Override the creation of the Resident Compiler to simplify testing.
class FakeTestCompiler extends TestCompiler {
  FakeTestCompiler(
    BuildMode buildMode,
    bool trackWidgetCreation,
    FlutterProject flutterProject,
    this.residentCompiler,
  ) : super(buildMode, trackWidgetCreation, flutterProject);

  final MockResidentCompiler residentCompiler;

  @override
  Future<ResidentCompiler> createCompiler() async {
    return residentCompiler;
  }
}

class MockResidentCompiler extends Mock implements ResidentCompiler {}
