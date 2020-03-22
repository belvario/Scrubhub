// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io show ProcessSignal;

import 'package:flutter_tools/src/base/io.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'common.dart';

export 'package:process/process.dart' show ProcessManager;

typedef VoidCallback = void Function();

/// A command for [FakeProcessManager].
@immutable
class FakeCommand {
  const FakeCommand({
    @required this.command,
    this.workingDirectory,
    this.environment,
    this.duration = const Duration(),
    this.onRun,
    this.exitCode = 0,
    this.stdout = '',
    this.stderr = '',
  }) : assert(command != null),
       assert(duration != null),
       assert(exitCode != null),
       assert(stdout != null),
       assert(stderr != null);

  /// The exact commands that must be matched for this [FakeCommand] to be
  /// considered correct.
  final List<String> command;

  /// The exact working directory that must be matched for this [FakeCommand] to
  /// be considered correct.
  ///
  /// If this is null, the working directory is ignored.
  final String workingDirectory;

  /// The environment that must be matched for this [FakeCommand] to be considered correct.
  ///
  /// If this is null, then the environment is ignored.
  ///
  /// Otherwise, each key in this environment must be present and must have a
  /// value that matches the one given here for the [FakeCommand] to match.
  final Map<String, String> environment;

  /// The time to allow to elapse before returning the [exitCode], if this command
  /// is "executed".
  ///
  /// If you set this to a non-zero time, you should use a [FakeAsync] zone,
  /// otherwise the test will be artificially slow.
  final Duration duration;

  /// A callback that is run after [duration] expires but before the [exitCode]
  /// (and output) are passed back.
  final VoidCallback onRun;

  /// The process' exit code.
  ///
  /// To simulate a never-ending process, set [duration] to a value greater than
  /// 15 minutes (the timeout for our tests).
  ///
  /// To simulate a crash, subtract the crash signal number from 256. For example,
  /// SIGPIPE (-13) is 243.
  final int exitCode;

  /// The output to simulate on stdout. This will be encoded as UTF-8 and
  /// returned in one go.
  final String stdout;

  /// The output to simulate on stderr. This will be encoded as UTF-8 and
  /// returned in one go.
  final String stderr;

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a == null) {
      return b == null;
    }
    if (b == null || a.length != b.length) {
      return false;
    }
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  bool _matches(List<String> command, String workingDirectory, Map<String, String> environment) {
    if (!_listEquals(command, this.command)) {
      return false;
    }
    if (this.workingDirectory != null && workingDirectory != this.workingDirectory) {
      return false;
    }
    if (this.environment != null) {
      if (environment == null) {
        return false;
      }
      for (String key in environment.keys) {
        if (environment[key] != this.environment[key]) {
          return false;
        }
      }
    }
    return true;
  }
}

class _FakeProcess implements Process {
  _FakeProcess(
    this._exitCode,
    Duration duration,
    VoidCallback onRun,
    this.pid,
    this._stderr,
    this.stdin,
    this._stdout,
  ) : exitCode = Future<void>.delayed(duration).then((void value) {
        if (onRun != null) {
          onRun();
        }
        return _exitCode;
      }),
      stderr = Stream<List<int>>.value(utf8.encode(_stderr)),
      stdout = Stream<List<int>>.value(utf8.encode(_stdout));

  final int _exitCode;

  @override
  final Future<int> exitCode;

  @override
  final int pid;

  final String _stderr;

  @override
  final Stream<List<int>> stderr;

  @override
  final IOSink stdin;

  @override
  final Stream<List<int>> stdout;

  final String _stdout;

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    assert(false, 'Process.kill() should not be used directly in flutter_tools.');
    return false;
  }
}

abstract class FakeProcessManager implements ProcessManager {
  /// A fake [ProcessManager] which responds to all commands as if they had run
  /// instantaneously with an exit code of 0 and no output.
  factory FakeProcessManager.any() = _FakeAnyProcessManager;

