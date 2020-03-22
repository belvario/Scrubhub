// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../build_info.dart';
import '../features.dart';
import '../project.dart';
import '../runner/flutter_command.dart'
    show DevelopmentArtifact, FlutterCommandResult;
import '../web/compile.dart';
import 'build.dart';

class BuildWebCommand extends BuildSubCommand {
  BuildWebCommand() {
    usesTargetOption();
    usesPubOption();
    addBuildModeFlags(excludeDebug: true);
    usesDartDefines();
    argParser.addFlag('web-initialize-platform',
        defaultsTo: true,
        negatable: true,
        hide: true,
        help: 'Whether to automatically invoke webOnlyInitializePlatform.',
    );
  }

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async =>
      const <DevelopmentArtifact>{
        DevelopmentArtifact.universal,
        DevelopmentArtifact.web,
      };

  @override
  final String name = 'web';

  @override
  bool get hidden => !featureFlags.isWebEnabled;

  @override
  final String description = 'build a web application bundle.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!featureFlags.isWebEnabled) {
      throwToolExit('"build web" is not currently supported.');
    }
    final FlutterProject flutterProject = FlutterProject.current();
    final String target = stringArg('target');
    final BuildInfo buildInfo = getBuildInfo();
    if (buildInfo.isDebug) {
      throwToolExit('debug builds cannot be built directly for the web. Try using "flutter run"');
    }
    await buildWeb(
      flutterProject,
      target,
      buildInfo,
      boolArg('web-initialize-platform'),
      dartDefines,
    );
    return null;
  }
}
