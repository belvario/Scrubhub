// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;

import '../android/android_sdk.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../flutter_manifest.dart';
import '../globals.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import 'android_sdk.dart';
import 'gradle_errors.dart';
import 'gradle_utils.dart';

/// The directory where the APK artifact is generated.
@visibleForTesting
Directory getApkDirectory(FlutterProject project) {
  return project.isModule
    ? project.android.buildDirectory
        .childDirectory('host')
        .childDirectory('outputs')
        .childDirectory('apk')
    : project.android.buildDirectory
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('apk');
}

/// The directory where the app bundle artifact is generated.
@visibleForTesting
Directory getBundleDirectory(FlutterProject project) {
  return project.isModule
    ? project.android.buildDirectory
        .childDirectory('host')
        .childDirectory('outputs')
        .childDirectory('bundle')
    : project.android.buildDirectory
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('bundle');
}

/// The directory where the repo is generated.
/// Only applicable to AARs.
Directory getRepoDirectory(Directory buildDirectory) {
  return buildDirectory
    .childDirectory('outputs')
    .childDirectory('repo');
}

/// Returns the name of Gradle task that starts with [prefix].
String _taskFor(String prefix, BuildInfo buildInfo) {
  final String buildType = camelCase(buildInfo.modeName);
  final String productFlavor = buildInfo.flavor ?? '';
  return '$prefix${toTitleCase(productFlavor)}${toTitleCase(buildType)}';
}

/// Returns the task to build an APK.
@visibleForTesting
String getAssembleTaskFor(BuildInfo buildInfo) {
  return _taskFor('assemble', buildInfo);
}

/// Returns the task to build an AAB.
@visibleForTesting
String getBundleTaskFor(BuildInfo buildInfo) {
  return _taskFor('bundle', buildInfo);
}

/// Returns the task to build an AAR.
@visibleForTesting
String getAarTaskFor(BuildInfo buildInfo) {
  return _taskFor('assembleAar', buildInfo);
}

/// Returns the output APK file names for a given [AndroidBuildInfo].
///
/// For example, when [splitPerAbi] is true, multiple APKs are created.
Iterable<String> _apkFilesFor(AndroidBuildInfo androidBuildInfo) {
  final String buildType = camelCase(androidBuildInfo.buildInfo.modeName);
  final String productFlavor = androidBuildInfo.buildInfo.flavor ?? '';
  final String flavorString = productFlavor.isEmpty ? '' : '-$productFlavor';
  if (androidBuildInfo.splitPerAbi) {
    return androidBuildInfo.targetArchs.map<String>((AndroidArch arch) {
      final String abi = getNameForAndroidArch(arch);
      return 'app$flavorString-$abi-$buildType.apk';
    });
  }
  return <String>['app$flavorString-$buildType.apk'];
}

/// Returns true if the current version of the Gradle plugin is supported.
bool _isSupportedVersion(AndroidProject project) {
  final File plugin = project.hostAppGradleRoot.childFile(
      fs.path.join('buildSrc', 'src', 'main', 'groovy', 'FlutterPlugin.groovy'));
  if (plugin.existsSync()) {
    return false;
  }
  final File appGradle = project.hostAppGradleRoot.childFile(
      fs.path.join('app', 'build.gradle'));
  if (!appGradle.existsSync()) {
    return false;
  }
  for (String line in appGradle.readAsLinesSync()) {
    if (line.contains(RegExp(r'apply from: .*/flutter.gradle')) ||
        line.contains("def flutterPluginVersion = 'managed'")) {
      return true;
    }
  }
  return false;
}

/// Returns the apk file created by [buildGradleProject]
Future<File> getGradleAppOut(AndroidProject androidProject) async {
  if (!_isSupportedVersion(androidProject)) {
    _exitWithUnsupportedProjectMessage();
  }
  return getApkDirectory(androidProject.parent).childFile('app.apk');
}

