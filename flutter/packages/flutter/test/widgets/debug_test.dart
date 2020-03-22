// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debugChildrenHaveDuplicateKeys control test', () {
    const Key key = Key('key');
    final List<Widget> children = <Widget>[
      Container(key: key),
      Container(key: key),
    ];
    final Widget widget = Flex(
      direction: Axis.vertical,
      children: children
    );
    FlutterError error;
    try {
      debugChildrenHaveDuplicateKeys(widget, children);
    } on FlutterError catch (e) {
      error = e;
    } finally {
      expect(error, isNotNull);
      expect(
        error.toStringDeep(),
        equalsIgnoringHashCodes(
          'FlutterError\n'
          '   Duplicate keys found.\n'
          '   If multiple keyed nodes exist as children of another node, they\n'
          '   must have unique keys.\n'
          '   Flex(direction: vertical, mainAxisAlignment: start,\n'
          '   crossAxisAlignment: center) has multiple children with key\n'
          '   [<\'key\'>].\n',
        ),
      );
    }
  });

  test('debugItemsHaveDuplicateKeys control test', () {
    const Key key = Key('key');
    final List<Widget> items = <Widget>[
      Container(key: key),
      Container(key: key),
    ];
    FlutterError error;
    try {
      debugItemsHaveDuplicateKeys(items);
    } on FlutterError catch (e) {
      error = e;
    } finally {
      expect(error, isNotNull);
      expect(
        error.toStringDeep(),
        equalsIgnoringHashCodes(
          'FlutterError\n'
          '   Duplicate key found: [<\'key\'>].\n'
        ),
      );
    }
  });

  testWidgets('debugCheckHasTable control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          FlutterError error;
          try {
            debugCheckHasTable(context);
          } on FlutterError catch (e) {
            error = e;
          } finally {
            expect(error, isNotNull);
            expect(error.diagnostics.length, 4);
            expect(error.diagnostics[2], isInstanceOf<DiagnosticsProperty<Element>>());
            expect(
              error.toStringDeep(),
              equalsIgnoringHashCodes(
                'FlutterError\n'
                '   No Table widget found.\n'
                '   Builder widgets require a Table widget ancestor.\n'
                '   The specific widget that could not find a Table ancestor was:\n'
                '     Builder\n'
                '   The ownership chain for the affected widget is: "Builder ←\n'
                '     [root]"\n'
              ),
            );
          }
          return Container();
        }
      ),
    );
  });

  testWidgets('debugCheckHasMediaQuery control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          FlutterError error;
          try {
            debugCheckHasMediaQuery(context);
          } on FlutterError catch (e) {
            error = e;
          } finally {
            expect(error, isNotNull);
            expect(error.diagnostics.length, 5);
            expect(error.diagnostics[2], isInstanceOf<DiagnosticsProperty<Element>>());
            expect(error.diagnostics.last.level, DiagnosticLevel.hint);
            expect(
              error.diagnostics.last.toStringDeep(),
              equalsIgnoringHashCodes(
                'Typically, the MediaQuery widget is introduced by the MaterialApp\n'
                'or WidgetsApp widget at the top of your application widget tree.\n'
              ),
            );
            expect(
              error.toStringDeep(),
              equalsIgnoringHashCodes(
                'FlutterError\n'
                '   No MediaQuery widget found.\n'
                '   Builder widgets require a MediaQuery widget ancestor.\n'
                '   The specific widget that could not find a MediaQuery ancestor\n'
                '   was:\n'
                '     Builder\n'
                '   The ownership chain for the affected widget is: "Builder ←\n'
                '     [root]"\n'
                '   Typically, the MediaQuery widget is introduced by the MaterialApp\n'
                '   or WidgetsApp widget at the top of your application widget tree.\n'
              ),
            );
          }
          return Container();
        }
      ),
    );
  });

  test('debugWidgetBuilderValue control test', () {
    final Widget widget = Container();
    FlutterError error;
    try {
      debugWidgetBuilderValue(widget, null);
    } on FlutterError catch (e) {
      error = e;
    } finally {
      expect(error, isNotNull);
      expect(error.diagnostics.length, 4);
      expect(error.diagnostics[1], isInstanceOf<DiagnosticsProperty<Widget>>());
      expect(error.diagnostics[1].style, DiagnosticsTreeStyle.errorProperty);
      expect(
        error.diagnostics[1].toStringDeep(),
        equalsIgnoringHashCodes(
          'The offending widget is:\n'
          '  Container\n'
        )
      );
      expect(error.diagnostics[2].level, DiagnosticLevel.info);
      expect(error.diagnostics[3].level, DiagnosticLevel.hint);
      expect(
        error.diagnostics[3].toStringDeep(),
        equalsIgnoringHashCodes(
          'To return an empty space that causes the building widget to fill\n'
          'available room, return "Container()". To return an empty space\n'
          'that takes as little room as possible, return "Container(width:\n'
          '0.0, height: 0.0)".\n',
        )
      );
      expect(
        error.toStringDeep(),
        equalsIgnoringHashCodes(
          'FlutterError\n'
          '   A build function returned null.\n'
          '   The offending widget is:\n'
          '     Container\n'
          '   Build functions must never return null.\n'
          '   To return an empty space that causes the building widget to fill\n'
          '   available room, return "Container()". To return an empty space\n'
          '   that takes as little room as possible, return "Container(width:\n'
          '   0.0, height: 0.0)".\n'
        ),
      );
      error = null;
    }
    try {
      debugWidgetBuilderValue(widget, widget);
    } on FlutterError catch (e) {
      error = e;
    } finally {
      expect(error, isNotNull);
      expect(error.diagnostics.length, 3);
      expect(error.diagnostics[1], isInstanceOf<DiagnosticsProperty<Widget>>());
      expect(error.diagnostics[1].style, DiagnosticsTreeStyle.errorProperty);
      expect(
        error.diagnostics[1].toStringDeep(),
        equalsIgnoringHashCodes(
          'The offending widget is:\n'
          '  Container\n'
        )
      );
      expect(
        error.toStringDeep(),
        equalsIgnoringHashCodes(
          'FlutterError\n'
          '   A build function returned context.widget.\n'
          '   The offending widget is:\n'
          '     Container\n'
          '   Build functions must never return their BuildContext parameter\'s\n'
          '   widget or a child that contains "context.widget". Doing so\n'
          '   introduces a loop in the widget tree that can cause the app to\n'
          '   crash.\n'
        ),
      );
    }
  });

  test('debugAssertAllWidgetVarsUnset', () {
    debugHighlightDeprecatedWidgets = true;
    FlutterError error;
    try {
      debugAssertAllWidgetVarsUnset('The value of a widget debug variable was changed by the test.');
    } on FlutterError catch (e) {
      error = e;
    } finally {
      expect(error, isNotNull);
      expect(error.diagnostics.length, 1);
      expect(
        error.toStringDeep(),
        'FlutterError\n'
        '   The value of a widget debug variable was changed by the test.\n',
      );
    }
  });
}
