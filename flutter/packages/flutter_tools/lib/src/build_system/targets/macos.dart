// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/build.dart';
import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/process.dart';
import '../../base/process_manager.dart';
import '../../build_info.dart';
import '../../globals.dart';
import '../../macos/xcode.dart';
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'dart.dart';

const String _kOutputPrefix = '{OUTPUT_DIR}/FlutterMacOS.framework';

/// Copy the macOS framework to the correct copy dir by invoking 'cp -R'.
///
/// This class is abstract to share logic between the three concrete
/// implementations. The shelling out is done to avoid complications with
/// preserving special files (e.g., symbolic links) in the framework structure.
///
/// Removes any previous version of the framework that already exists in the
/// target directory.
///
/// The real implementations are:
///   * [DebugUnpackMacOS]
///   * [ProfileUnpackMacOS]
///   * [ReleaseUnpackMacOS]
///
// TODO(jonahwilliams): remove shell out.
// TODO(jonahwilliams): the subtypes are required to specify the different
// input dependencies as a current limitation of the build system planning.
// This should be resolved after https://github.com/flutter/flutter/issues/38937.
abstract class UnpackMacOS extends Target {
  const UnpackMacOS();

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/macos.dart'),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('$_kOutputPrefix/FlutterMacOS'),
    // Headers
    Source.pattern('$_kOutputPrefix/Headers/FlutterDartProject.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterEngine.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterViewController.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterBinaryMessenger.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterChannels.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterCodecs.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterMacros.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterPluginMacOS.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterPluginRegistrarMacOS.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterMacOS.h'),
    // Modules
    Source.pattern('$_kOutputPrefix/Modules/module.modulemap'),
    // Resources
    Source.pattern('$_kOutputPrefix/Resources/icudtl.dat'),
    Source.pattern('$_kOutputPrefix/Resources/Info.plist'),
    // Ignore Versions folder for now
  ];

  @override
  List<Target> get dependencies => <Target>[];

  @override
  Future<void> build(Environment environment) async {
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'unpack_macos');
    }
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final String basePath = artifacts.getArtifactPath(Artifact.flutterMacOSFramework, mode: buildMode);
    final Directory targetDirectory = environment
      .outputDir
      .childDirectory('FlutterMacOS.framework');
    if (targetDirectory.existsSync()) {
      targetDirectory.deleteSync(recursive: true);
    }
    final ProcessResult result = await processManager
        .run(<String>['cp', '-R', basePath, targetDirectory.path]);
    if (result.exitCode != 0) {
      throw Exception(
        'Failed to copy framework (exit ${result.exitCode}:\n'
        '${result.stdout}\n---\n${result.stderr}',
      );
    }
  }
}

/// Unpack the release prebuilt engine framework.
class ReleaseUnpackMacOS extends UnpackMacOS {
  const ReleaseUnpackMacOS();

  @override
  String get name => 'release_unpack_macos';

  @override
  List<Source> get inputs => <Source>[
    ...super.inputs,
    const Source.artifact(Artifact.flutterMacOSFramework, mode: BuildMode.release),
  ];
}

/// Unpack the profile prebuilt engine framework.
class ProfileUnpackMacOS extends UnpackMacOS {
  const ProfileUnpackMacOS();

  @override
  String get name => 'profile_unpack_macos';

  @override
  List<Source> get inputs => <Source>[
    ...super.inputs,
    const Source.artifact(Artifact.flutterMacOSFramework, mode: BuildMode.profile),
  ];
}

/// Unpack the debug prebuilt engine framework.
class DebugUnpackMacOS extends UnpackMacOS {
  const DebugUnpackMacOS();

  @override
  String get name => 'debug_unpack_macos';

  @override
  List<Source> get inputs => <Source>[
    ...super.inputs,
    const Source.artifact(Artifact.flutterMacOSFramework, mode: BuildMode.debug),
  ];
}

/// Create an App.framework for debug macOS targets.
///
/// This framework needs to exist for the Xcode project to link/bundle,
/// but it isn't actually executed. To generate something valid, we compile a trivial
/// constant.
class DebugMacOSFramework extends Target {
  const DebugMacOSFramework();

  @override
  String get name => 'debug_macos_framework';