/// Runs `gradlew dependencies`, ensuring that dependencies are resolved and
/// potentially downloaded.
Future<void> checkGradleDependencies() async {
  final Status progress = logger.startProgress(
    'Ensuring gradle dependencies are up to date...',
    timeout: timeoutConfiguration.slowOperation,
  );
  final FlutterProject flutterProject = FlutterProject.current();
  await processUtils.run(<String>[
      gradleUtils.getExecutable(flutterProject),
      'dependencies',
    ],
    throwOnError: true,
    workingDirectory: flutterProject.android.hostAppGradleRoot.path,
    environment: gradleEnvironment,
  );
  androidSdk.reinitialize();
  progress.stop();
}

/// Tries to create `settings_aar.gradle` in an app project by removing the subprojects
/// from the existing `settings.gradle` file. This operation will fail if the existing
/// `settings.gradle` file has local edits.
@visibleForTesting
void createSettingsAarGradle(Directory androidDirectory) {
  final File newSettingsFile = androidDirectory.childFile('settings_aar.gradle');
  if (newSettingsFile.existsSync()) {
    return;
  }
  final File currentSettingsFile = androidDirectory.childFile('settings.gradle');
  if (!currentSettingsFile.existsSync()) {
    return;
  }
  final String currentFileContent = currentSettingsFile.readAsStringSync();

  final String newSettingsRelativeFile = fs.path.relative(newSettingsFile.path);
  final Status status = logger.startProgress('✏️  Creating `$newSettingsRelativeFile`...',
      timeout: timeoutConfiguration.fastOperation);

  final String flutterRoot = fs.path.absolute(Cache.flutterRoot);
  final File deprecatedFile = fs.file(fs.path.join(flutterRoot, 'packages','flutter_tools',
      'gradle', 'deprecated_settings.gradle'));
  assert(deprecatedFile.existsSync());
  final String settingsAarContent = fs.file(fs.path.join(flutterRoot, 'packages','flutter_tools',
      'gradle', 'settings_aar.gradle.tmpl')).readAsStringSync();

  // Get the `settings.gradle` content variants that should be patched.
  final List<String> existingVariants = deprecatedFile.readAsStringSync().split(';EOF');
  existingVariants.add(settingsAarContent);

  bool exactMatch = false;
  for (String fileContentVariant in existingVariants) {
    if (currentFileContent.trim() == fileContentVariant.trim()) {
      exactMatch = true;
      break;
    }
  }
  if (!exactMatch) {
    status.cancel();
    printStatus('$warningMark Flutter tried to create the file `$newSettingsRelativeFile`, but failed.');
    // Print how to manually update the file.
    printStatus(fs.file(fs.path.join(flutterRoot, 'packages','flutter_tools',
        'gradle', 'manual_migration_settings.gradle.md')).readAsStringSync());
    throwToolExit('Please create the file and run this command again.');
  }
  // Copy the new file.
  newSettingsFile.writeAsStringSync(settingsAarContent);
  status.stop();
  printStatus('$successMark `$newSettingsRelativeFile` created successfully.');
}

