// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../globals.dart';
import '../project.dart';

abstract class FuchsiaApp extends ApplicationPackage {
  FuchsiaApp({@required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new [FuchsiaApp] from a fuchsia sub project.
  factory FuchsiaApp.fromFuchsiaProject(FuchsiaProject project) {
    if (!project.existsSync()) {
      // If the project doesn't exist at all the current hint to run flutter
      // create is accurate.
      return null;
    }
    return BuildableFuchsiaApp(
      project: project,
    );
  }

  /// Creates a new [FuchsiaApp] from an existing .far archive.
  ///
  /// [applicationBinary] is the path to the .far archive.
  factory FuchsiaApp.fromPrebuiltApp(FileSystemEntity applicationBinary) {
    final FileSystemEntityType entityType = fs.typeSync(applicationBinary.path);
    if (entityType != FileSystemEntityType.file) {
      printError('File "${applicationBinary.path}" does not exist or is not a .far file. Use far archive.');
      return null;
    }
    return PrebuiltFuchsiaApp(
      farArchive: applicationBinary.path,
    );
  }

  @override
  String get displayName => id;

  /// The location of the 'far' archive containing the built app.
  File farArchive(BuildMode buildMode);
}

class PrebuiltFuchsiaApp extends FuchsiaApp {
  PrebuiltFuchsiaApp({
    @required String farArchive,
  }) : _farArchive = farArchive,
       // TODO(zra): Extract the archive and extract the id from meta/package.
       super(projectBundleId: farArchive);

  final String _farArchive;

  @override
  File farArchive(BuildMode buildMode) => fs.file(_farArchive);

  @override
  String get name => _farArchive;
}

class BuildableFuchsiaApp extends FuchsiaApp {
  BuildableFuchsiaApp({this.project}) :
      super(projectBundleId: project.project.manifest.appName);

  final FuchsiaProject project;

  @override
  File farArchive(BuildMode buildMode) {
    // TODO(zra): Distinguish among build modes.
    final String outDir = getFuchsiaBuildDirectory();
    final String pkgDir = fs.path.join(outDir, 'pkg');
    final String appName = project.project.manifest.appName;
    return fs.file(fs.path.join(pkgDir, '$appName-0.far'));
  }

  @override
  String get name => project.project.manifest.appName;
}
