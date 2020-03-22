// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';

import '../src/common.dart';

void main() {
  Config config;
  MemoryFileSystem memoryFileSystem;

  setUp(() {
    memoryFileSystem = MemoryFileSystem();
    final File file = memoryFileSystem.file('example');
    config = Config(file);
  });
  test('Config get set value', () async {
    expect(config.getValue('foo'), null);
    config.setValue('foo', 'bar');
    expect(config.getValue('foo'), 'bar');
    expect(config.keys, contains('foo'));
  });

  test('Config get set bool value', () async {
    expect(config.getValue('foo'), null);
    config.setValue('foo', true);
    expect(config.getValue('foo'), true);
    expect(config.keys, contains('foo'));
  });

  test('Config containsKey', () async {
    expect(config.containsKey('foo'), false);
    config.setValue('foo', 'bar');
    expect(config.containsKey('foo'), true);
  });

  test('Config removeValue', () async {
    expect(config.getValue('foo'), null);
    config.setValue('foo', 'bar');
    expect(config.getValue('foo'), 'bar');
    expect(config.keys, contains('foo'));
    config.removeValue('foo');
    expect(config.getValue('foo'), null);
    expect(config.keys, isNot(contains('foo')));
  });

  test('Config parse error', () {
    final BufferLogger bufferLogger =BufferLogger();
    final File file = memoryFileSystem.file('example')
      ..writeAsStringSync('{"hello":"bar');
    config = Config(file, bufferLogger);

    expect(file.existsSync(), false);
    expect(bufferLogger.errorText, contains('Failed to decode preferences'));
  });
}