/// Builds an app.
///
/// * [project] is typically [FlutterProject.current()].
/// * [androidBuildInfo] is the build configuration.
/// * [target] is the target dart entry point. Typically, `lib/main.dart`.
/// * If [isBuildingBundle] is `true`, then the output artifact is an `*.aab`,
///   otherwise the output artifact is an `*.apk`.
/// * The plugins are built as AARs if [shouldBuildPluginAsAar] is `true`. This isn't set by default
///   because it makes the build slower proportional to the number of plugins.
/// * [retries] is the max number of build retries in case one of the [GradleHandledError] handler
///   returns [GradleBuildStatus.retry] or [GradleBuildStatus.retryWithAarPlugins].
Future<void> buildGradleApp({
  @required FlutterProject project,
  @required AndroidBuildInfo androidBuildInfo,
  @required String target,
  @required bool isBuildingBundle,
  @required List<GradleHandledError> localGradleErrors,
  bool shouldBuildPluginAsAar = false,
  int retries = 1,
}) async {
  if (androidSdk == null) {
    exitWithNoSdkMessage();
  }
  if (!project.android.isUsingGradle) {
    _exitWithProjectNotUsingGradleMessage();
  }
  if (!_isSupportedVersion(project.android)) {
    _exitWithUnsupportedProjectMessage();
  }
  final Directory buildDirectory = project.android.buildDirectory;

  final bool usesAndroidX = isAppUsingAndroidX(project.android.hostAppGradleRoot);
  if (usesAndroidX) {
    BuildEvent('app-using-android-x').send();
  } else if (!usesAndroidX) {
    BuildEvent('app-not-using-android-x').send();
    printStatus('$warningMark Your app isn\'t using AndroidX.', emphasis: true);
    printStatus(
      'To avoid potential build failures, you can quickly migrate your app '
      'by following the steps on https://goo.gl/CP92wY.',
      indent: 4,
    );
  }
  // The default Gradle script reads the version name and number
  // from the local.properties file.
  updateLocalProperties(project: project, buildInfo: androidBuildInfo.buildInfo);

  if (shouldBuildPluginAsAar) {
    // Create a settings.gradle that doesn't import the plugins as subprojects.
    createSettingsAarGradle(project.android.hostAppGradleRoot);
    await buildPluginsAsAar(
      project,
      androidBuildInfo,
      buildDirectory: buildDirectory.childDirectory('app'),
    );
  }

  final BuildInfo buildInfo = androidBuildInfo.buildInfo;
  final String assembleTask = isBuildingBundle
    ? getBundleTaskFor(buildInfo)
    : getAssembleTaskFor(buildInfo);

  final Status status = logger.startProgress(
    'Running Gradle task \'$assembleTask\'...',
    timeout: timeoutConfiguration.slowOperation,
    multilineOutput: true,
  );

  final List<String> command = <String>[
    gradleUtils.getExecutable(project),
  ];
  if (logger.isVerbose) {
    command.add('-Pverbose=true');
  } else {
    command.add('-q');
  }
  if (artifacts is LocalEngineArtifacts) {
    final LocalEngineArtifacts localEngineArtifacts = artifacts as LocalEngineArtifacts;
    final Directory localEngineRepo = _getLocalEngineRepo(
      engineOutPath: localEngineArtifacts.engineOutPath,
      androidBuildInfo: androidBuildInfo,
    );
    printTrace(
      'Using local engine: ${localEngineArtifacts.engineOutPath}\n'
      'Local Maven repo: ${localEngineRepo.path}'
    );
    command.add('-Plocal-engine-repo=${localEngineRepo.path}');
    command.add('-Plocal-engine-build-mode=${buildInfo.modeName}');
    command.add('-Plocal-engine-out=${localEngineArtifacts.engineOutPath}');
  }
  if (target != null) {
    command.add('-Ptarget=$target');
  }
  assert(buildInfo.trackWidgetCreation != null);
  command.add('-Ptrack-widget-creation=${buildInfo.trackWidgetCreation}');

  if (buildInfo.extraFrontEndOptions != null) {
    command.add('-Pextra-front-end-options=${buildInfo.extraFrontEndOptions}');
  }
  if (buildInfo.extraGenSnapshotOptions != null) {
    command.add('-Pextra-gen-snapshot-options=${buildInfo.extraGenSnapshotOptions}');
  }
  if (buildInfo.fileSystemRoots != null && buildInfo.fileSystemRoots.isNotEmpty) {
    command.add('-Pfilesystem-roots=${buildInfo.fileSystemRoots.join('|')}');
  }
  if (buildInfo.fileSystemScheme != null) {
    command.add('-Pfilesystem-scheme=${buildInfo.fileSystemScheme}');
  }
  if (androidBuildInfo.splitPerAbi) {
    command.add('-Psplit-per-abi=true');
  }
  if (androidBuildInfo.shrink) {
    command.add('-Pshrink=true');
  }
  if (androidBuildInfo.targetArchs.isNotEmpty) {
    final String targetPlatforms = androidBuildInfo
      .targetArchs
      .map(getPlatformNameForAndroidArch).join(',');
    command.add('-Ptarget-platform=$targetPlatforms');
  }
  if (shouldBuildPluginAsAar) {
    // Pass a system flag instead of a project flag, so this flag can be
    // read from include_flutter.groovy.
    command.add('-Dbuild-plugins-as-aars=true');
    // Don't use settings.gradle from the current project since it includes the plugins as subprojects.
    command.add('--settings-file=settings_aar.gradle');
  }
  command.add(assembleTask);

  GradleHandledError detectedGradleError;
  String detectedGradleErrorLine;
  String consumeLog(String line) {
    // This message was removed from first-party plugins,
    // but older plugin versions still display this message.
    if (androidXPluginWarningRegex.hasMatch(line)) {
      // Don't pipe.
      return null;
    }
    if (detectedGradleError != null) {
      // Pipe stdout/stderr from Gradle.
      return line;
    }
    for (final GradleHandledError gradleError in localGradleErrors) {
      if (gradleError.test(line)) {
        detectedGradleErrorLine = line;
        detectedGradleError = gradleError;
        // The first error match wins.
        break;
      }
    }
    // Pipe stdout/stderr from Gradle.
    return line;
  }

  final Stopwatch sw = Stopwatch()..start();
  int exitCode = 1;
  try {
    exitCode = await processUtils.stream(
      command,
      workingDirectory: project.android.hostAppGradleRoot.path,
      allowReentrantFlutter: true,
      environment: gradleEnvironment,
      mapFunction: consumeLog,
    );
  } on ProcessException catch(exception) {
    consumeLog(exception.toString());
    // Rethrow the exception if the error isn't handled by any of the
    // `localGradleErrors`.
    if (detectedGradleError == null) {
      rethrow;
    }
  } finally {
    status.stop();
  }

  flutterUsage.sendTiming('build', 'gradle', sw.elapsed);

  if (exitCode != 0) {
    if (detectedGradleError == null) {
      BuildEvent('gradle-unkown-failure').send();
      throwToolExit(
        'Gradle task $assembleTask failed with exit code $exitCode',
        exitCode: exitCode,
      );
    } else {
      final GradleBuildStatus status = await detectedGradleError.handler(
        line: detectedGradleErrorLine,
        project: project,
        usesAndroidX: usesAndroidX,
        shouldBuildPluginAsAar: shouldBuildPluginAsAar,
      );

      if (retries >= 1) {
        final String successEventLabel = 'gradle-${detectedGradleError.eventLabel}-success';
        switch (status) {
          case GradleBuildStatus.retry:
            await buildGradleApp(
              project: project,
              androidBuildInfo: androidBuildInfo,
              target: target,
              isBuildingBundle: isBuildingBundle,
              localGradleErrors: localGradleErrors,
              shouldBuildPluginAsAar: shouldBuildPluginAsAar,
              retries: retries - 1,
            );
            BuildEvent(successEventLabel).send();
            return;
          case GradleBuildStatus.retryWithAarPlugins:
            await buildGradleApp(
              project: project,
              androidBuildInfo: androidBuildInfo,
              target: target,
              isBuildingBundle: isBuildingBundle,
              localGradleErrors: localGradleErrors,
              shouldBuildPluginAsAar: true,
              retries: retries - 1,
            );
            BuildEvent(successEventLabel).send();
            return;
          case GradleBuildStatus.exit:
            // noop.
        }
      }
      BuildEvent('gradle-${detectedGradleError.eventLabel}-failure').send();
      throwToolExit(
        'Gradle task $assembleTask failed with exit code $exitCode',
        exitCode: exitCode,
      );
    }
  }

  if (isBuildingBundle) {
    final File bundleFile = findBundleFile(project, buildInfo);
    final String appSize = (buildInfo.mode == BuildMode.debug)
      ? '' // Don't display the size when building a debug variant.
      : ' (${getSizeAsMB(bundleFile.lengthSync())})';

    printStatus(
      '$successMark Built ${fs.path.relative(bundleFile.path)}$appSize.',
      color: TerminalColor.green,
    );
    return;
  }
  // Gradle produced an APK.
  final Iterable<File> apkFiles = findApkFiles(project, androidBuildInfo);
  final Directory apkDirectory = getApkDirectory(project);
  // Copy the first APK to app.apk, so `flutter run` can find it.
  // TODO(egarciad): Handle multiple APKs.
  apkFiles.first.copySync(apkDirectory.childFile('app.apk').path);
  printTrace('calculateSha: $apkDirectory/app.apk');

  final File apkShaFile = apkDirectory.childFile('app.apk.sha1');
  apkShaFile.writeAsStringSync(_calculateSha(apkFiles.first));

  for (File apkFile in apkFiles) {
    final String appSize = (buildInfo.mode == BuildMode.debug)
      ? '' // Don't display the size when building a debug variant.
      : ' (${getSizeAsMB(apkFile.lengthSync())})';
    printStatus(
      '$successMark Built ${fs.path.relative(apkFile.path)}$appSize.',
      color: TerminalColor.green,
    );
  }
}

