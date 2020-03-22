// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/platform.dart';
import '../base/process.dart';
import '../device.dart';
import '../emulator.dart';
import '../globals.dart';
import '../macos/xcode.dart';
import 'ios_workflow.dart';
import 'simulators.dart';

class IOSEmulators extends EmulatorDiscovery {
  @override
  bool get supportsPlatform => platform.isMacOS;

  @override
  bool get canListAnything => iosWorkflow.canListEmulators;

  @override
  Future<List<Emulator>> get emulators async => getEmulators();
}

class IOSEmulator extends Emulator {
  IOSEmulator(String id) : super(id, true);

  @override
  String get name => 'iOS Simulator';

  @override
  String get manufacturer => 'Apple';

  @override
  Category get category => Category.mobile;

  @override
  PlatformType get platformType => PlatformType.ios;

  @override
  Future<void> launch() async {
    Future<bool> launchSimulator(List<String> additionalArgs) async {
      final List<String> args = <String>[
        'open',
        ...additionalArgs,
        '-a',
        xcode.getSimulatorPath(),
      ];

      final RunResult launchResult = await processUtils.run(args);
      if (launchResult.exitCode != 0) {
        printError('$launchResult');
        return false;
      }
      return true;
    }

    // First run with `-n` to force a device to boot if there isn't already one
    if (!await launchSimulator(<String>['-n'])) {
      return;
    }

    // Run again to force it to Foreground (using -n doesn't force existing
    // devices to the foreground)
    await launchSimulator(<String>[]);
  }
}

/// Return the list of iOS Simulators (there can only be zero or one).
List<IOSEmulator> getEmulators() {
  final String simulatorPath = xcode.getSimulatorPath();
  if (simulatorPath == null) {
    return <IOSEmulator>[];
  }

  return <IOSEmulator>[IOSEmulator(iosSimulatorId)];
}
