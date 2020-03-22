// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:yaml/yaml.dart';

import '../src/common.dart';

const String _kTestPluginName = 'test_plugin_name';
const String _kTestPluginPath = 'test_plugin_path';

void main() {
  group('PluginParsing', () {
    test('Legacy Format', () {
      const String pluginYamlRaw = 'androidPackage: com.flutter.dev\n'
          'iosPrefix: FLT\n'
          'pluginClass: SamplePlugin\n';

      final YamlMap pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
      final Plugin plugin =
          Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml, const <String>[]);

      final AndroidPlugin androidPlugin =
          plugin.platforms[AndroidPlugin.kConfigKey] as AndroidPlugin;
      final IOSPlugin iosPlugin = plugin.platforms[IOSPlugin.kConfigKey] as IOSPlugin;
      final String androidPluginClass = androidPlugin.pluginClass;
      final String iosPluginClass = iosPlugin.pluginClass;

      expect(iosPluginClass, 'SamplePlugin');
      expect(androidPluginClass, 'SamplePlugin');
      expect(iosPlugin.classPrefix, 'FLT');
      expect(androidPlugin.package, 'com.flutter.dev');
    });

    test('Multi-platform Format', () {
      const String pluginYamlRaw = 'platforms:\n'
          ' android:\n'
          '  package: com.flutter.dev\n'
          '  pluginClass: ASamplePlugin\n'
          ' ios:\n'
          '  pluginClass: ISamplePlugin\n'
          ' linux:\n'
          '  pluginClass: LSamplePlugin\n'
          ' macos:\n'
          '  pluginClass: MSamplePlugin\n'
          ' web:\n'
          '  pluginClass: WebSamplePlugin\n'
          '  fileName: web_plugin.dart\n'
          ' windows:\n'
          '  pluginClass: WinSamplePlugin\n';

      final YamlMap pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
      final Plugin plugin =
          Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml, const <String>[]);

      final AndroidPlugin androidPlugin =
          plugin.platforms[AndroidPlugin.kConfigKey] as AndroidPlugin;
      final IOSPlugin iosPlugin = plugin.platforms[IOSPlugin.kConfigKey] as IOSPlugin;
      final LinuxPlugin linuxPlugin =
          plugin.platforms[LinuxPlugin.kConfigKey] as LinuxPlugin;
      final MacOSPlugin macOSPlugin =
          plugin.platforms[MacOSPlugin.kConfigKey] as MacOSPlugin;
      final WebPlugin webPlugin = plugin.platforms[WebPlugin.kConfigKey] as WebPlugin;
      final WindowsPlugin windowsPlugin =
          plugin.platforms[WindowsPlugin.kConfigKey] as WindowsPlugin;
      final String androidPluginClass = androidPlugin.pluginClass;
      final String iosPluginClass = iosPlugin.pluginClass;

      expect(iosPluginClass, 'ISamplePlugin');
      expect(androidPluginClass, 'ASamplePlugin');
      expect(iosPlugin.classPrefix, '');
      expect(androidPlugin.package, 'com.flutter.dev');
      expect(linuxPlugin.pluginClass, 'LSamplePlugin');
      expect(macOSPlugin.pluginClass, 'MSamplePlugin');
      expect(webPlugin.pluginClass, 'WebSamplePlugin');
      expect(webPlugin.fileName, 'web_plugin.dart');
      expect(windowsPlugin.pluginClass, 'WinSamplePlugin');
    });

    test('Unknown fields are allowed (allows some future compatibility)', () {
      const String pluginYamlRaw = 'implements: same_plugin\n' // this should be ignored by the tool
          'platforms:\n'
          ' android:\n'
          '  package: com.flutter.dev\n'
          '  pluginClass: ASamplePlugin\n'
          '  anUnknownField: ASamplePlugin\n' // this should be ignored by the tool
          ' ios:\n'
          '  pluginClass: ISamplePlugin\n'
          ' linux:\n'
          '  pluginClass: LSamplePlugin\n'
          ' macos:\n'
          '  pluginClass: MSamplePlugin\n'
          ' web:\n'
          '  pluginClass: WebSamplePlugin\n'
          '  fileName: web_plugin.dart\n'
          ' windows:\n'
          '  pluginClass: WinSamplePlugin\n';

      final dynamic pluginYaml = loadYaml(pluginYamlRaw);
      final Plugin plugin =
      Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml as YamlMap, const <String>[]);

      final AndroidPlugin androidPlugin = plugin.platforms[AndroidPlugin.kConfigKey] as AndroidPlugin;
      final IOSPlugin iosPlugin = plugin.platforms[IOSPlugin.kConfigKey] as IOSPlugin;
      final LinuxPlugin linuxPlugin = plugin.platforms[LinuxPlugin.kConfigKey] as LinuxPlugin;
      final MacOSPlugin macOSPlugin = plugin.platforms[MacOSPlugin.kConfigKey] as MacOSPlugin;
      final WebPlugin webPlugin = plugin.platforms[WebPlugin.kConfigKey] as WebPlugin;
      final WindowsPlugin windowsPlugin = plugin.platforms[WindowsPlugin.kConfigKey] as WindowsPlugin;
      final String androidPluginClass = androidPlugin.pluginClass;
      final String iosPluginClass = iosPlugin.pluginClass;

      expect(iosPluginClass, 'ISamplePlugin');
      expect(androidPluginClass, 'ASamplePlugin');
      expect(iosPlugin.classPrefix, '');
      expect(androidPlugin.package, 'com.flutter.dev');
      expect(linuxPlugin.pluginClass, 'LSamplePlugin');
      expect(macOSPlugin.pluginClass, 'MSamplePlugin');
      expect(webPlugin.pluginClass, 'WebSamplePlugin');
      expect(webPlugin.fileName, 'web_plugin.dart');
      expect(windowsPlugin.pluginClass, 'WinSamplePlugin');
    });

    test('A default_package field is allowed', () {
      const String pluginYamlRaw =
          'platforms:\n'
          ' android:\n'
          '  default_package: sample_package_android\n'
          ' ios:\n'
          '  default_package: sample_package_ios\n'
          ' linux:\n'
          '  default_package: sample_package_linux\n'
          ' macos:\n'
          '  default_package: sample_package_macos\n'
          ' web:\n'
          '  default_package: sample_package_web\n'
          ' windows:\n'
          '  default_package: sample_package_windows\n';

      final dynamic pluginYaml = loadYaml(pluginYamlRaw);
      final Plugin plugin =
      Plugin.fromYaml(_kTestPluginName, _kTestPluginPath, pluginYaml as YamlMap, const <String>[]);

      expect(plugin.platforms, <String, PluginPlatform> {});
    });
  });
}