/// Builds AAR and POM files.
///
/// * [project] is typically [FlutterProject.current()].
/// * [androidBuildInfo] is the build configuration.
/// * [outputDir] is the destination of the artifacts,
Future<void> buildGradleAar({
  @required FlutterProject project,
  @required AndroidBuildInfo androidBuildInfo,
  @required String target,
  @required Directory outputDirectory,
}) async {
  assert(project != null);
  assert(target != null);
  assert(androidBuildInfo != null);
  assert(outputDirectory != null);

  if (androidSdk == null) {
    exitWithNoSdkMessage();
  }
  final FlutterManifest manifest = project.manifest;
  if (!manifest.isModule && !manifest.isPlugin) {
    throwToolExit('AARs can only be built for plugin or module projects.');
  }

  final String aarTask = getAarTaskFor(androidBuildInfo.buildInfo);
  final Status status = logger.startProgress(
    'Running Gradle task \'$aarTask\'...',
    timeout: timeoutConfiguration.slowOperation,
    multilineOutput: true,
  );

  final String flutterRoot = fs.path.absolute(Cache.flutterRoot);
  final String initScript = fs.path.join(
    flutterRoot,
    'packages',
    'flutter_tools',
    'gradle',
    'aar_init_script.gradle',
  );
  final List<String> command = <String>[
    gradleUtils.getExecutable(project),
    '-I=$initScript',
    '-Pflutter-root=$flutterRoot',
    '-Poutput-dir=${outputDirectory.path}',
    '-Pis-plugin=${manifest.isPlugin}',
  ];

  if (target != null && target.isNotEmpty) {
    command.add('-Ptarget=$target');
  }

  if (androidBuildInfo.targetArchs.isNotEmpty) {
    final String targetPlatforms = androidBuildInfo.targetArchs
        .map(getPlatformNameForAndroidArch).join(',');
    command.add('-Ptarget-platform=$targetPlatforms');
  }
  if (artifacts is LocalEngineArtifacts) {
    final LocalEngineArtifacts localEngineArtifacts = artifacts as LocalEngineArtifacts;
    final Directory localEngineRepo = _getLocalEngineRepo(
      engineOutPath: localEngineArtifacts.engineOutPath,
      androidBuildInfo: androidBuildInfo,
    );
    printTrace(
      'Using local engine: ${localEngineArtifacts.engineOutPath}\n'
      'Local Maven repo: ${localEngineRepo.path}'
    );
    command.add('-Plocal-engine-repo=${localEngineRepo.path}');
    command.add('-Plocal-engine-build-mode=${androidBuildInfo.buildInfo.modeName}');
    command.add('-Plocal-engine-out=${localEngineArtifacts.engineOutPath}');
  }

  command.add(aarTask);

  final Stopwatch sw = Stopwatch()..start();
  RunResult result;
  try {
    result = await processUtils.run(
      command,
      workingDirectory: project.android.hostAppGradleRoot.path,
      allowReentrantFlutter: true,
      environment: gradleEnvironment,
    );
  } finally {
    status.stop();
  }
  flutterUsage.sendTiming('build', 'gradle-aar', sw.elapsed);

  if (result.exitCode != 0) {
    printStatus(result.stdout, wrap: false);
    printError(result.stderr, wrap: false);
    throwToolExit(
      'Gradle task $aarTask failed with exit code $exitCode.',
      exitCode: exitCode,
    );
  }
  final Directory repoDirectory = getRepoDirectory(outputDirectory);
  if (!repoDirectory.existsSync()) {
    printStatus(result.stdout, wrap: false);
    printError(result.stderr, wrap: false);
    throwToolExit(
      'Gradle task $aarTask failed to produce $repoDirectory.',
      exitCode: exitCode,
    );
  }
  printStatus(
    '$successMark Built ${fs.path.relative(repoDirectory.path)}.',
    color: TerminalColor.green,
  );
}

