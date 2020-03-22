// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../globals.dart';
import 'build_system.dart';
import 'exceptions.dart';

/// A set of source files.
abstract class ResolvedFiles {
  /// Whether any of the sources we evaluated contained a missing depfile.
  ///
  /// If so, the build system needs to rerun the visitor after executing the
  /// build to ensure all hashes are up to date.
  bool get containsNewDepfile;

  /// The resolved source files.
  List<File> get sources;
}

/// Collects sources for a [Target] into a single list of [FileSystemEntities].
class SourceVisitor implements ResolvedFiles {
  /// Create a new [SourceVisitor] from an [Environment].
  SourceVisitor(this.environment, [this.inputs = true]);

  /// The current environment.
  final Environment environment;

  /// Whether we are visiting inputs or outputs.
  ///
  /// Defaults to `true`.
  final bool inputs;

  @override
  final List<File> sources = <File>[];

  @override
  bool get containsNewDepfile => _containsNewDepfile;
  bool _containsNewDepfile = false;

  /// Visit a depfile which contains both input and output files.
  ///
  /// If the file is missing, this visitor is marked as [containsNewDepfile].
  /// This is used by the [Node] class to tell the [BuildSystem] to
  /// defer hash computation until after executing the target.
  // depfile logic adopted from https://github.com/flutter/flutter/blob/7065e4330624a5a216c8ffbace0a462617dc1bf5/dev/devicelab/lib/framework/apk_utils.dart#L390
  void visitDepfile(String name) {
    final File depfile = environment.buildDir.childFile(name);
    if (!depfile.existsSync()) {
      _containsNewDepfile = true;
      return;
    }
    final String contents = depfile.readAsStringSync();
    final List<String> colonSeparated = contents.split(': ');
    if (colonSeparated.length != 2) {
      printError('Invalid depfile: ${depfile.path}');
      return;
    }
    if (inputs) {
      sources.addAll(_processList(colonSeparated[1].trim()));
    } else {
      sources.addAll(_processList(colonSeparated[0].trim()));
    }
  }

  final RegExp _separatorExpr = RegExp(r'([^\\]) ');
  final RegExp _escapeExpr = RegExp(r'\\(.)');

  Iterable<File> _processList(String rawText) {
    return rawText
    // Put every file on right-hand side on the separate line
        .replaceAllMapped(_separatorExpr, (Match match) => '${match.group(1)}\n')
        .split('\n')
    // Expand escape sequences, so that '\ ', for example,ß becomes ' '
        .map<String>((String path) => path.replaceAllMapped(_escapeExpr, (Match match) => match.group(1)).trim())
        .where((String path) => path.isNotEmpty)
        .toSet()
        .map((String path) => fs.file(path));
  }