  @override
  Future<void> build(Environment environment) async {
    final File outputFile = fs.file(fs.path.join(
        environment.buildDir.path, 'App.framework', 'App'));
    outputFile.createSync(recursive: true);
    final File debugApp = environment.buildDir.childFile('debug_app.cc')
        ..writeAsStringSync(r'''
static const int Moo = 88;
''');
    final RunResult result = await xcode.clang(<String>[
      '-x',
      'c',
      debugApp.path,
      '-arch', 'x86_64',
      '-dynamiclib',
      '-Xlinker', '-rpath', '-Xlinker', '@executable_path/Frameworks',
      '-Xlinker', '-rpath', '-Xlinker', '@loader_path/Frameworks',
      '-install_name', '@rpath/App.framework/App',
      '-o', outputFile.path,
    ]);
    if (result.exitCode != 0) {
      throw Exception('Failed to compile debug App.framework');
    }
  }

  @override
  List<Target> get dependencies => const <Target>[];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/macos.dart'),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/App.framework/App'),
  ];
}

class CompileMacOSFramework extends Target {
  const CompileMacOSFramework();

  @override
  String get name => 'compile_macos_framework';

  @override
  Future<void> build(Environment environment) async {
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'compile_macos_framework');
    }
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    if (buildMode == BuildMode.debug) {
      throw Exception('precompiled macOS framework only supported in release/profile builds.');
    }
    final int result = await AOTSnapshotter(reportTimings: false).build(
      bitcode: false,
      buildMode: buildMode,
      mainPath: environment.buildDir.childFile('app.dill').path,
      outputPath: environment.buildDir.path,
      platform: TargetPlatform.darwin_x64,
      darwinArch: DarwinArch.x86_64,
      packagesPath: environment.projectDir.childFile('.packages').path,
    );
    if (result != 0) {
      throw Exception('gen shapshot failed.');
    }
  }

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/app.dill'),
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/macos.dart'),
    Source.artifact(Artifact.genSnapshot, mode: BuildMode.release, platform: TargetPlatform.darwin_x64),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/App.framework/App'),
  ];
}

/// Bundle the flutter assets into the App.framework.
///
/// In debug mode, also include the app.dill and precompiled runtimes.
///
/// See https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPFrameworks/Concepts/FrameworkAnatomy.html
/// for more information on Framework structure.
abstract class MacOSBundleFlutterAssets extends Target {
  const MacOSBundleFlutterAssets();

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/App.framework/App'),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{OUTPUT_DIR}/App.framework/Versions/A/App'),
    Source.pattern('{OUTPUT_DIR}/App.framework/Versions/A/Resources/Info.plist'),
  ];

  @override
  List<String> get depfiles => const <String>[
    'flutter_assets.d',
  ];

  @override
  Future<void> build(Environment environment) async {
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'compile_macos_framework');
    }
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final Directory frameworkRootDirectory = environment
        .outputDir
        .childDirectory('App.framework');
    final Directory outputDirectory = frameworkRootDirectory
        .childDirectory('Versions')
        .childDirectory('A')
        ..createSync(recursive: true);

    // Copy App into framework directory.
    environment.buildDir
      .childDirectory('App.framework')
      .childFile('App')
      .copySync(outputDirectory.childFile('App').path);

    // Copy assets into asset directory.
    final Directory assetDirectory = outputDirectory
      .childDirectory('Resources')
      .childDirectory('flutter_assets');
    assetDirectory.createSync(recursive: true);
    final Depfile depfile = await copyAssets(environment, assetDirectory);
    depfile.writeToFile(environment.buildDir.childFile('flutter_assets.d'));

    // Copy Info.plist template.
    assetDirectory.parent.childFile('Info.plist')
      ..createSync()
      ..writeAsStringSync(r'''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>App</string>
	<key>CFBundleIdentifier</key>
	<string>io.flutter.flutter.app</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>App</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1.0</string>
</dict>
</plist>

''');
    if (buildMode == BuildMode.debug) {
      // Copy dill file.
      try {
        final File sourceFile = environment.buildDir.childFile('app.dill');
        sourceFile.copySync(assetDirectory.childFile('kernel_blob.bin').path);
      } catch (err) {
        throw Exception('Failed to copy app.dill: $err');
      }
      // Copy precompiled runtimes.
      try {
        final String vmSnapshotData = artifacts.getArtifactPath(Artifact.vmSnapshotData,
            platform: TargetPlatform.darwin_x64, mode: BuildMode.debug);
        final String isolateSnapshotData = artifacts.getArtifactPath(Artifact.isolateSnapshotData,
            platform: TargetPlatform.darwin_x64, mode: BuildMode.debug);
        fs.file(vmSnapshotData).copySync(
            assetDirectory.childFile('vm_snapshot_data').path);
        fs.file(isolateSnapshotData).copySync(
            assetDirectory.childFile('isolate_snapshot_data').path);
      } catch (err) {
        throw Exception('Failed to copy precompiled runtimes: $err');
      }
    }
    // Create symlink to current version. These must be relative, from the
    // framework root for Resources/App and from the versions root for
    // Current.
    try {
      final Link currentVersion = outputDirectory.parent
          .childLink('Current');
      if (!currentVersion.existsSync()) {
        final String linkPath = fs.path.relative(outputDirectory.path,
            from: outputDirectory.parent.path);
        currentVersion.createSync(linkPath);
      }
      // Create symlink to current resources.
      final Link currentResources = frameworkRootDirectory
          .childLink('Resources');
      if (!currentResources.existsSync()) {
        final String linkPath = fs.path.relative(fs.path.join(currentVersion.path, 'Resources'),
            from: frameworkRootDirectory.path);
        currentResources.createSync(linkPath);
      }
      // Create symlink to current binary.
      final Link currentFramework = frameworkRootDirectory
          .childLink('App');
      if (!currentFramework.existsSync()) {
        final String linkPath = fs.path.relative(fs.path.join(currentVersion.path, 'App'),
            from: frameworkRootDirectory.path);
        currentFramework.createSync(linkPath);
      }
    } on FileSystemException {
      throw Exception('Failed to create symlinks for framework. try removing '
        'the "${environment.outputDir.path}" directory and rerunning');
    }
  }
}