/// Prints how to consume the AAR from a host app.
void printHowToConsumeAar({
  @required Set<String> buildModes,
  @required String androidPackage,
  @required Directory repoDirectory,
}) {
  assert(buildModes != null && buildModes.isNotEmpty);
  assert(androidPackage != null);
  assert(repoDirectory != null);

  printStatus('''

${terminal.bolden('Consuming the Module')}
  1. Open ${fs.path.join('<host>', 'app', 'build.gradle')}
  2. Ensure you have the repositories configured, otherwise add them:

      repositories {
        maven {
            url '${repoDirectory.path}'
        }
        maven {
            url 'http://download.flutter.io'
        }
      }

  3. Make the host app depend on the Flutter module:

    dependencies {''');

  for (String buildMode in buildModes) {
    printStatus('''
      ${buildMode}Implementation '$androidPackage:flutter_$buildMode:1.0''');
  }

printStatus('''
    }
''');

  if (buildModes.contains('profile')) {
    printStatus('''

  4. Add the `profile` build type:

    android {
      buildTypes {
        profile {
          initWith debug
        }
      }
    }
''');
  }

printStatus('To learn more, visit https://flutter.dev/go/build-aar''');
}

String _hex(List<int> bytes) {
  final StringBuffer result = StringBuffer();
  for (int part in bytes) {
    result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  }
  return result.toString();
}

