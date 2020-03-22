// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class MockFlutterVersion extends Mock implements FlutterVersion {}
class MockAndroidSdk extends Mock implements AndroidSdk {}
class MockArtifacts extends Mock implements Artifacts {}
class MockXcode extends Mock implements Xcode {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}

class _FakeGenSnapshot implements GenSnapshot {
  _FakeGenSnapshot({
    this.succeed = true,
  });

  final bool succeed;
  Map<String, String> outputs = <String, String>{};
  int _callCount = 0;
  SnapshotType _snapshotType;
  String _depfilePath;
  List<String> _additionalArgs;

  int get callCount => _callCount;

  SnapshotType get snapshotType => _snapshotType;

  String get depfilePath => _depfilePath;

  List<String> get additionalArgs => _additionalArgs;

  @override
  Future<int> run({
    SnapshotType snapshotType,
    String depfilePath,
    DarwinArch darwinArch,
    Iterable<String> additionalArgs = const <String>[],
  }) async {
    _callCount += 1;
    _snapshotType = snapshotType;
    _depfilePath = depfilePath;
    _additionalArgs = additionalArgs.toList();

    if (!succeed) {
      return 1;
    }
    outputs.forEach((String filePath, String fileContent) {
      fs.file(filePath).writeAsString(fileContent);
    });
    return 0;
  }
}