  /// A fake [ProcessManager] which responds to particular commands with
  /// particular results.
  ///
  /// On creation, pass in a list of [FakeCommand] objects. When the
  /// [ProcessManager] methods such as [start] are invoked, the next
  /// [FakeCommand] must match (otherwise the test fails); its settings are used
  /// to simulate the result of running that command.
  ///
  /// If no command is found, then one is implied which immediately returns exit
  /// code 0 with no output.
  ///
  /// There is no logic to ensure that all the listed commands are run. Use
  /// [FakeCommand.onRun] to set a flag, or specify a sentinel command as your
  /// last command and verify its execution is successful, to ensure that all
  /// the specified commands are actually called.
  factory FakeProcessManager.list(List<FakeCommand> commands) = _SequenceProcessManager;

  FakeProcessManager._();

  @protected
  FakeCommand findCommand(List<String> command, String workingDirectory, Map<String, String> environment);

  int _pid = 9999;

  _FakeProcess _runCommand(List<String> command, String workingDirectory, Map<String, String> environment) {
    _pid += 1;
    final FakeCommand fakeCommand = findCommand(command, workingDirectory, environment);
    return _FakeProcess(
      fakeCommand.exitCode,
      fakeCommand.duration,
      fakeCommand.onRun,
      _pid,
      fakeCommand.stdout,
      null, // stdin
      fakeCommand.stderr,
    );
  }

  @override
  Future<Process> start(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true, // ignored
    bool runInShell = false, // ignored
    ProcessStartMode mode = ProcessStartMode.normal, // ignored
  }) async => _runCommand(command.cast<String>(), workingDirectory, environment);

  @override
  Future<ProcessResult> run(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true, // ignored
    bool runInShell = false, // ignored
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  }) async {
    final _FakeProcess process = _runCommand(command.cast<String>(), workingDirectory, environment);
    await process.exitCode;
    return ProcessResult(
      process.pid,
      process._exitCode,
      stdoutEncoding == null ? process.stdout : await stdoutEncoding.decodeStream(process.stdout),
      stderrEncoding == null ? process.stderr : await stderrEncoding.decodeStream(process.stderr),
    );
  }

  @override
  ProcessResult runSync(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true, // ignored
    bool runInShell = false, // ignored
    Encoding stdoutEncoding = systemEncoding, // actual encoder is ignored
    Encoding stderrEncoding = systemEncoding, // actual encoder is ignored
  }) {
    final _FakeProcess process = _runCommand(command.cast<String>(), workingDirectory, environment);
    return ProcessResult(
      process.pid,
      process._exitCode,
      stdoutEncoding == null ? utf8.encode(process._stdout) : process._stdout,
      stderrEncoding == null ? utf8.encode(process._stderr) : process._stderr,
    );
  }

  @override
  bool canRun(dynamic executable, {String workingDirectory}) => true;

  @override
  bool killPid(int pid, [io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    assert(false, 'ProcessManager.killPid() should not be used directly in flutter_tools.');
    return false;
  }
}

class _FakeAnyProcessManager extends FakeProcessManager {
  _FakeAnyProcessManager() : super._();

  @override
  FakeCommand findCommand(List<String> command, String workingDirectory, Map<String, String> environment) {
    return FakeCommand(
      command: command,
      workingDirectory: workingDirectory,
      environment: environment,
      duration: const Duration(),
      exitCode: 0,
      stdout: '',
      stderr: '',
    );
  }
}

class _SequenceProcessManager extends FakeProcessManager {
  _SequenceProcessManager(this._commands) : super._();

  final List<FakeCommand> _commands;

  @override
  FakeCommand findCommand(List<String> command, String workingDirectory, Map<String, String> environment) {
    expect(_commands, isNotEmpty,
      reason: 'ProcessManager was told to execute $command (in $workingDirectory) '
              'but the FakeProcessManager.list expected no more processes.'
    );
    expect(_commands.first._matches(command, workingDirectory, environment), isTrue,
      reason: 'ProcessManager was told to execute $command '
              '(in $workingDirectory, with environment $environment) '
              'but the next process that was expected was ${_commands.first.command} '
              '(in ${_commands.first.workingDirectory}, with environment ${_commands.first.environment})}.'
    );
    return _commands.removeAt(0);
  }
}