String _calculateSha(File file) {
  final Stopwatch sw = Stopwatch()..start();
  final List<int> bytes = file.readAsBytesSync();
  printTrace('calculateSha: reading file took ${sw.elapsedMilliseconds}us');
  flutterUsage.sendTiming('build', 'apk-sha-read', sw.elapsed);
  sw.reset();
  final String sha = _hex(sha1.convert(bytes).bytes);
  printTrace('calculateSha: computing sha took ${sw.elapsedMilliseconds}us');
  flutterUsage.sendTiming('build', 'apk-sha-calc', sw.elapsed);
  return sha;
}

void _exitWithUnsupportedProjectMessage() {
  BuildEvent('unsupported-project', eventError: 'gradle-plugin').send();
  throwToolExit(
    '$warningMark Your app is using an unsupported Gradle project. '
    'To fix this problem, create a new project by running `flutter create -t app <app-directory>` '
    'and then move the dart code, assets and pubspec.yaml to the new project.',
  );
}

void _exitWithProjectNotUsingGradleMessage() {
  BuildEvent('unsupported-project', eventError: 'app-not-using-gradle').send();
  throwToolExit(
    '$warningMark The build process for Android has changed, and the '
    'current project configuration is no longer valid. Please consult\n\n'
    'https://github.com/flutter/flutter/wiki/Upgrading-Flutter-projects-to-build-with-gradle\n\n'
    'for details on how to upgrade the project.'
  );
}

/// Returns [true] if the current app uses AndroidX.
// TODO(egarciad): https://github.com/flutter/flutter/issues/40800
// Remove `FlutterManifest.usesAndroidX` and provide a unified `AndroidProject.usesAndroidX`.
bool isAppUsingAndroidX(Directory androidDirectory) {
  final File properties = androidDirectory.childFile('gradle.properties');
  if (!properties.existsSync()) {
    return false;
  }
  return properties.readAsStringSync().contains('android.useAndroidX=true');
}

