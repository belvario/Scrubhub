// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('Checkbox size is configurable by ThemeData.materialTapTargetSize', (WidgetTester tester) async {
    await tester.pumpWidget(
      Theme(
        data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.padded),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: Checkbox(
                value: true,
                onChanged: (bool newValue) { },
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(Checkbox)), const Size(48.0, 48.0));

    await tester.pumpWidget(
      Theme(
        data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: Checkbox(
                value: true,
                onChanged: (bool newValue) { },
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(Checkbox)), const Size(40.0, 40.0));
  });

  testWidgets('CheckBox semantics', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(Material(
      child: Checkbox(
        value: false,
        onChanged: (bool b) { },
      ),
    ));

    expect(tester.getSemantics(find.byType(Focus).last), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
      isFocusable: true,
    ));

    await tester.pumpWidget(Material(
      child: Checkbox(
        value: true,
        onChanged: (bool b) { },
      ),
    ));

    expect(tester.getSemantics(find.byType(Focus).last), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isChecked: true,
      isEnabled: true,
      hasTapAction: true,
      isFocusable: true,
    ));

    await tester.pumpWidget(const Material(
      child: Checkbox(
        value: false,
        onChanged: null,
      ),
    ));

    expect(tester.getSemantics(find.byType(Focus).last), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
    ));

    await tester.pumpWidget(const Material(
      child: Checkbox(
        value: true,
        onChanged: null,
      ),
    ));

    expect(tester.getSemantics(find.byType(Focus).last), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isChecked: true,
    ));
    handle.dispose();
  });

  testWidgets('Can wrap CheckBox with Semantics', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(Material(
      child: Semantics(
        label: 'foo',
        textDirection: TextDirection.ltr,
        child: Checkbox(
          value: false,
          onChanged: (bool b) { },
        ),
      ),
    ));

    expect(tester.getSemantics(find.byType(Focus).last), matchesSemantics(
      label: 'foo',
      textDirection: TextDirection.ltr,
      hasCheckedState: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
      isFocusable: true,
    ));
    handle.dispose();
  });

  testWidgets('CheckBox tristate: true', (WidgetTester tester) async {
    bool checkBoxValue;

    await tester.pumpWidget(
      Material(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Checkbox(
              tristate: true,
              value: checkBoxValue,
              onChanged: (bool value) {
                setState(() {
                  checkBoxValue = value;
                });
              },
            );
          },
        ),
      ),
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, null);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(checkBoxValue, false);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(checkBoxValue, true);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(checkBoxValue, null);

    checkBoxValue = true;
    await tester.pumpAndSettle();
    expect(checkBoxValue, true);

    checkBoxValue = null;
    await tester.pumpAndSettle();
    expect(checkBoxValue, null);
  });

  testWidgets('has semantics for tristate', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Material(
        child: Checkbox(
          tristate: true,
          value: null,
          onChanged: (bool newValue) { },
        ),
      ),
    );

    expect(semantics.nodesWith(
      flags: <SemanticsFlag>[
        SemanticsFlag.hasCheckedState,
        SemanticsFlag.hasEnabledState,
        SemanticsFlag.isEnabled,
        SemanticsFlag.isFocusable,
      ],
      actions: <SemanticsAction>[SemanticsAction.tap],
    ), hasLength(1));

    await tester.pumpWidget(
      Material(
        child: Checkbox(
          tristate: true,
          value: true,
          onChanged: (bool newValue) { },
        ),
      ),
    );

    expect(semantics.nodesWith(
      flags: <SemanticsFlag>[
        SemanticsFlag.hasCheckedState,
        SemanticsFlag.hasEnabledState,
        SemanticsFlag.isEnabled,
        SemanticsFlag.isChecked,
        SemanticsFlag.isFocusable,
      ],
      actions: <SemanticsAction>[SemanticsAction.tap],
    ), hasLength(1));

    await tester.pumpWidget(
      Material(
        child: Checkbox(
          tristate: true,
          value: false,
          onChanged: (bool newValue) { },
        ),
      ),
    );

    expect(semantics.nodesWith(
      flags: <SemanticsFlag>[
        SemanticsFlag.hasCheckedState,
        SemanticsFlag.hasEnabledState,
        SemanticsFlag.isEnabled,
        SemanticsFlag.isFocusable,
      ],
      actions: <SemanticsAction>[SemanticsAction.tap],
    ), hasLength(1));

    semantics.dispose();
  });

  testWidgets('has semantic events', (WidgetTester tester) async {
    dynamic semanticEvent;
    bool checkboxValue = false;
    SystemChannels.accessibility.setMockMessageHandler((dynamic message) async {
      semanticEvent = message;
    });
    final SemanticsTester semanticsTester = SemanticsTester(tester);

    await tester.pumpWidget(
      Material(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Checkbox(
              value: checkboxValue,
              onChanged: (bool value) {
                setState(() {
                  checkboxValue = value;
                });
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    final RenderObject object = tester.firstRenderObject(find.byType(Focus));

    expect(checkboxValue, true);
    expect(semanticEvent, <String, dynamic>{
      'type': 'tap',
      'nodeId': object.debugSemantics.id,
      'data': <String, dynamic>{},
    });
    expect(object.debugSemantics.getSemanticsData().hasAction(SemanticsAction.tap), true);

    SystemChannels.accessibility.setMockMessageHandler(null);
    semanticsTester.dispose();
  });

  testWidgets('CheckBox tristate rendering, programmatic transitions', (WidgetTester tester) async {
    Widget buildFrame(bool checkboxValue) {
      return Material(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Checkbox(
              tristate: true,
              value: checkboxValue,
              onChanged: (bool value) { },
            );
          },
        ),
      );
    }

    RenderToggleable getCheckboxRenderer() {
      return tester.renderObject<RenderToggleable>(find.byWidgetPredicate((Widget widget) {
        return widget.runtimeType.toString() == '_CheckboxRenderObjectWidget';
      }));
    }

    await tester.pumpWidget(buildFrame(false));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), isNot(paints..path())); // checkmark is rendered as a path
    expect(getCheckboxRenderer(), isNot(paints..line())); // null is rendered as a line (a "dash")
    expect(getCheckboxRenderer(), paints..drrect()); // empty checkbox

    await tester.pumpWidget(buildFrame(true));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..path()); // checkmark is rendered as a path

    await tester.pumpWidget(buildFrame(false));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), isNot(paints..path())); // checkmark is rendered as a path
    expect(getCheckboxRenderer(), isNot(paints..line())); // null is rendered as a line (a "dash")
    expect(getCheckboxRenderer(), paints..drrect()); // empty checkbox

    await tester.pumpWidget(buildFrame(null));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..line()); // null is rendered as a line (a "dash")

    await tester.pumpWidget(buildFrame(true));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..path()); // checkmark is rendered as a path

    await tester.pumpWidget(buildFrame(null));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..line()); // null is rendered as a line (a "dash")
  });

  testWidgets('CheckBox color rendering', (WidgetTester tester) async {
    Widget buildFrame({Color activeColor, Color checkColor, ThemeData themeData}) {
      return Material(
        child: Theme(
          data: themeData ?? ThemeData(),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Checkbox(
                value: true,
                activeColor: activeColor,
                checkColor: checkColor,
                onChanged: (bool value) { },
              );
            },
          ),
        ),
      );
    }

    RenderToggleable getCheckboxRenderer() {
      return tester.renderObject<RenderToggleable>(find.byWidgetPredicate((Widget widget) {
        return widget.runtimeType.toString() == '_CheckboxRenderObjectWidget';
      }));
    }

    await tester.pumpWidget(buildFrame(checkColor: const Color(0xFFFFFFFF)));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..path(color: const Color(0xFFFFFFFF))); // paints's color is 0xFFFFFFFF (default color)

    await tester.pumpWidget(buildFrame(checkColor: const Color(0xFF000000)));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..path(color: const Color(0xFF000000))); // paints's color is 0xFF000000 (params)

    await tester.pumpWidget(buildFrame(themeData: ThemeData(toggleableActiveColor: const Color(0xFF00FF00))));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..rrect(color: const Color(0xFF00FF00))); // paints's color is 0xFF00FF00 (theme)

    await tester.pumpWidget(buildFrame(activeColor: const Color(0xFF000000)));
    await tester.pumpAndSettle();
    expect(getCheckboxRenderer(), paints..rrect(color: const Color(0xFF000000))); // paints's color is 0xFF000000 (params)
  });

  testWidgets('Checkbox is focusable and has correct focus color', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'Checkbox');
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    bool value = true;
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Checkbox(
                value: value,
                onChanged: enabled ? (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                } : null,
                focusColor: Colors.orange[500],
                autofocus: true,
                focusNode: focusNode,
              );
            }),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildApp());

    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(
      Material.of(tester.element(find.byType(Checkbox))),
      paints
        ..circle(color: Colors.orange[500])
        ..rrect(
            color: const Color(0xff1e88e5),
            rrect: RRect.fromLTRBR(
                391.0, 291.0, 409.0, 309.0, const Radius.circular(1.0)))
        ..path(color: Colors.white),
    );

    // Check the false value.
    value = false;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(
      Material.of(tester.element(find.byType(Checkbox))),
      paints
        ..circle(color: Colors.orange[500])
        ..drrect(
            color: const Color(0x8a000000),
            outer: RRect.fromLTRBR(
                391.0, 291.0, 409.0, 309.0, const Radius.circular(1.0)),
        inner: RRect.fromLTRBR(393.0,
            293.0, 407.0, 307.0, const Radius.circular(-1.0))),
    );

    // Check what happens when disabled.
    value = false;
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isFalse);
    expect(
      Material.of(tester.element(find.byType(Checkbox))),
      paints
        ..drrect(
            color: const Color(0x61000000),
            outer: RRect.fromLTRBR(
                391.0, 291.0, 409.0, 309.0, const Radius.circular(1.0)),
            inner: RRect.fromLTRBR(393.0,
                293.0, 407.0, 307.0, const Radius.circular(-1.0))),
    );
  });

  testWidgets('Checkbox can be hovered and has correct hover color', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    bool value = true;
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Checkbox(
                value: value,
                onChanged: enabled ? (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                } : null,
                hoverColor: Colors.orange[500],
              );
            }),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(Checkbox))),
      paints
        ..rrect(
            color: const Color(0xff1e88e5),
            rrect: RRect.fromLTRBR(
                391.0, 291.0, 409.0, 309.0, const Radius.circular(1.0)))
        ..path(color: const Color(0xffffffff), style: PaintingStyle.stroke, strokeWidth: 2.0),
    );

    // Start hovering
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(Checkbox)));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(Checkbox))),
      paints
        ..rrect(
            color: const Color(0xff1e88e5),
            rrect: RRect.fromLTRBR(
                391.0, 291.0, 409.0, 309.0, const Radius.circular(1.0)))
        ..path(color: const Color(0xffffffff), style: PaintingStyle.stroke, strokeWidth: 2.0),
    );

    // Check what happens when disabled.
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(
      Material.of(tester.element(find.byType(Checkbox))),
      paints
        ..rrect(
            color: const Color(0x61000000),
            rrect: RRect.fromLTRBR(
                391.0, 291.0, 409.0, 309.0, const Radius.circular(1.0)))
        ..path(color: const Color(0xffffffff), style: PaintingStyle.stroke, strokeWidth: 2.0),
    );
  });

  testWidgets('Checkbox can be toggled by keyboard shortcuts', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    bool value = true;
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Checkbox(
                value: value,
                onChanged: enabled ? (bool newValue) {
                  setState(() {
                    value = newValue;
                  });
                } : null,
                focusColor: Colors.orange[500],
                autofocus: true,
              );
            }),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    // On web, switches don't respond to the enter key.
    expect(value, kIsWeb ? isTrue : isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(value, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(value, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });
}
