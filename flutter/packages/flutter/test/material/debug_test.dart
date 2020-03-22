// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debugCheckHasMaterial control test', (WidgetTester tester) async {
    await tester.pumpWidget(const ListTile());
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    final FlutterError error = exception;
    expect(error.diagnostics.length, 5);
    expect(error.diagnostics[2].level, DiagnosticLevel.hint);
    expect(
      error.diagnostics[2].toStringDeep(),
      equalsIgnoringHashCodes(
        'To introduce a Material widget, you can either directly include\n'
        'one, or use a widget that contains Material itself, such as a\n'
        'Card, Dialog, Drawer, or Scaffold.\n',
      ),
    );
    expect(error.diagnostics[3], isInstanceOf<DiagnosticsProperty<Element>>());
    expect(error.diagnostics[4], isInstanceOf<DiagnosticsBlock>());
    expect(error.toStringDeep(),
      'FlutterError\n'
      '   No Material widget found.\n'
      '   ListTile widgets require a Material widget ancestor.\n'
      '   In material design, most widgets are conceptually "printed" on a\n'
      '   sheet of material. In Flutter\'s material library, that material\n'
      '   is represented by the Material widget. It is the Material widget\n'
      '   that renders ink splashes, for instance. Because of this, many\n'
      '   material library widgets require that there be a Material widget\n'
      '   in the tree above them.\n'
      '   To introduce a Material widget, you can either directly include\n'
      '   one, or use a widget that contains Material itself, such as a\n'
      '   Card, Dialog, Drawer, or Scaffold.\n'
      '   The specific widget that could not find a Material ancestor was:\n'
      '     ListTile\n'
      '   The ancestors of this widget were:\n'
      '     [root]\n'
    );
  });

  testWidgets('debugCheckHasMaterialLocalizations control test', (
      WidgetTester tester) async {
    await tester.pumpWidget(const BackButton());
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    final FlutterError error = exception;
    expect(error.diagnostics.length, 6);
    expect(error.diagnostics[3].level, DiagnosticLevel.hint);
    expect(
      error.diagnostics[3].toStringDeep(),
      equalsIgnoringHashCodes(
        'To introduce a MaterialLocalizations, either use a MaterialApp at\n'
        'the root of your application to include them automatically, or\n'
        'add a Localization widget with a MaterialLocalizations delegate.\n',
      ),
    );
    expect(error.diagnostics[4], isInstanceOf<DiagnosticsProperty<Element>>());
    expect(error.diagnostics[5], isInstanceOf<DiagnosticsBlock>());
    expect(error.toStringDeep(),
      'FlutterError\n'
      '   No MaterialLocalizations found.\n'
      '   BackButton widgets require MaterialLocalizations to be provided\n'
      '   by a Localizations widget ancestor.\n'
      '   Localizations are used to generate many different messages,\n'
      '   labels,and abbreviations which are used by the material library.\n'
      '   To introduce a MaterialLocalizations, either use a MaterialApp at\n'
      '   the root of your application to include them automatically, or\n'
      '   add a Localization widget with a MaterialLocalizations delegate.\n'
      '   The specific widget that could not find a MaterialLocalizations\n'
      '   ancestor was:\n'
      '     BackButton\n'
      '   The ancestors of this widget were:\n'
      '     [root]\n'
    );
  });

  testWidgets(
      'debugCheckHasScaffold control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            showBottomSheet<void>(context: context,
                builder: (BuildContext context) => Container());
            return Container();
          }
        ),
      ),
    );
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    final FlutterError error = exception;
    expect(error.diagnostics.length, 5);
    expect(error.diagnostics[2], isInstanceOf<DiagnosticsProperty<Element>>());
    expect(error.diagnostics[3], isInstanceOf<DiagnosticsBlock>());
    expect(error.diagnostics[4].level, DiagnosticLevel.hint);
    expect(
      error.diagnostics[4].toStringDeep(),
      equalsIgnoringHashCodes(
        'Typically, the Scaffold widget is introduced by the MaterialApp\n'
        'or WidgetsApp widget at the top of your application widget tree.\n',
      ),
    );
    expect(error.toStringDeep(), equalsIgnoringHashCodes(
      'FlutterError\n'
      '   No Scaffold widget found.\n'
      '   Builder widgets require a Scaffold widget ancestor.\n'
      '   The specific widget that could not find a Scaffold ancestor was:\n'
      '     Builder\n'
      '   The ancestors of this widget were:\n'
      '     Semantics\n'
      '     Builder\n'
      '     RepaintBoundary-[GlobalKey#2d465]\n'
      '     IgnorePointer\n'
      '     AnimatedBuilder\n'
      '     FadeTransition\n'
      '     FractionalTranslation\n'
      '     SlideTransition\n'
      '     _FadeUpwardsPageTransition\n'
      '     AnimatedBuilder\n'
      '     RepaintBoundary\n'
      '     _FocusMarker\n'
      '     Semantics\n'
      '     FocusScope\n'
      '     PageStorage\n'
      '     Offstage\n'
      '     _ModalScopeStatus\n'
      '     _ModalScope<dynamic>-[LabeledGlobalKey<_ModalScopeState<dynamic>>#969b7]\n'
      '     _OverlayEntry-[LabeledGlobalKey<_OverlayEntryState>#7a3ae]\n'
      '     Stack\n'
      '     _Theatre\n'
      '     Overlay-[LabeledGlobalKey<OverlayState>#31a52]\n'
      '     _FocusMarker\n'
      '     Semantics\n'
      '     FocusScope\n'
      '     AbsorbPointer\n'
      '     _PointerListener\n'
      '     Listener\n'
      '     Navigator-[GlobalObjectKey<NavigatorState> _WidgetsAppState#10579]\n'
      '     IconTheme\n'
      '     IconTheme\n'
      '     _InheritedCupertinoTheme\n'
      '     CupertinoTheme\n'
      '     _InheritedTheme\n'
      '     Theme\n'
      '     AnimatedTheme\n'
      '     Builder\n'
      '     DefaultTextStyle\n'
      '     CustomPaint\n'
      '     Banner\n'
      '     CheckedModeBanner\n'
      '     Title\n'
      '     Directionality\n'
      '     _LocalizationsScope-[GlobalKey#a51e3]\n'
      '     Semantics\n'
      '     Localizations\n'
      '     MediaQuery\n'
      '     _MediaQueryFromWindow\n'
      '     DefaultFocusTraversal\n'
      '     Actions\n'
      '     _ShortcutsMarker\n'
      '     Semantics\n'
      '     _FocusMarker\n'
      '     Focus\n'
      '     Shortcuts\n'
      '     WidgetsApp-[GlobalObjectKey _MaterialAppState#38e79]\n'
      '     ScrollConfiguration\n'
      '     MaterialApp\n'
      '     [root]\n'
      '   Typically, the Scaffold widget is introduced by the MaterialApp\n'
      '   or WidgetsApp widget at the top of your application widget tree.\n',
    ));
  });
}
