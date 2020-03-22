// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/commands/clean.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  void test1() {
    final MemoryFileSystem fs = MemoryFileSystem();
    final MockXcodeProjectInterpreter mockXcodeProjectInterpreter = MockXcodeProjectInterpreter();
    final MockXcode mockXcode = MockXcode();

    final Directory currentDirectory = fs.currentDirectory;
    final Directory buildDirectory = currentDirectory.childDirectory('build');
    buildDirectory.createSync(recursive: true);

    final FlutterProject projectUnderTest = FlutterProject.fromDirectory(currentDirectory);
    projectUnderTest.ios.xcodeWorkspace.createSync(recursive: true);
    projectUnderTest.macos.xcodeWorkspace.createSync(recursive: true);

    projectUnderTest.dartTool.createSync(recursive: true);
    projectUnderTest.android.ephemeralDirectory.createSync(recursive: true);
    projectUnderTest.ios.ephemeralDirectory.createSync(recursive: true);
    projectUnderTest.linux.ephemeralDirectory.createSync(recursive: true);
    projectUnderTest.macos.ephemeralDirectory.createSync(recursive: true);
    projectUnderTest.windows.ephemeralDirectory.createSync(recursive: true);

    testUsingContext('$CleanCommand removes build and .dart_tool and ephemeral directories, cleans Xcode', () async {
      when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(true);
      await CleanCommand().runCommand();

      expect(buildDirectory.existsSync(), isFalse);
      expect(projectUnderTest.dartTool.existsSync(), isFalse);
      expect(projectUnderTest.android.ephemeralDirectory.existsSync(), isFalse);
      expect(projectUnderTest.ios.ephemeralDirectory.existsSync(), isFalse);
      expect(projectUnderTest.linux.ephemeralDirectory.existsSync(), isFalse);
      expect(projectUnderTest.macos.ephemeralDirectory.existsSync(), isFalse);
      expect(projectUnderTest.windows.ephemeralDirectory.existsSync(), isFalse);

      verify(xcodeProjectInterpreter.cleanWorkspace(any, 'Runner')).called(2);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
      Xcode: () => mockXcode,
      XcodeProjectInterpreter: () => mockXcodeProjectInterpreter,
    });
  }

  void test2() {
    final MockXcode mockXcode = MockXcode();
    final MockPlatform windowsPlatform = MockPlatform();
    testUsingContext('$CleanCommand prints a helpful error message on Windows', () async {
      when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(false);
      when(windowsPlatform.isWindows).thenReturn(true);

      final MockFile mockFile = MockFile();
      when(mockFile.existsSync()).thenReturn(true);

      when(mockFile.deleteSync(recursive: true)).thenThrow(const FileSystemException('Deletion failed'));
      final CleanCommand command = CleanCommand();
      command.deleteFile(mockFile);
      expect(testLogger.errorText, contains('A program may still be using a file'));
      verify(mockFile.deleteSync(recursive: true)).called(1);
    }, overrides: <Type, Generator>{
      Platform: () => windowsPlatform,
      Logger: () => BufferLogger(),
      Xcode: () => mockXcode,
    });

    testUsingContext('$CleanCommand handles missing permissions;', () async {
      when(mockXcode.isInstalledAndMeetsVersionCheck).thenReturn(false);

      final MockFile mockFile = MockFile();
      when(mockFile.existsSync()).thenThrow(const FileSystemException('OS error: Access Denied'));
      when(mockFile.path).thenReturn('foo.dart');

      final CleanCommand command = CleanCommand();
      command.deleteFile(mockFile);
      expect(testLogger.errorText, contains('Cannot clean foo.dart'));
      verifyNever(mockFile.deleteSync(recursive: true));
    }, overrides: <Type, Generator>{
      Platform: () => windowsPlatform,
      Logger: () => BufferLogger(),
      Xcode: () => mockXcode,
    });
  }

  test1();
  test2();
}

class MockFile extends Mock implements File {}
class MockPlatform extends Mock implements Platform {}
class MockXcode extends Mock implements Xcode {}

class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {
  @override
  Future<XcodeProjectInfo> getInfo(String projectPath, {String projectFilename}) async {
    return XcodeProjectInfo(null, null, <String>['Runner']);
  }
}
