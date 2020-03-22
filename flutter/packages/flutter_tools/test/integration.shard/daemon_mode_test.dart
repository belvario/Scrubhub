// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  test('device.getDevices', () async {
    final Directory tempDir = createResolvedTempDirectorySync('daemon_mode_test.');

    final BasicProject _project = BasicProject();
    await _project.setUpIn(tempDir);

    final String flutterBin = fs.path.join(getFlutterRoot(), 'bin', 'flutter');

    const ProcessManager processManager = LocalProcessManager();
    final Process process = await processManager.start(
      <String>[flutterBin, '--show-test-device', 'daemon'],
      workingDirectory: tempDir.path,
    );

    final StreamController<String> stdout = StreamController<String>.broadcast();
    transformToLines(process.stdout).listen((String line) => stdout.add(line));
    final Stream<Map<String, dynamic>> stream = stdout
      .stream
      .map<Map<String, dynamic>>(parseFlutterResponse)
      .where((Map<String, dynamic> value) => value != null);

    Map<String, dynamic> response = await stream.first;
    expect(response['event'], 'daemon.connected');

    // start listening for devices
    process.stdin.writeln('[${jsonEncode(<String, dynamic>{
      'id': 1,
      'method': 'device.enable',
    })}]');
    response = await stream.first;
    expect(response['id'], 1);
    expect(response['error'], isNull);

    // [{"event":"device.added","params":{"id":"flutter-tester","name":
    //   "Flutter test device","platform":"flutter-tester","emulator":false}}]
    response = await stream.first;
    expect(response['event'], 'device.added');

    // get the list of all devices
    process.stdin.writeln('[${jsonEncode(<String, dynamic>{
      'id': 2,
      'method': 'device.getDevices',
    })}]');
    // Skip other device.added events that may fire (desktop/web devices).
    response = await stream.firstWhere((Map<String, dynamic> response) => response['event'] != 'device.added');
    expect(response['id'], 2);
    expect(response['error'], isNull);

    final dynamic result = response['result'];
    expect(result, isList);
    expect(result, isNotEmpty);

    tryToDelete(tempDir);
    process.kill();
  });
}
