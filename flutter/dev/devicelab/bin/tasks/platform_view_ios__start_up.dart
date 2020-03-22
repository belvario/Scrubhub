// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/perf_tests.dart';
import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(() async {
    final String platformViewDirectoryPath = '${flutterDirectory.path}/examples/platform_view';
    final Directory platformViewDirectory = dir(
      platformViewDirectoryPath
    );
    await inDirectory(platformViewDirectory, () async {
      await flutter('pub', options: <String>['get']);
    });
    final Directory iosDirectory = dir(
      '$platformViewDirectoryPath/ios',
    );
    await inDirectory(iosDirectory, () async {
      await exec('pod', <String>['install']);
    });

    final TaskFunction taskFunction = createPlatformViewStartupTest();
    return await taskFunction();
  });
}