/// Builds the plugins as AARs.
@visibleForTesting
Future<void> buildPluginsAsAar(
  FlutterProject flutterProject,
  AndroidBuildInfo androidBuildInfo, {
  Directory buildDirectory,
}) async {
  final File flutterPluginFile = flutterProject.flutterPluginsFile;
  if (!flutterPluginFile.existsSync()) {
    return;
  }
  final List<String> plugins = flutterPluginFile.readAsStringSync().split('\n');
  for (String plugin in plugins) {
    final List<String> pluginParts = plugin.split('=');
    if (pluginParts.length != 2) {
      continue;
    }
    final Directory pluginDirectory = fs.directory(pluginParts.last);
    assert(pluginDirectory.existsSync());

    final String pluginName = pluginParts.first;
    logger.printStatus('Building plugin $pluginName...');
    try {
      await buildGradleAar(
        project: FlutterProject.fromDirectory(pluginDirectory),
        androidBuildInfo: const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release, // Plugins are built as release.
            null, // Plugins don't define flavors.
          ),
        ),
        target: '',
        outputDirectory: buildDirectory,
      );
    } on ToolExit {
      // Log the entire plugin entry in `.flutter-plugins` since it
      // includes the plugin name and the version.
      BuildEvent('gradle-plugin-aar-failure', eventError: plugin).send();
      throwToolExit('The plugin $pluginName could not be built due to the issue above.');
    }
  }
}

/// Returns the APK files for a given [FlutterProject] and [AndroidBuildInfo].
@visibleForTesting
Iterable<File> findApkFiles(
  FlutterProject project,
  AndroidBuildInfo androidBuildInfo,
) {
  final Iterable<String> apkFileNames = _apkFilesFor(androidBuildInfo);
  final Directory apkDirectory = getApkDirectory(project);
  final Iterable<File> apks = apkFileNames.expand<File>((String apkFileName) {
    File apkFile = apkDirectory.childFile(apkFileName);
    if (apkFile.existsSync()) {
      return <File>[apkFile];
    }
    final BuildInfo buildInfo = androidBuildInfo.buildInfo;
    final String modeName = camelCase(buildInfo.modeName);
    apkFile = apkDirectory
      .childDirectory(modeName)
      .childFile(apkFileName);
    if (apkFile.existsSync()) {
      return <File>[apkFile];
    }
    if (buildInfo.flavor != null) {
      // Android Studio Gradle plugin v3 adds flavor to path.
      apkFile = apkDirectory
        .childDirectory(buildInfo.flavor)
        .childDirectory(modeName)
        .childFile(apkFileName);
      if (apkFile.existsSync()) {
        return <File>[apkFile];
      }
    }
    return const <File>[];
  });
  if (apks.isEmpty) {
    _exitWithExpectedFileNotFound(
      project: project,
      fileExtension: '.apk',
    );
  }
  return apks;
}

@visibleForTesting
File findBundleFile(FlutterProject project, BuildInfo buildInfo) {
  final List<File> fileCandidates = <File>[
    getBundleDirectory(project)
      .childDirectory(camelCase(buildInfo.modeName))
      .childFile('app.aab'),
    getBundleDirectory(project)
      .childDirectory(camelCase(buildInfo.modeName))
      .childFile('app-${buildInfo.modeName}.aab'),
  ];
  if (buildInfo.flavor != null) {
    // The Android Gradle plugin 3.0.0 adds the flavor name to the path.
    // For example: In release mode, if the flavor name is `foo_bar`, then
    // the directory name is `foo_barRelease`.
    fileCandidates.add(
      getBundleDirectory(project)
        .childDirectory('${buildInfo.flavor}${camelCase('_' + buildInfo.modeName)}')
        .childFile('app.aab'));

    // The Android Gradle plugin 3.5.0 adds the flavor name to file name.
    // For example: In release mode, if the flavor name is `foo_bar`, then
    // the file name name is `app-foo_bar-release.aab`.
    fileCandidates.add(
      getBundleDirectory(project)
        .childDirectory('${buildInfo.flavor}${camelCase('_' + buildInfo.modeName)}')
        .childFile('app-${buildInfo.flavor}-${buildInfo.modeName}.aab'));
  }
  for (final File bundleFile in fileCandidates) {
    if (bundleFile.existsSync()) {
      return bundleFile;
    }
  }
  _exitWithExpectedFileNotFound(
    project: project,
    fileExtension: '.aab',
  );
  return null;
}