  /// Visit a [Source] which contains a file URL.
  ///
  /// The URL may include constants defined in an [Environment]. If
  /// [optional] is true, the file is not required to exist. In this case, it
  /// is never resolved as an input.
  void visitPattern(String pattern, bool optional) {
    // perform substitution of the environmental values and then
    // of the local values.
    final List<String> segments = <String>[];
    final List<String> rawParts = pattern.split('/');
    final bool hasWildcard = rawParts.last.contains('*');
    String wildcardFile;
    if (hasWildcard) {
      wildcardFile = rawParts.removeLast();
    }
    // If the pattern does not start with an env variable, then we have nothing
    // to resolve it to, error out.
    switch (rawParts.first) {
      case Environment.kProjectDirectory:
        segments.addAll(
            fs.path.split(environment.projectDir.resolveSymbolicLinksSync()));
        break;
      case Environment.kBuildDirectory:
        segments.addAll(fs.path.split(
            environment.buildDir.resolveSymbolicLinksSync()));
        break;
      case Environment.kCacheDirectory:
        segments.addAll(
            fs.path.split(environment.cacheDir.resolveSymbolicLinksSync()));
        break;
      case Environment.kFlutterRootDirectory:
        // flutter root will not contain a symbolic link.
        segments.addAll(
            fs.path.split(environment.flutterRootDir.absolute.path));
        break;
      case Environment.kOutputDirectory:
        segments.addAll(
            fs.path.split(environment.outputDir.resolveSymbolicLinksSync()));
        break;
      default:
        throw InvalidPatternException(pattern);
    }
    rawParts.skip(1).forEach(segments.add);
    final String filePath = fs.path.joinAll(segments);
    if (!hasWildcard) {
      if (optional && !fs.isFileSync(filePath)) {
        return;
      }
      sources.add(fs.file(fs.path.normalize(filePath)));
      return;
    }
    // Perform a simple match by splitting the wildcard containing file one
    // the `*`. For example, for `/*.dart`, we get [.dart]. We then check
    // that part of the file matches. If there are values before and after
    // the `*` we need to check that both match without overlapping. For
    // example, `foo_*_.dart`. We want to match `foo_b_.dart` but not
    // `foo_.dart`. To do so, we first subtract the first section from the
    // string if the first segment matches.
    final List<String> wildcardSegments = wildcardFile.split('*');
    if (wildcardSegments.length > 2) {
      throw InvalidPatternException(pattern);
    }
    if (!fs.directory(filePath).existsSync()) {
      throw Exception('$filePath does not exist!');
    }
    for (FileSystemEntity entity in fs.directory(filePath).listSync()) {
      final String filename = fs.path.basename(entity.path);
      if (wildcardSegments.isEmpty) {
        sources.add(fs.file(entity.absolute));
      } else if (wildcardSegments.length == 1) {
        if (filename.startsWith(wildcardSegments[0]) ||
            filename.endsWith(wildcardSegments[0])) {
          sources.add(fs.file(entity.absolute));
        }
      } else if (filename.startsWith(wildcardSegments[0])) {
        if (filename.substring(wildcardSegments[0].length).endsWith(wildcardSegments[1])) {
          sources.add(fs.file(entity.absolute));
        }
      }
    }
  }

  /// Visit a [Source] which is defined by an [Artifact] from the flutter cache.
  ///
  /// If the [Artifact] points to a directory then all child files are included.
  void visitArtifact(Artifact artifact, TargetPlatform platform, BuildMode mode) {
    final String path = artifacts.getArtifactPath(artifact, platform: platform, mode: mode);
    if (fs.isDirectorySync(path)) {
      sources.addAll(<File>[
        for (FileSystemEntity entity in fs.directory(path).listSync(recursive: true))
          if (entity is File)
            entity,
      ]);
    } else {
      sources.add(fs.file(path));
    }
  }
}

/// A description of an input or output of a [Target].
abstract class Source {
  /// This source is a file URL which contains some references to magic
  /// environment variables.
  const factory Source.pattern(String pattern, { bool optional }) = _PatternSource;
  /// The source is provided by an [Artifact].
  ///
  /// If [artifact] points to a directory then all child files are included.
  const factory Source.artifact(Artifact artifact, {TargetPlatform platform, BuildMode mode}) = _ArtifactSource;

  /// Visit the particular source type.
  void accept(SourceVisitor visitor);

  /// Whether the output source provided can be known before executing the rule.
  ///
  /// This does not apply to inputs, which are always explicit and must be
  /// evaluated before the build.
  ///
  /// For example, [Source.pattern] and [Source.version] are not implicit
  /// provided they do not use any wildcards.
  bool get implicit;
}

class _PatternSource implements Source {
  const _PatternSource(this.value, { this.optional = false });

  final String value;
  final bool optional;

  @override
  void accept(SourceVisitor visitor) => visitor.visitPattern(value, optional);

  @override
  bool get implicit => value.contains('*');
}

class _ArtifactSource implements Source {
  const _ArtifactSource(this.artifact, { this.platform, this.mode });

  final Artifact artifact;
  final TargetPlatform platform;
  final BuildMode mode;

  @override
  void accept(SourceVisitor visitor) => visitor.visitArtifact(artifact, platform, mode);

  @override
  bool get implicit => false;
}
