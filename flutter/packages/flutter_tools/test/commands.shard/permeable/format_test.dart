// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/format.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('format', () {
    Directory tempDir;

    setUp(() {
      Cache.disableLocking();
      tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_format_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testUsingContext('a file', () async {
      final String projectPath = await createProject(tempDir);

      final File srcFile = fs.file(fs.path.join(projectPath, 'lib', 'main.dart'));
      final String original = srcFile.readAsStringSync();
      srcFile.writeAsStringSync(original.replaceFirst('main()', 'main(  )'));

      final FormatCommand command = FormatCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['format', srcFile.path]);

      final String formatted = srcFile.readAsStringSync();
      expect(formatted, original);
    });

    testUsingContext('dry-run', () async {
      final String projectPath = await createProject(tempDir);

      final File srcFile = fs.file(
          fs.path.join(projectPath, 'lib', 'main.dart'));
      final String nonFormatted = srcFile.readAsStringSync().replaceFirst(
          'main()', 'main(  )');
      srcFile.writeAsStringSync(nonFormatted);

      final FormatCommand command = FormatCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['format', '--dry-run', srcFile.path]);

      final String shouldNotFormatted = srcFile.readAsStringSync();
      expect(shouldNotFormatted, nonFormatted);
    });

    testUsingContext('dry-run with set-exit-if-changed', () async {
      final String projectPath = await createProject(tempDir);

      final File srcFile = fs.file(
          fs.path.join(projectPath, 'lib', 'main.dart'));
      final String nonFormatted = srcFile.readAsStringSync().replaceFirst(
          'main()', 'main(  )');
      srcFile.writeAsStringSync(nonFormatted);

      final FormatCommand command = FormatCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      expect(runner.run(<String>[
        'format', '--dry-run', '--set-exit-if-changed', srcFile.path,
      ]), throwsException);

      final String shouldNotFormatted = srcFile.readAsStringSync();
      expect(shouldNotFormatted, nonFormatted);
    });

    testUsingContext('line-length', () async {
      const int lineLengthShort = 50;
      const int lineLengthLong = 120;
      final String projectPath = await createProject(tempDir);

      final File srcFile = fs.file(
          fs.path.join(projectPath, 'lib', 'main.dart'));
      final String nonFormatted = srcFile.readAsStringSync();
      srcFile.writeAsStringSync(
          nonFormatted.replaceFirst('main()',
              'main(anArgument1, anArgument2, anArgument3, anArgument4, anArgument5)'));

      final String nonFormattedWithLongLine = srcFile.readAsStringSync();
      final FormatCommand command = FormatCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      await runner.run(<String>['format', '--line-length', '$lineLengthLong', srcFile.path]);
      final String notFormatted = srcFile.readAsStringSync();
      expect(nonFormattedWithLongLine, notFormatted);

      await runner.run(<String>['format', '--line-length', '$lineLengthShort', srcFile.path]);
      final String shouldFormatted = srcFile.readAsStringSync();
      expect(nonFormattedWithLongLine, isNot(shouldFormatted));
    });
  });
}
