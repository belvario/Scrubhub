// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/run.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/web/web_runner.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

void main() {
  group('run', () {
    MockApplicationPackageFactory mockApplicationPackageFactory;
    MockDeviceManager mockDeviceManager;
    MockFlutterVersion mockStableFlutterVersion;
    MockFlutterVersion mockUnstableFlutterVersion;

    setUpAll(() {
      Cache.disableLocking();
      mockApplicationPackageFactory = MockApplicationPackageFactory();
      mockDeviceManager = MockDeviceManager();
      mockStableFlutterVersion = MockFlutterVersion(isStable: true);
      mockUnstableFlutterVersion = MockFlutterVersion(isStable: false);
    });

    testUsingContext('fails when target not found', () async {
      final RunCommand command = RunCommand();
      applyMocksToCommand(command);
      try {
        await createTestCommandRunner(command).run(<String>['run', '-t', 'abc123', '--no-pub']);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode ?? 1, 1);
      }
    });

    group('dart-flags option', () {
      setUpAll(() {
        when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
          return Stream<Device>.fromIterable(<Device>[
            FakeDevice(),
          ]);
        });
      });

      RunCommand command;
      List<String> args;
      setUp(() {
        command = TestRunCommand();
        args = <String> [
          'run',
          '--dart-flags', '"--observe"',
          '--no-hot',
          '--no-pub',
        ];
      });

      testUsingContext('is not available on stable channel', () async {
        // Stable branch.
        try {
          await createTestCommandRunner(command).run(args);
          fail('Expect exception');
        // ignore: unused_catch_clause
        } on UsageException catch(e) {
          // Not available while on stable branch.
        }
      }, overrides: <Type, Generator>{
        DeviceManager: () => mockDeviceManager,
        FlutterVersion: () => mockStableFlutterVersion,
      });

      testUsingContext('is populated in debug mode', () async {
        // FakeDevice.startApp checks that --dart-flags doesn't get dropped and
        // throws ToolExit with FakeDevice.kSuccess if the flag is populated.
        try {
          await createTestCommandRunner(command).run(args);
          fail('Expect exception');
        } on ToolExit catch (e) {
          expect(e.exitCode, FakeDevice.kSuccess);
        }
      }, overrides: <Type, Generator>{
        ApplicationPackageFactory: () => mockApplicationPackageFactory,
        DeviceManager: () => mockDeviceManager,
        FlutterVersion: () => mockUnstableFlutterVersion,
      });

      testUsingContext('is populated in profile mode', () async {
        args.add('--profile');

        // FakeDevice.startApp checks that --dart-flags doesn't get dropped and
        // throws ToolExit with FakeDevice.kSuccess if the flag is populated.
        try {
          await createTestCommandRunner(command).run(args);
          fail('Expect exception');
        } on ToolExit catch (e) {
          expect(e.exitCode, FakeDevice.kSuccess);
        }
      }, overrides: <Type, Generator>{
        ApplicationPackageFactory: () => mockApplicationPackageFactory,
        DeviceManager: () => mockDeviceManager,
        FlutterVersion: () => mockUnstableFlutterVersion,
      });

      testUsingContext('is not populated in release mode', () async {
        args.add('--release');

        // FakeDevice.startApp checks that --dart-flags *does* get dropped and
        // throws ToolExit with FakeDevice.kSuccess if the flag is set to the
        // empty string.
        try {
          await createTestCommandRunner(command).run(args);
          fail('Expect exception');
        } on ToolExit catch (e) {
          expect(e.exitCode, FakeDevice.kSuccess);
        }
      }, overrides: <Type, Generator>{
        ApplicationPackageFactory: () => mockApplicationPackageFactory,
        DeviceManager: () => mockDeviceManager,
        FlutterVersion: () => mockUnstableFlutterVersion,
      });
    });

    testUsingContext('should only request artifacts corresponding to connected devices', () async {
      when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
        return Stream<Device>.fromIterable(<Device>[
          MockDevice(TargetPlatform.android_arm),
        ]);
      });

      expect(await RunCommand().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.androidGenSnapshot,
      }));

      when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
        return Stream<Device>.fromIterable(<Device>[
          MockDevice(TargetPlatform.ios),
        ]);
      });

      expect(await RunCommand().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.iOS,
      }));

      when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
        return Stream<Device>.fromIterable(<Device>[
          MockDevice(TargetPlatform.ios),
          MockDevice(TargetPlatform.android_arm),
        ]);
      });

      expect(await RunCommand().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.iOS,
        DevelopmentArtifact.androidGenSnapshot,
      }));

      when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
        return Stream<Device>.fromIterable(<Device>[
          MockDevice(TargetPlatform.web_javascript),
        ]);
      });

      expect(await RunCommand().requiredArtifacts, unorderedEquals(<DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.web,
      }));
    }, overrides: <Type, Generator>{
      DeviceManager: () => mockDeviceManager,
    });

    group('--dart-define option', () {
      MemoryFileSystem fs;
      MockProcessManager mockProcessManager;
      MockWebRunnerFactory mockWebRunnerFactory;

      setUpAll(() {
        when(mockDeviceManager.getDevices()).thenAnswer((Invocation invocation) {
          return Stream<Device>.fromIterable(<Device>[
            FakeDevice().._targetPlatform = TargetPlatform.web_javascript,
          ]);
        });
      });

      RunCommand command;
      List<String> args;
      setUp(() {
        command = TestRunCommand();
        args = <String> [
          'run',
          '--dart-define=FOO=bar',
          '--no-hot',
          '--no-pub',
        ];
        applyMocksToCommand(command);
        fs = MemoryFileSystem();
        mockProcessManager = MockProcessManager();
        mockWebRunnerFactory = MockWebRunnerFactory();
      });

      testUsingContext('populates the environment', () async {
        final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_run_test.');
        fs.currentDirectory = tempDir;

        final Directory libDir = tempDir.childDirectory('lib');
        libDir.createSync();
        final File mainFile = libDir.childFile('main.dart');
        mainFile.writeAsStringSync('void main() {}');

        final Directory webDir = tempDir.childDirectory('web');
        webDir.createSync();
        final File indexFile = libDir.childFile('index.html');
        indexFile.writeAsStringSync('<h1>Hello</h1>');

        await createTestCommandRunner(command).run(args);
        expect(mockWebRunnerFactory._dartDefines, <String>['FOO=bar']);
      }, overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(
          isWebEnabled: true,
        ),
        FileSystem: () => fs,
        ProcessManager: () => mockProcessManager,
        DeviceManager: () => mockDeviceManager,
        FlutterVersion: () => mockStableFlutterVersion,
        WebRunnerFactory: () => mockWebRunnerFactory,
      });

      testUsingContext('populates dartDefines in --machine mode', () async {
        final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_run_test.');
        fs.currentDirectory = tempDir;

        final Directory libDir = tempDir.childDirectory('lib');
        libDir.createSync();
        final File mainFile = libDir.childFile('main.dart');
        mainFile.writeAsStringSync('void main() {}');

        final Directory webDir = tempDir.childDirectory('web');
        webDir.createSync();
        final File indexFile = libDir.childFile('index.html');
        indexFile.writeAsStringSync('<h1>Hello</h1>');

        when(mockDeviceManager.deviceDiscoverers).thenReturn(<DeviceDiscovery>[]);

        args.add('--machine');
        await createTestCommandRunner(command).run(args);
        expect(mockWebRunnerFactory._dartDefines, <String>['FOO=bar']);
      }, overrides: <Type, Generator>{
        DeviceManager: () => mockDeviceManager,
        FeatureFlags: () => TestFeatureFlags(
          isWebEnabled: true,
        ),
        FileSystem: () => fs,
        ProcessManager: () => mockProcessManager,
        DeviceManager: () => mockDeviceManager,
        FlutterVersion: () => mockStableFlutterVersion,
        WebRunnerFactory: () => mockWebRunnerFactory,
      });
    });
  });
}