/// Bundle the debug flutter assets into the App.framework.
class DebugMacOSBundleFlutterAssets extends MacOSBundleFlutterAssets {
  const DebugMacOSBundleFlutterAssets();

  @override
  String get name => 'debug_macos_bundle_flutter_assets';

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
    DebugMacOSFramework(),
    DebugUnpackMacOS(),
  ];

  @override
  List<Source> get inputs => <Source>[
    ...super.inputs,
    const Source.pattern('{BUILD_DIR}/app.dill'),
    const Source.artifact(Artifact.isolateSnapshotData, platform: TargetPlatform.darwin_x64, mode: BuildMode.debug),
    const Source.artifact(Artifact.vmSnapshotData, platform: TargetPlatform.darwin_x64, mode: BuildMode.debug),
  ];

  @override
  List<Source> get outputs => <Source>[
    ...super.outputs,
    const Source.pattern('{OUTPUT_DIR}/App.framework/Versions/A/Resources/flutter_assets/kernel_blob.bin'),
    const Source.pattern('{OUTPUT_DIR}/App.framework/Versions/A/Resources/flutter_assets/vm_snapshot_data'),
    const Source.pattern('{OUTPUT_DIR}/App.framework/Versions/A/Resources/flutter_assets/isolate_snapshot_data'),
  ];
}

/// Bundle the profile flutter assets into the App.framework.
class ProfileMacOSBundleFlutterAssets extends MacOSBundleFlutterAssets {
  const ProfileMacOSBundleFlutterAssets();

  @override
  String get name => 'profile_macos_bundle_flutter_assets';

  @override
  List<Target> get dependencies => const <Target>[
    CompileMacOSFramework(),
    ProfileUnpackMacOS(),
  ];
}


/// Bundle the release flutter assets into the App.framework.
class ReleaseMacOSBundleFlutterAssets extends MacOSBundleFlutterAssets {
  const ReleaseMacOSBundleFlutterAssets();

  @override
  String get name => 'release_macos_bundle_flutter_assets';

  @override
  List<Target> get dependencies => const <Target>[
    CompileMacOSFramework(),
    ReleaseUnpackMacOS(),
  ];
}
