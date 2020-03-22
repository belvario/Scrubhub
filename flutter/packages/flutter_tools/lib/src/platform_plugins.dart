// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import 'base/common.dart';
import 'base/file_system.dart';

/// Marker interface for all platform specific plugin config impls.
abstract class PluginPlatform {
  const PluginPlatform();

  Map<String, dynamic> toMap();
}

/// Contains parameters to template an Android plugin.
///
/// The required fields include: [name] of the plugin, [package] of the plugin and
/// the [pluginClass] that will be the entry point to the plugin's native code.
class AndroidPlugin extends PluginPlatform {
  AndroidPlugin({
    @required this.name,
    @required this.package,
    @required this.pluginClass,
    @required this.pluginPath,
  });

  factory AndroidPlugin.fromYaml(String name, YamlMap yaml, String pluginPath) {
    assert(validate(yaml));
    return AndroidPlugin(
      name: name,
      package: yaml['package'] as String,
      pluginClass: yaml['pluginClass'] as String,
      pluginPath: pluginPath,
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml['package'] is String && yaml['pluginClass'] is String;
  }

  static const String kConfigKey = 'android';

  /// The plugin name defined in pubspec.yaml.
  final String name;

  /// The plugin package name defined in pubspec.yaml.
  final String package;

  /// The plugin main class defined in pubspec.yaml.
  final String pluginClass;

  /// The absolute path to the plugin in the pub cache.
  final String pluginPath;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'package': package,
      'class': pluginClass,
      // Mustache doesn't support complex types.
      'supportsEmbeddingV1': _supportedEmbedings.contains('1'),
      'supportsEmbeddingV2': _supportedEmbedings.contains('2'),
    };
  }

  Set<String> _cachedEmbeddingVersion;

  /// Returns the version of the Android embedding.
  Set<String> get _supportedEmbedings => _cachedEmbeddingVersion ??= _getSupportedEmbeddings();

  Set<String> _getSupportedEmbeddings() {
    assert(pluginPath != null);
    final Set<String> supportedEmbeddings = <String>{};
    final String baseMainPath = fs.path.join(
      pluginPath,
      'android',
      'src',
      'main',
    );
    File mainPluginClass = fs.file(
      fs.path.join(
        baseMainPath,
        'java',
        package.replaceAll('.', fs.path.separator),
        '$pluginClass.java',
      )
    );
    // Check if the plugin is implemented in Kotlin since the plugin's pubspec.yaml
    // doesn't include this information.
    if (!mainPluginClass.existsSync()) {
      mainPluginClass = fs.file(
        fs.path.join(
          baseMainPath,
          'kotlin',
          package.replaceAll('.', fs.path.separator),
          '$pluginClass.kt',
        )
      );
    }
    assert(mainPluginClass.existsSync());
    String mainClassContent;
    try {
      mainClassContent = mainPluginClass.readAsStringSync();
    } on FileSystemException {
      throwToolExit(
        'Couldn\'t read file $mainPluginClass even though it exists. '
        'Please verify that this file has read permission and try again.'
      );
    }
    if (mainClassContent
        .contains('io.flutter.embedding.engine.plugins.FlutterPlugin')) {
      supportedEmbeddings.add('2');
    } else {
      supportedEmbeddings.add('1');
    }
    if (mainClassContent.contains('PluginRegistry')
        && mainClassContent.contains('registerWith')) {
      supportedEmbeddings.add('1');
    }
    return supportedEmbeddings;
  }
}

/// Contains the parameters to template an iOS plugin.
///
/// The required fields include: [name] of the plugin, the [pluginClass] that
/// will be the entry point to the plugin's native code.
class IOSPlugin extends PluginPlatform {
  const IOSPlugin({
    @required this.name,
    this.classPrefix,
    @required this.pluginClass,
  });

  factory IOSPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    return IOSPlugin(
      name: name,
      classPrefix: '',
      pluginClass: yaml['pluginClass'] as String,
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml['pluginClass'] is String;
  }

  static const String kConfigKey = 'ios';

  final String name;

  /// Note, this is here only for legacy reasons. Multi-platform format
  /// always sets it to empty String.
  final String classPrefix;
  final String pluginClass;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'prefix': classPrefix,
      'class': pluginClass,
    };
  }
}

/// Contains the parameters to template a macOS plugin.
///
/// The required fields include: [name] of the plugin, and [pluginClass] that will
/// be the entry point to the plugin's native code.
class MacOSPlugin extends PluginPlatform {
  const MacOSPlugin({
    @required this.name,
    @required this.pluginClass,
  });

  factory MacOSPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    return MacOSPlugin(
      name: name,
      pluginClass: yaml['pluginClass'] as String,
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml['pluginClass'] is String;
  }

  static const String kConfigKey = 'macos';

  final String name;
  final String pluginClass;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'class': pluginClass,
    };
  }
}

/// Contains the parameters to template a Windows plugin.
///
/// The required fields include: [name] of the plugin, and [pluginClass] that will
/// be the entry point to the plugin's native code.
class WindowsPlugin extends PluginPlatform {
  const WindowsPlugin({
    @required this.name,
    @required this.pluginClass,
  });

  factory WindowsPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    return WindowsPlugin(
      name: name,
      pluginClass: yaml['pluginClass'] as String,
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml['pluginClass'] is String;
  }

  static const String kConfigKey = 'windows';

  final String name;
  final String pluginClass;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'class': pluginClass,
      'filename': _filenameForCppClass(pluginClass),
    };
  }
}

/// Contains the parameters to template a Linux plugin.
///
/// The required fields include: [name] of the plugin, and [pluginClass] that will
/// be the entry point to the plugin's native code.
class LinuxPlugin extends PluginPlatform {
  const LinuxPlugin({
    @required this.name,
    @required this.pluginClass,
  });

  factory LinuxPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    return LinuxPlugin(
      name: name,
      pluginClass: yaml['pluginClass'] as String,
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml['pluginClass'] is String;
  }

  static const String kConfigKey = 'linux';

  final String name;
  final String pluginClass;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'class': pluginClass,
      'filename': _filenameForCppClass(pluginClass),
    };
  }
}

/// Contains the parameters to template a web plugin.
///
/// The required fields include: [name] of the plugin, the [pluginClass] that will
/// be the entry point to the plugin's implementation, and the [fileName]
/// containing the code.
class WebPlugin extends PluginPlatform {
  const WebPlugin({
    @required this.name,
    @required this.pluginClass,
    @required this.fileName,
  });

  factory WebPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    return WebPlugin(
      name: name,
      pluginClass: yaml['pluginClass'] as String,
      fileName: yaml['fileName'] as String,
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml['pluginClass'] is String && yaml['fileName'] is String;
  }

  static const String kConfigKey = 'web';

  /// The name of the plugin.
  final String name;

  /// The class containing the plugin implementation details.
  ///
  /// This class should have a static `registerWith` method defined.
  final String pluginClass;

  /// The name of the file containing the class implementation above.
  final String fileName;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'class': pluginClass,
      'file': fileName,
    };
  }
}

final RegExp _internalCapitalLetterRegex = RegExp(r'(?=(?!^)[A-Z])');
String _filenameForCppClass(String className) {
  return className.splitMapJoin(
    _internalCapitalLetterRegex,
    onMatch: (_) => '_',
    onNonMatch: (String n) => n.toLowerCase());
}
