// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_linux.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/linux/makefile.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

void main() {
  MockProcessManager mockProcessManager;
  MockProcess mockProcess;
  MockPlatform linuxPlatform;
  MockPlatform notLinuxPlatform;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    mockProcessManager = MockProcessManager();
    mockProcess = MockProcess();
    linuxPlatform = MockPlatform();
    notLinuxPlatform = MockPlatform();
    when(mockProcess.exitCode).thenAnswer((Invocation invocation) async {
      return 0;
    });
    when(mockProcess.stderr).thenAnswer((Invocation invocation) {
      return const Stream<List<int>>.empty();
    });
    when(mockProcess.stdout).thenAnswer((Invocation invocation) {
      return Stream<List<int>>.fromIterable(<List<int>>[utf8.encode('STDOUT STUFF')]);
    });
    when(linuxPlatform.isLinux).thenReturn(true);
    when(linuxPlatform.isWindows).thenReturn(false);
    when(notLinuxPlatform.isLinux).thenReturn(false);
    when(notLinuxPlatform.isWindows).thenReturn(false);
  });

  // Creates the mock files necessary to run a build.
  void setUpMockProjectFilesForBuild() {
    fs.file('linux/build.sh').createSync(recursive: true);
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
  }

  // Sets up mock expectation for running 'make'.
  void expectMakeInvocationWithMode(String buildModeName) {
    when(mockProcessManager.start(<String>[
      'make',
      '-C',
      '/linux',
      'BUILD=$buildModeName',
    ])).thenAnswer((Invocation invocation) async {
      return mockProcess;
    });
  }

  testUsingContext('Linux build fails when there is no linux project', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    expect(createTestCommandRunner(command).run(
      const <String>['build', 'linux']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => linuxPlatform,
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build fails on non-linux platform', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'linux']
    ), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    Platform: () => notLinuxPlatform,
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build invokes make and writes temporary files', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    expectMakeInvocationWithMode('release');

    await createTestCommandRunner(command).run(
      const <String>['build', 'linux']
    );
    expect(fs.file('linux/flutter/ephemeral/generated_config.mk').existsSync(), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => mockProcessManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Handles argument error from missing make', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    when(mockProcessManager.start(<String>[
      'make',
      '-C',
      '/linux',
      'BUILD=release',
    ])).thenThrow(ArgumentError());

    expect(createTestCommandRunner(command).run(
      const <String>['build', 'linux']
    ), throwsToolExit(message: 'make not found. Run \'flutter doctor\' for more information.'));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => mockProcessManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build does not spew stdout to status logger', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    expectMakeInvocationWithMode('debug');

    await createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--debug']
    );
    expect(testLogger.statusText, isNot(contains('STDOUT STUFF')));
    expect(testLogger.traceText, contains('STDOUT STUFF'));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => mockProcessManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build --debug passes debug mode to make', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    expectMakeInvocationWithMode('debug');

    await createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--debug']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => mockProcessManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Linux build --profile passes profile mode to make', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    expectMakeInvocationWithMode('profile');

    await createTestCommandRunner(command).run(
      const <String>['build', 'linux', '--profile']
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => mockProcessManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('linux can extract binary name from Makefile', () async {
    fs.file('linux/Makefile')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
# Comment
SOMETHING_ELSE=FOO
BINARY_NAME=fizz_bar
''');
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(makefileExecutableName(flutterProject.linux), 'fizz_bar');
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('Refuses to build for Linux when feature is disabled', () {
    final CommandRunner<void> runner = createTestCommandRunner(BuildCommand());

    expect(() => runner.run(<String>['build', 'linux']),
        throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: false),
  });

  testUsingContext('Release build prints an under-construction warning', () async {
    final BuildCommand command = BuildCommand();
    applyMocksToCommand(command);
    setUpMockProjectFilesForBuild();
    expectMakeInvocationWithMode('release');

    await createTestCommandRunner(command).run(
      const <String>['build', 'linux']
    );

    expect(testLogger.statusText, contains('🚧'));
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => mockProcessManager,
    Platform: () => linuxPlatform,
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
  });

  testUsingContext('hidden when not enabled on Linux host', () {
    when(platform.isLinux).thenReturn(true);

    expect(BuildLinuxCommand().hidden, true);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: false),
    Platform: () => MockPlatform(),
  });

  testUsingContext('Not hidden when enabled and on Linux host', () {
    when(platform.isLinux).thenReturn(true);

    expect(BuildLinuxCommand().hidden, false);
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(isLinuxEnabled: true),
    Platform: () => MockPlatform(),
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': '/',
  };
}