/// Throws a [ToolExit] exception and logs the event.
void _exitWithExpectedFileNotFound({
  @required FlutterProject project,
  @required String fileExtension,
}) {
  assert(project != null);
  assert(fileExtension != null);

  final String androidGradlePluginVersion =
      getGradleVersionForAndroidPlugin(project.android.hostAppGradleRoot);
  BuildEvent('gradle-expected-file-not-found',
    settings:
      'androidGradlePluginVersion: $androidGradlePluginVersion, '
      'fileExtension: $fileExtension'
    ).send();
  throwToolExit(
    'Gradle build failed to produce an $fileExtension file. '
    'It\'s likely that this file was generated under ${project.android.buildDirectory.path}, '
    'but the tool couldn\'t find it.'
  );
}

void _createSymlink(String targetPath, String linkPath) {
  final File targetFile = fs.file(targetPath);
  if (!targetFile.existsSync()) {
    throwToolExit('The file $targetPath wasn\'t found in the local engine out directory.');
  }
  final File linkFile = fs.file(linkPath);
  final Link symlink = linkFile.parent.childLink(linkFile.basename);
  try {
    symlink.createSync(targetPath, recursive: true);
  } on FileSystemException catch (exception) {
    throwToolExit(
      'Failed to create the symlink $linkPath->$targetPath: $exception'
    );
  }
}

String _getLocalArtifactVersion(String pomPath) {
  final File pomFile = fs.file(pomPath);
  if (!pomFile.existsSync()) {
    throwToolExit('The file $pomPath wasn\'t found in the local engine out directory.');
  }
  xml.XmlDocument document;
  try {
    document = xml.parse(pomFile.readAsStringSync());
  } on xml.XmlParserException {
    throwToolExit(
      'Error parsing $pomPath. Please ensure that this is a valid XML document.'
    );
  } on FileSystemException {
    throwToolExit(
      'Error reading $pomPath. Please ensure that you have read permission to this'
      'file and try again.');
  }
  final Iterable<xml.XmlElement> project = document.findElements('project');
  assert(project.isNotEmpty);
  for (xml.XmlElement versionElement in document.findAllElements('version')) {
    if (versionElement.parent == project.first) {
      return versionElement.text;
    }
  }
  throwToolExit('Error while parsing the <version> element from $pomPath');
  return null;
}

/// Returns the local Maven repository for a local engine build.
/// For example, if the engine is built locally at <home>/engine/src/out/android_release_unopt
/// This method generates symlinks in the temp directory to the engine artifacts
/// following the convention specified on https://maven.apache.org/pom.html#Repositories
Directory _getLocalEngineRepo({
  @required String engineOutPath,
  @required AndroidBuildInfo androidBuildInfo,
}) {
  assert(engineOutPath != null);
  assert(androidBuildInfo != null);

  final String abi = getEnumName(androidBuildInfo.targetArchs.first);
  final Directory localEngineRepo = fs.systemTempDirectory
    .createTempSync('flutter_tool_local_engine_repo.');

  // Remove the local engine repo before the tool exits.
  addShutdownHook(
    () => localEngineRepo.deleteSync(recursive: true),
    ShutdownStage.CLEANUP,
  );

  final String buildMode = androidBuildInfo.buildInfo.modeName;
  final String artifactVersion = _getLocalArtifactVersion(
    fs.path.join(
      engineOutPath,
      'flutter_embedding_$buildMode.pom',
    )
  );
  for (String artifact in const <String>['pom', 'jar']) {
    // The Android embedding artifacts.
    _createSymlink(
      fs.path.join(
        engineOutPath,
        'flutter_embedding_$buildMode.$artifact',
      ),
      fs.path.join(
        localEngineRepo.path,
        'io',
        'flutter',
        'flutter_embedding_$buildMode',
        artifactVersion,
        'flutter_embedding_$buildMode-$artifactVersion.$artifact',
      ),
    );
    // The engine artifacts (libflutter.so).
    _createSymlink(
      fs.path.join(
        engineOutPath,
        '${abi}_$buildMode.$artifact',
      ),
      fs.path.join(
        localEngineRepo.path,
        'io',
        'flutter',
        '${abi}_$buildMode',
        artifactVersion,
        '${abi}_$buildMode-$artifactVersion.$artifact',
      ),
    );
  }
  return localEngineRepo;
}
