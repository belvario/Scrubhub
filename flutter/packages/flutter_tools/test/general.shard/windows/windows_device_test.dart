// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/windows/application_package.dart';
import 'package:flutter_tools/src/windows/windows_device.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group(WindowsDevice, () {
    final WindowsDevice device = WindowsDevice();
    final MockPlatform notWindows = MockPlatform();

    when(notWindows.isWindows).thenReturn(false);
    when(notWindows.environment).thenReturn(const <String, String>{});

    testUsingContext('defaults', () async {
      final PrebuiltWindowsApp windowsApp = PrebuiltWindowsApp(executable: 'foo');
      expect(await device.targetPlatform, TargetPlatform.windows_x64);
      expect(device.name, 'Windows');
      expect(await device.installApp(windowsApp), true);
      expect(await device.uninstallApp(windowsApp), true);
      expect(await device.isLatestBuildInstalled(windowsApp), true);
      expect(await device.isAppInstalled(windowsApp), true);
      expect(device.category, Category.desktop);
    });

    testUsingContext('No devices listed if platform unsupported', () async {
      expect(await WindowsDevices().devices, <Device>[]);
    }, overrides: <Type, Generator>{
      Platform: () => notWindows,
    });

    testUsingContext('isSupportedForProject is true with editable host app', () async {
      fs.file('pubspec.yaml').createSync();
      fs.file('.packages').createSync();
      fs.directory('windows').createSync();
      final FlutterProject flutterProject = FlutterProject.current();

      expect(WindowsDevice().isSupportedForProject(flutterProject), true);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('isSupportedForProject is false with no host app', () async {
      fs.file('pubspec.yaml').createSync();
      fs.file('.packages').createSync();
      final FlutterProject flutterProject = FlutterProject.current();

      expect(WindowsDevice().isSupportedForProject(flutterProject), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('executablePathForDevice uses the correct package executable', () async {
      final MockWindowsApp mockApp = MockWindowsApp();
      const String debugPath = 'debug/executable';
      const String profilePath = 'profile/executable';
      const String releasePath = 'release/executable';
      when(mockApp.executable(BuildMode.debug)).thenReturn(debugPath);
      when(mockApp.executable(BuildMode.profile)).thenReturn(profilePath);
      when(mockApp.executable(BuildMode.release)).thenReturn(releasePath);

      expect(WindowsDevice().executablePathForDevice(mockApp, BuildMode.debug), debugPath);
      expect(WindowsDevice().executablePathForDevice(mockApp, BuildMode.profile), profilePath);
      expect(WindowsDevice().executablePathForDevice(mockApp, BuildMode.release), releasePath);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });
  });
}

class MockPlatform extends Mock implements Platform {}

class MockWindowsApp extends Mock implements WindowsApp {}