void main() {
  group('SnapshotType', () {
    test('throws, if build mode is null', () {
      expect(
        () => SnapshotType(TargetPlatform.android_x64, null),
        throwsA(anything),
      );
    });
    test('does not throw, if target platform is null', () {
      expect(SnapshotType(null, BuildMode.release), isNotNull);
    });
  });

  group('GenSnapshot', () {
    GenSnapshot genSnapshot;
    MockArtifacts mockArtifacts;
    MockProcessManager mockProcessManager;
    MockProcess mockProc;

    setUp(() async {
      genSnapshot = const GenSnapshot();
      mockArtifacts = MockArtifacts();
      mockProcessManager = MockProcessManager();
      mockProc = MockProcess();
    });

    final Map<Type, Generator> contextOverrides = <Type, Generator>{
      Artifacts: () => mockArtifacts,
      ProcessManager: () => mockProcessManager,
    };

    testUsingContext('android_x64', () async {
      when(mockArtifacts.getArtifactPath(Artifact.genSnapshot,
              platform: TargetPlatform.android_x64, mode: BuildMode.release))
          .thenReturn('gen_snapshot');
      when(mockProcessManager.start(any,
              workingDirectory: anyNamed('workingDirectory'),
              environment: anyNamed('environment')))
          .thenAnswer((_) => Future<Process>.value(mockProc));
      when(mockProc.stdout).thenAnswer((_) => const Stream<List<int>>.empty());
      when(mockProc.stderr).thenAnswer((_) => const Stream<List<int>>.empty());
      await genSnapshot.run(
          snapshotType:
              SnapshotType(TargetPlatform.android_x64, BuildMode.release),
          darwinArch: null,
          additionalArgs: <String>['--additional_arg']);
      verify(mockProcessManager.start(
        <String>[
          'gen_snapshot',
          '--causal_async_stacks',
          '--additional_arg',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
    }, overrides: contextOverrides);

    testUsingContext('iOS armv7', () async {
      when(mockArtifacts.getArtifactPath(Artifact.genSnapshot,
              platform: TargetPlatform.ios, mode: BuildMode.release))
          .thenReturn('gen_snapshot');
      when(mockProcessManager.start(any,
              workingDirectory: anyNamed('workingDirectory'),
              environment: anyNamed('environment')))
          .thenAnswer((_) => Future<Process>.value(mockProc));
      when(mockProc.stdout).thenAnswer((_) => const Stream<List<int>>.empty());
      when(mockProc.stderr).thenAnswer((_) => const Stream<List<int>>.empty());
      await genSnapshot.run(
          snapshotType: SnapshotType(TargetPlatform.ios, BuildMode.release),
          darwinArch: DarwinArch.armv7,
          additionalArgs: <String>['--additional_arg']);
      verify(mockProcessManager.start(
        <String>[
          'gen_snapshot_armv7',
          '--causal_async_stacks',
          '--additional_arg',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment')),
      ).called(1);
    }, overrides: contextOverrides);

    testUsingContext('iOS arm64', () async {
      when(mockArtifacts.getArtifactPath(Artifact.genSnapshot,
              platform: TargetPlatform.ios, mode: BuildMode.release))
          .thenReturn('gen_snapshot');
      when(mockProcessManager.start(any,
              workingDirectory: anyNamed('workingDirectory'),
              environment: anyNamed('environment')))
          .thenAnswer((_) => Future<Process>.value(mockProc));
      when(mockProc.stdout).thenAnswer((_) => const Stream<List<int>>.empty());
      when(mockProc.stderr).thenAnswer((_) => const Stream<List<int>>.empty());
      await genSnapshot.run(
          snapshotType: SnapshotType(TargetPlatform.ios, BuildMode.release),
          darwinArch: DarwinArch.arm64,
          additionalArgs: <String>['--additional_arg']);
      verify(mockProcessManager.start(
        <String>[
          'gen_snapshot_arm64',
          '--causal_async_stacks',
          '--additional_arg',
        ],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
    }, overrides: contextOverrides);

    testUsingContext('--strip filters outputs', () async {
      when(mockArtifacts.getArtifactPath(Artifact.genSnapshot,
              platform: TargetPlatform.android_x64, mode: BuildMode.release))
          .thenReturn('gen_snapshot');
      when(mockProcessManager.start(
              <String>['gen_snapshot', '--causal_async_stacks', '--strip'],
              workingDirectory: anyNamed('workingDirectory'),
              environment: anyNamed('environment')))
          .thenAnswer((_) => Future<Process>.value(mockProc));
      when(mockProc.stdout).thenAnswer((_) => const Stream<List<int>>.empty());
      when(mockProc.stderr)
        .thenAnswer((_) => Stream<String>.fromIterable(<String>[
          '--ABC\n',
          'Warning: Generating ELF library without DWARF debugging information.\n',
          '--XYZ\n',
        ])
        .transform<List<int>>(utf8.encoder));
      await genSnapshot.run(
          snapshotType:
              SnapshotType(TargetPlatform.android_x64, BuildMode.release),
          darwinArch: null,
          additionalArgs: <String>['--strip']);
      verify(mockProcessManager.start(
              <String>['gen_snapshot', '--causal_async_stacks', '--strip'],
              workingDirectory: anyNamed('workingDirectory'),
              environment: anyNamed('environment')))
          .called(1);
      expect(testLogger.errorText, contains('ABC'));
      expect(testLogger.errorText, isNot(contains('ELF library')));
      expect(testLogger.errorText, contains('XYZ'));
    }, overrides: contextOverrides);
  });

  group('Snapshotter - AOT', () {
    const String kSnapshotDart = 'snapshot.dart';
    const String kSDKPath = '/path/to/sdk';
    String skyEnginePath;

    _FakeGenSnapshot genSnapshot;
    MemoryFileSystem fs;
    AOTSnapshotter snapshotter;
    AOTSnapshotter snapshotterWithTimings;
    MockAndroidSdk mockAndroidSdk;
    MockArtifacts mockArtifacts;
    MockXcode mockXcode;
    BufferLogger bufferLogger;

    setUp(() async {
      fs = MemoryFileSystem();
      fs.file(kSnapshotDart).createSync();
      fs.file('.packages').writeAsStringSync('sky_engine:file:///flutter/bin/cache/pkg/sky_engine/lib/');

      skyEnginePath = fs.path.fromUri(Uri.file('/flutter/bin/cache/pkg/sky_engine'));
      fs.directory(fs.path.join(skyEnginePath, 'lib', 'ui')).createSync(recursive: true);
      fs.directory(fs.path.join(skyEnginePath, 'sdk_ext')).createSync(recursive: true);
      fs.file(fs.path.join(skyEnginePath, '.packages')).createSync();
      fs.file(fs.path.join(skyEnginePath, 'lib', 'ui', 'ui.dart')).createSync();
      fs.file(fs.path.join(skyEnginePath, 'sdk_ext', 'vmservice_io.dart')).createSync();

      genSnapshot = _FakeGenSnapshot();
      snapshotter = AOTSnapshotter();
      snapshotterWithTimings = AOTSnapshotter(reportTimings: true);
      mockAndroidSdk = MockAndroidSdk();
      mockArtifacts = MockArtifacts();
      mockXcode = MockXcode();
      when(mockXcode.sdkLocation(any)).thenAnswer((_) => Future<String>.value(kSDKPath));

      bufferLogger = BufferLogger();
      for (BuildMode mode in BuildMode.values) {
        when(mockArtifacts.getArtifactPath(Artifact.snapshotDart,
            platform: anyNamed('platform'), mode: mode)).thenReturn(kSnapshotDart);
      }
    });

    final Map<Type, Generator> contextOverrides = <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Artifacts: () => mockArtifacts,
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      GenSnapshot: () => genSnapshot,
      Xcode: () => mockXcode,
      Logger: () => bufferLogger,
    };

    testUsingContext('iOS debug AOT snapshot is invalid', () async {
      final String outputPath = fs.path.join('build', 'foo');
      expect(await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.debug,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        bitcode: false,
      ), isNot(equals(0)));
    }, overrides: contextOverrides);

    testUsingContext('Android arm debug AOT snapshot is invalid', () async {
      final String outputPath = fs.path.join('build', 'foo');
      expect(await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.debug,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        bitcode: false,
      ), isNot(0));
    }, overrides: contextOverrides);

    testUsingContext('Android arm64 debug AOT snapshot is invalid', () async {
      final String outputPath = fs.path.join('build', 'foo');
      expect(await snapshotter.build(
        platform: TargetPlatform.android_arm64,
        buildMode: BuildMode.debug,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        bitcode: false,
      ), isNot(0));
    }, overrides: contextOverrides);

    testUsingContext('iOS profile AOT with bitcode uses right flags', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      final String assembly = fs.path.join(outputPath, 'snapshot_assembly.S');
      genSnapshot.outputs = <String, String>{
        assembly: 'blah blah\n.section __DWARF\nblah blah\n',
      };

      final RunResult successResult = RunResult(ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        darwinArch: DarwinArch.armv7,
        bitcode: true,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.ios);
      expect(genSnapshot.snapshotType.mode, BuildMode.profile);
      expect(genSnapshot.additionalArgs, <String>[
        '--deterministic',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=$assembly',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        'main.dill',
      ]);

      final VerificationResult toVerifyCC = verify(xcode.cc(captureAny));
      expect(toVerifyCC.callCount, 1);
      final dynamic ccArgs = toVerifyCC.captured.first;
      expect(ccArgs, contains('-fembed-bitcode'));
      expect(ccArgs, contains('-isysroot'));
      expect(ccArgs, contains(kSDKPath));

      final VerificationResult toVerifyClang = verify(xcode.clang(captureAny));
      expect(toVerifyClang.callCount, 1);
      final dynamic clangArgs = toVerifyClang.captured.first;
      expect(clangArgs, contains('-fembed-bitcode'));
      expect(clangArgs, contains('-isysroot'));
      expect(clangArgs, contains(kSDKPath));

      final File assemblyFile = fs.file(assembly);
      expect(assemblyFile.existsSync(), true);
      expect(assemblyFile.readAsStringSync().contains('.section __DWARF'), true);
    }, overrides: contextOverrides);

    testUsingContext('iOS release AOT with bitcode uses right flags', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      final String assembly = fs.path.join(outputPath, 'snapshot_assembly.S');
      genSnapshot.outputs = <String, String>{
        assembly: 'blah blah\n.section __DWARF\nblah blah\n',
      };

      final RunResult successResult = RunResult(ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        darwinArch: DarwinArch.armv7,
        bitcode: true,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.ios);
      expect(genSnapshot.snapshotType.mode, BuildMode.release);
      expect(genSnapshot.additionalArgs, <String>[
        '--deterministic',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=$assembly',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        'main.dill',
      ]);

      final VerificationResult toVerifyCC = verify(xcode.cc(captureAny));
      expect(toVerifyCC.callCount, 1);
      final dynamic ccArgs = toVerifyCC.captured.first;
      expect(ccArgs, contains('-fembed-bitcode'));
      expect(ccArgs, contains('-isysroot'));
      expect(ccArgs, contains(kSDKPath));

      final VerificationResult toVerifyClang = verify(xcode.clang(captureAny));
      expect(toVerifyClang.callCount, 1);
      final dynamic clangArgs = toVerifyClang.captured.first;
      expect(clangArgs, contains('-fembed-bitcode'));
      expect(clangArgs, contains('-isysroot'));
      expect(clangArgs, contains(kSDKPath));

      final File assemblyFile = fs.file(assembly);
      final File assemblyBitcodeFile = fs.file('$assembly.stripped.S');
      expect(assemblyFile.existsSync(), true);
      expect(assemblyBitcodeFile.existsSync(), true);
      expect(assemblyFile.readAsStringSync().contains('.section __DWARF'), true);
      expect(assemblyBitcodeFile.readAsStringSync().contains('.section __DWARF'), false);
    }, overrides: contextOverrides);

    testUsingContext('builds iOS armv7 profile AOT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      final String assembly = fs.path.join(outputPath, 'snapshot_assembly.S');
      genSnapshot.outputs = <String, String>{
        assembly: 'blah blah\n.section __DWARF\nblah blah\n',
      };

      final RunResult successResult = RunResult(ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        darwinArch: DarwinArch.armv7,
        bitcode: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.ios);
      expect(genSnapshot.snapshotType.mode, BuildMode.profile);
      expect(genSnapshot.additionalArgs, <String>[
        '--deterministic',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=$assembly',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        'main.dill',
      ]);
      verifyNever(xcode.cc(argThat(contains('-fembed-bitcode'))));
      verifyNever(xcode.clang(argThat(contains('-fembed-bitcode'))));

      verify(xcode.cc(argThat(contains('-isysroot')))).called(1);
      verify(xcode.clang(argThat(contains('-isysroot')))).called(1);

      final File assemblyFile = fs.file(assembly);
      expect(assemblyFile.existsSync(), true);
      expect(assemblyFile.readAsStringSync().contains('.section __DWARF'), true);
    }, overrides: contextOverrides);

    testUsingContext('builds iOS arm64 profile AOT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'snapshot_assembly.S'): '',
      };

      final RunResult successResult = RunResult(ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.profile,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        darwinArch: DarwinArch.arm64,
        bitcode: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.ios);
      expect(genSnapshot.snapshotType.mode, BuildMode.profile);
      expect(genSnapshot.additionalArgs, <String>[
        '--deterministic',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=${fs.path.join(outputPath, 'snapshot_assembly.S')}',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('builds iOS release armv7 AOT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'snapshot_assembly.S'): '',
      };

      final RunResult successResult = RunResult(ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        darwinArch: DarwinArch.armv7,
        bitcode: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.ios);
      expect(genSnapshot.snapshotType.mode, BuildMode.release);
      expect(genSnapshot.additionalArgs, <String>[
        '--deterministic',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=${fs.path.join(outputPath, 'snapshot_assembly.S')}',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('builds iOS release arm64 AOT snapshot', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'snapshot_assembly.S'): '',
      };

      final RunResult successResult = RunResult(ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.ios,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        darwinArch: DarwinArch.arm64,
        bitcode: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.ios);
      expect(genSnapshot.snapshotType.mode, BuildMode.release);
      expect(genSnapshot.additionalArgs, <String>[
        '--deterministic',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=${fs.path.join(outputPath, 'snapshot_assembly.S')}',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('builds shared library for android-arm', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        bitcode: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.android_arm);
      expect(genSnapshot.snapshotType.mode, BuildMode.release);
      expect(genSnapshot.additionalArgs, <String>[
        '--deterministic',
        '--snapshot_kind=app-aot-elf',
        '--elf=build/foo/app.so',
        '--strip',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('builds shared library for android-arm64', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      final int genSnapshotExitCode = await snapshotter.build(
        platform: TargetPlatform.android_arm64,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        bitcode: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(genSnapshot.snapshotType.platform, TargetPlatform.android_arm64);
      expect(genSnapshot.snapshotType.mode, BuildMode.release);
      expect(genSnapshot.additionalArgs, <String>[
        '--deterministic',
        '--snapshot_kind=app-aot-elf',
        '--elf=build/foo/app.so',
        '--strip',
        'main.dill',
      ]);
    }, overrides: contextOverrides);

    testUsingContext('reports timing', () async {
      fs.file('main.dill').writeAsStringSync('binary magic');

      final String outputPath = fs.path.join('build', 'foo');
      fs.directory(outputPath).createSync(recursive: true);

      genSnapshot.outputs = <String, String>{
        fs.path.join(outputPath, 'app.so'): '',
      };

      final RunResult successResult = RunResult(ProcessResult(1, 0, '', ''), <String>['command name', 'arguments...']);
      when(xcode.cc(any)).thenAnswer((_) => Future<RunResult>.value(successResult));
      when(xcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(successResult));

      final int genSnapshotExitCode = await snapshotterWithTimings.build(
        platform: TargetPlatform.android_arm,
        buildMode: BuildMode.release,
        mainPath: 'main.dill',
        packagesPath: '.packages',
        outputPath: outputPath,
        bitcode: false,
      );

      expect(genSnapshotExitCode, 0);
      expect(genSnapshot.callCount, 1);
      expect(bufferLogger.statusText, matches(RegExp(r'snapshot\(CompileTime\): \d+ ms.')));
    }, overrides: contextOverrides);
  });
}
