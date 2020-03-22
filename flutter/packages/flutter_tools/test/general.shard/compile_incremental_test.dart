// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/async_guard.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  ProcessManager mockProcessManager;
  ResidentCompiler generator;
  MockProcess mockFrontendServer;
  MockStdIn mockFrontendServerStdIn;
  MockStream mockFrontendServerStdErr;
  StreamController<String> stdErrStreamController;

  setUp(() {
    generator = ResidentCompiler('sdkroot', buildMode: BuildMode.debug);
    mockProcessManager = MockProcessManager();
    mockFrontendServer = MockProcess();
    mockFrontendServerStdIn = MockStdIn();
    mockFrontendServerStdErr = MockStream();

    when(mockFrontendServer.stdin).thenReturn(mockFrontendServerStdIn);
    when(mockFrontendServer.stderr)
        .thenAnswer((Invocation invocation) => mockFrontendServerStdErr);
    when(mockFrontendServer.exitCode).thenAnswer((Invocation invocation) {
      return Completer<int>().future;
    });
    stdErrStreamController = StreamController<String>();
    when(mockFrontendServerStdErr.transform<String>(any))
        .thenAnswer((Invocation invocation) => stdErrStreamController.stream);

    when(mockProcessManager.canRun(any)).thenReturn(true);
    when(mockProcessManager.start(any)).thenAnswer(
        (Invocation invocation) => Future<Process>.value(mockFrontendServer)
    );
  });

  testUsingContext('incremental compile single dart compile', () async {
    when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
          Future<List<int>>.value(utf8.encode(
            'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0'
          ))
        ));

    final CompilerOutput output = await generator.recompile(
      '/path/to/main.dart',
        null /* invalidatedFiles */,
      outputPath: '/build/',
    );
    expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');
    verifyNoMoreInteractions(mockFrontendServerStdIn);
    expect(testLogger.errorText, equals('\nCompiler message:\nline1\nline2\n'));
    expect(output.outputFilename, equals('/path/to/main.dart.dill'));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
  });

  testUsingContext('incremental compile single dart compile abnormally terminates', () async {
    when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) => const Stream<List<int>>.empty()
    );

    expect(asyncGuard(() => generator.recompile(
      '/path/to/main.dart',
      null, /* invalidatedFiles */
      outputPath: '/build/',
    )), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
  });

  testUsingContext('incremental compile single dart compile abnormally terminates via exitCode', () async {
    when(mockFrontendServer.exitCode)
        .thenAnswer((Invocation invocation) async => 1);
    when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) => const Stream<List<int>>.empty()
    );

    expect(asyncGuard(() => generator.recompile(
      '/path/to/main.dart',
      null, /* invalidatedFiles */
      outputPath: '/build/',
    )), throwsA(isInstanceOf<ToolExit>()));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
  });

  testUsingContext('incremental compile and recompile', () async {
    final StreamController<List<int>> streamController = StreamController<List<int>>();
    when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) => streamController.stream);
    streamController.add(utf8.encode('result abc\nline0\nline1\nabc\nabc /path/to/main.dart.dill 0\n'));
    await generator.recompile(
      '/path/to/main.dart',
      null, /* invalidatedFiles */
      outputPath: '/build/',
    );
    expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');

    // No accept or reject commands should be issued until we
    // send recompile request.
    await _accept(streamController, generator, mockFrontendServerStdIn, '');
    await _reject(streamController, generator, mockFrontendServerStdIn, '', '');

    await _recompile(streamController, generator, mockFrontendServerStdIn,
      'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n');

    await _accept(streamController, generator, mockFrontendServerStdIn, '^accept\\n\$');

    await _recompile(streamController, generator, mockFrontendServerStdIn,
      'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n');
    // No sources returned from reject command.
    await _reject(streamController, generator, mockFrontendServerStdIn, 'result abc\nabc\n',
      '^reject\\n\$');
    verifyNoMoreInteractions(mockFrontendServerStdIn);
    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
    expect(testLogger.errorText, equals(
      '\nCompiler message:\nline0\nline1\n'
      '\nCompiler message:\nline1\nline2\n'
      '\nCompiler message:\nline1\nline2\n'
    ));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
  });

  testUsingContext('incremental compile and recompile twice', () async {
    final StreamController<List<int>> streamController = StreamController<List<int>>();
    when(mockFrontendServer.stdout)
        .thenAnswer((Invocation invocation) => streamController.stream);
    streamController.add(utf8.encode(
      'result abc\nline0\nline1\nabc\nabc /path/to/main.dart.dill 0\n'
    ));
    await generator.recompile('/path/to/main.dart', null /* invalidatedFiles */, outputPath: '/build/');
    expect(mockFrontendServerStdIn.getAndClear(), 'compile /path/to/main.dart\n');

    await _recompile(streamController, generator, mockFrontendServerStdIn,
      'result abc\nline1\nline2\nabc\nabc /path/to/main.dart.dill 0\n');
    await _recompile(streamController, generator, mockFrontendServerStdIn,
      'result abc\nline2\nline3\nabc\nabc /path/to/main.dart.dill 0\n');

    verifyNoMoreInteractions(mockFrontendServerStdIn);
    expect(mockFrontendServerStdIn.getAndClear(), isEmpty);
    expect(testLogger.errorText, equals(
      '\nCompiler message:\nline0\nline1\n'
      '\nCompiler message:\nline1\nline2\n'
      '\nCompiler message:\nline2\nline3\n'
    ));
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    OutputPreferences: () => OutputPreferences(showColor: false),
    Platform: kNoColorTerminalPlatform,
  });
}

