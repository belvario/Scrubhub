// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../cache.dart';
import '../features.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../version.dart';

class PrecacheCommand extends FlutterCommand {
  PrecacheCommand({bool verboseHelp = false}) {
    argParser.addFlag('all-platforms', abbr: 'a', negatable: false,
        help: 'Precache artifacts for all host platforms.');
    argParser.addFlag('force', abbr: 'f', negatable: false,
        help: 'Force downloading of artifacts.');
    argParser.addFlag('android', negatable: true, defaultsTo: true,
        help: 'Precache artifacts for Android development.',
        hide: verboseHelp);
    argParser.addFlag('android_gen_snapshot', negatable: true, defaultsTo: true,
        help: 'Precache gen_snapshot for Android development.',
        hide: !verboseHelp);
    argParser.addFlag('android_maven', negatable: true, defaultsTo: true,
        help: 'Precache Gradle dependencies for Android development.',
        hide: !verboseHelp);
    argParser.addFlag('android_internal_build', negatable: true, defaultsTo: false,
        help: 'Precache dependencies for internal Android development.',
        hide: !verboseHelp);
    argParser.addFlag('ios', negatable: true, defaultsTo: true,
        help: 'Precache artifacts for iOS development.');
    argParser.addFlag('web', negatable: true, defaultsTo: false,
        help: 'Precache artifacts for web development.');
    argParser.addFlag('linux', negatable: true, defaultsTo: false,
        help: 'Precache artifacts for Linux desktop development.');
    argParser.addFlag('windows', negatable: true, defaultsTo: false,
        help: 'Precache artifacts for Windows desktop development.');
    argParser.addFlag('macos', negatable: true, defaultsTo: false,
        help: 'Precache artifacts for macOS desktop development.');
    argParser.addFlag('fuchsia', negatable: true, defaultsTo: false,
        help: 'Precache artifacts for Fuchsia development.');
    argParser.addFlag('universal', negatable: true, defaultsTo: true,
        help: 'Precache artifacts required for any development platform.');
    argParser.addFlag('flutter_runner', negatable: true, defaultsTo: false,
        help: 'Precache the flutter runner artifacts.', hide: true);
    argParser.addFlag('use-unsigned-mac-binaries', negatable: true, defaultsTo: false,
        help: 'Precache the unsigned mac binaries when available.', hide: true);
  }

  @override
  final String name = 'precache';

  @override
  final String description = 'Populates the Flutter tool\'s cache of binary artifacts.';

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (boolArg('all-platforms')) {
      cache.includeAllPlatforms = true;
    }
    if (boolArg('use-unsigned-mac-binaries')) {
      cache.useUnsignedMacBinaries = true;
    }
    final Set<DevelopmentArtifact> requiredArtifacts = <DevelopmentArtifact>{};
    for (DevelopmentArtifact artifact in DevelopmentArtifact.values) {
      // Don't include unstable artifacts on stable branches.
      if (!FlutterVersion.instance.isMaster && artifact.unstable) {
        continue;
      }
      if (artifact.feature != null && !featureFlags.isEnabled(artifact.feature)) {
        continue;
      }
      if (boolArg(artifact.name)) {
        requiredArtifacts.add(artifact);
      }
      // The `android` flag expands to android_gen_snapshot, android_maven, android_internal_build.
      if (artifact.name.startsWith('android_') && boolArg('android')) {
        requiredArtifacts.add(artifact);
      }
    }
    final bool forceUpdate = boolArg('force');
    if (forceUpdate || !cache.isUpToDate()) {
      await cache.updateAll(requiredArtifacts);
    } else {
      printStatus('Already up-to-date.');
    }
    return null;
  }
}