class MockDeviceManager extends Mock implements DeviceManager {}
class MockDevice extends Mock implements Device {
  MockDevice(this._targetPlatform);

  final TargetPlatform _targetPlatform;

  @override
  Future<TargetPlatform> get targetPlatform async => _targetPlatform;
}

class TestRunCommand extends RunCommand {
  @override
  // ignore: must_call_super
  Future<void> validateCommand() async {
    devices = await deviceManager.getDevices().toList();
  }
}

class MockStableFlutterVersion extends MockFlutterVersion {
  @override
  bool get isMaster => false;
}

class FakeDevice extends Fake implements Device {
  static const int kSuccess = 1;
  static const int kFailure = -1;
  TargetPlatform _targetPlatform = TargetPlatform.ios;

  @override
  String get id => 'fake_device';

  void _throwToolExit(int code) => throwToolExit(null, exitCode: code);

  @override
  Future<bool> get isLocalEmulator => Future<bool>.value(false);

  @override
  bool get supportsHotReload => false;

  @override
  Future<String> get sdkNameAndVersion => Future<String>.value('');

  @override
  DeviceLogReader getLogReader({ ApplicationPackage app }) {
    return MockDeviceLogReader();
  }

  @override
  String get name => 'FakeDevice';

  @override
  Future<TargetPlatform> get targetPlatform async => _targetPlatform;

  @override
  final PlatformType platformType = PlatformType.ios;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool usesTerminalUi = true,
    bool ipv6 = false,
  }) async {
    final String dartFlags = debuggingOptions.dartFlags;
    // In release mode, --dart-flags should be set to the empty string and
    // provided flags should be dropped. In debug and profile modes,
    // --dart-flags should not be empty.
    if (debuggingOptions.buildInfo.isRelease) {
      if (dartFlags.isNotEmpty) {
        _throwToolExit(kFailure);
      }
      _throwToolExit(kSuccess);
    } else {
      if (dartFlags.isEmpty) {
        _throwToolExit(kFailure);
      }
      _throwToolExit(kSuccess);
    }
    return null;
  }
}

class MockWebRunnerFactory extends Mock implements WebRunnerFactory {
  List<String> _dartDefines;

  @override
  ResidentRunner createWebRunner(
    FlutterDevice device, {
    String target,
    bool stayResident,
    FlutterProject flutterProject,
    bool ipv6,
    DebuggingOptions debuggingOptions,
    List<String> dartDefines,
  }) {
    _dartDefines = dartDefines;
    return MockWebRunner();
  }
}

class MockWebRunner extends Mock implements ResidentRunner {
  @override
  bool get debuggingEnabled => false;

  @override
  Future<int> run({
    Completer<DebugConnectionInfo> connectionInfoCompleter,
    Completer<void> appStartedCompleter,
    String route,
  }) async {
    return 0;
  }

  @override
  Future<int> waitForAppToFinish() async => 0;
}