Future<void> _recompile(
  StreamController<List<int>> streamController,
  ResidentCompiler generator,
  MockStdIn mockFrontendServerStdIn,
  String mockCompilerOutput,
) async {
  // Put content into the output stream after generator.recompile gets
  // going few lines below, resets completer.
  scheduleMicrotask(() {
    streamController.add(utf8.encode(mockCompilerOutput));
  });
  final CompilerOutput output = await generator.recompile(
    null /* mainPath */,
    <Uri>[Uri.parse('/path/to/main.dart')],
    outputPath: '/build/',
  );
  expect(output.outputFilename, equals('/path/to/main.dart.dill'));
  final String commands = mockFrontendServerStdIn.getAndClear();
  final RegExp re = RegExp('^recompile (.*)\\n/path/to/main.dart\\n(.*)\\n\$');
  expect(commands, matches(re));
  final Match match = re.firstMatch(commands);
  expect(match[1] == match[2], isTrue);
  mockFrontendServerStdIn.stdInWrites.clear();
}

Future<void> _accept(
  StreamController<List<int>> streamController,
  ResidentCompiler generator,
  MockStdIn mockFrontendServerStdIn,
  String expected,
) async {
  // Put content into the output stream after generator.recompile gets
  // going few lines below, resets completer.
  generator.accept();
  final String commands = mockFrontendServerStdIn.getAndClear();
  final RegExp re = RegExp(expected);
  expect(commands, matches(re));
  mockFrontendServerStdIn.stdInWrites.clear();
}

Future<void> _reject(
  StreamController<List<int>> streamController,
  ResidentCompiler generator,
  MockStdIn mockFrontendServerStdIn,
  String mockCompilerOutput,
  String expected,
) async {
  // Put content into the output stream after generator.recompile gets
  // going few lines below, resets completer.
  scheduleMicrotask(() {
    streamController.add(utf8.encode(mockCompilerOutput));
  });
  final CompilerOutput output = await generator.reject();
  expect(output, isNull);
  final String commands = mockFrontendServerStdIn.getAndClear();
  final RegExp re = RegExp(expected);
  expect(commands, matches(re));
  mockFrontendServerStdIn.stdInWrites.clear();
}

class MockProcess extends Mock implements Process {}
class MockProcessManager extends Mock implements ProcessManager {}
