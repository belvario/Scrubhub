// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/android_builder.dart';
import '../base/common.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../cache.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildAarCommand extends BuildSubCommand {
  BuildAarCommand() {
    argParser
      ..addFlag(
        'debug',
        defaultsTo: true,
        help: 'Build a debug version of the current project.',
      )
      ..addFlag(
        'profile',
        defaultsTo: true,
        help: 'Build a version of the current project specialized for performance profiling.',
      )
      ..addFlag(
        'release',
        defaultsTo: true,
        help: 'Build a release version of the current project.',
      );
    usesFlavorOption();
    usesPubOption();
    argParser
      ..addMultiOption(
        'target-platform',
        splitCommas: true,
        defaultsTo: <String>['android-arm', 'android-arm64', 'android-x64'],
        allowed: <String>['android-arm', 'android-arm64', 'android-x86', 'android-x64'],
        help: 'The target platform for which the project is compiled.',
      )
      ..addOption(
        'output-dir',
        help: 'The absolute path to the directory where the repository is generated.'
              'By default, this is \'<current-directory>android/build\'. ',
      );
  }

  @override
  final String name = 'aar';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.androidGenSnapshot,
    DevelopmentArtifact.universal,
  };

  @override
  Future<Map<CustomDimensions, String>> get usageValues async {
    final Map<CustomDimensions, String> usage = <CustomDimensions, String>{};
    final FlutterProject flutterProject = _getProject();
    if (flutterProject == null) {
      return usage;
    }
    if (flutterProject.manifest.isModule) {
      usage[CustomDimensions.commandBuildAarProjectType] = 'module';
    } else if (flutterProject.manifest.isPlugin) {
      usage[CustomDimensions.commandBuildAarProjectType] = 'plugin';
    } else {
      usage[CustomDimensions.commandBuildAarProjectType] = 'app';
    }
    usage[CustomDimensions.commandBuildAarTargetPlatform] = stringsArg('target-platform').join(',');
    return usage;
  }

  @override
  final String description = 'Build a repository containing an AAR and a POM file.\n\n'
      'By default, AARs are built for `release`, `debug` and `profile`.\n'
      'The POM file is used to include the dependencies that the AAR was compiled against.\n'
      'To learn more about how to use these artifacts, see '
      'https://flutter.dev/go/build-aar';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Set<AndroidBuildInfo> androidBuildInfo = <AndroidBuildInfo>{};
    final Iterable<AndroidArch> targetArchitectures = stringsArg('target-platform')
      .map<AndroidArch>(getAndroidArchForName);

    for (String buildMode in const <String>['debug', 'profile', 'release']) {
      if (boolArg(buildMode)) {
        androidBuildInfo.add(
          AndroidBuildInfo(
            BuildInfo(BuildMode.fromName(buildMode), stringArg('flavor')),
            targetArchs: targetArchitectures,
          )
        );
      }
    }
    if (androidBuildInfo.isEmpty) {
      throwToolExit('Please specify a build mode and try again.');
    }
    await androidBuilder.buildAar(
      project: _getProject(),
      target: '', // Not needed because this command only builds Android's code.
      androidBuildInfo: androidBuildInfo,
      outputDirectoryPath: stringArg('output-dir'),
    );
    return null;
  }

  /// Returns the [FlutterProject] which is determined from the remaining command-line
  /// argument if any or the current working directory.
  FlutterProject _getProject() {
    if (argResults.rest.isEmpty) {
      return FlutterProject.current();
    }
    return FlutterProject.fromPath(findProjectRoot(argResults.rest.first));
  }
}
