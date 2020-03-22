// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('MaterialButton defaults', (WidgetTester tester) async {
    final Finder rawButtonMaterial = find.descendant(
      of: find.byType(MaterialButton),
      matching: find.byType(Material),
    );

    // Enabled MaterialButton
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialButton(
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );
    Material material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, null);
    expect(material.elevation, 2.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0)));
    expect(material.textStyle.color, const Color(0xdd000000));
    expect(material.textStyle.fontFamily, 'Roboto');
    expect(material.textStyle.fontSize, 14);
    expect(material.textStyle.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.transparency);

    final Offset center = tester.getCenter(find.byType(MaterialButton));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    // Only elevation changes when enabled and pressed.
    material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, null);
    expect(material.elevation, 8.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0)));
    expect(material.textStyle.color, const Color(0xdd000000));
    expect(material.textStyle.fontFamily, 'Roboto');
    expect(material.textStyle.fontSize, 14);
    expect(material.textStyle.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.transparency);

    // Disabled MaterialButton
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialButton(
          onPressed: null,
          child: Text('button'),
        ),
      ),
    );
    material = tester.widget<Material>(rawButtonMaterial);
    expect(material.animationDuration, const Duration(milliseconds: 200));
    expect(material.borderOnForeground, true);
    expect(material.borderRadius, null);
    expect(material.clipBehavior, Clip.none);
    expect(material.color, null);
    expect(material.elevation, 0.0);
    expect(material.shadowColor, const Color(0xff000000));
    expect(material.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0)));
    expect(material.textStyle.color, const Color(0x61000000));
    expect(material.textStyle.fontFamily, 'Roboto');
    expect(material.textStyle.fontSize, 14);
    expect(material.textStyle.fontWeight, FontWeight.w500);
    expect(material.type, MaterialType.transparency);
  });

  testWidgets('Does MaterialButton work with hover', (WidgetTester tester) async {
    const Color hoverColor = Color(0xff001122);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialButton(
          hoverColor: hoverColor,
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(MaterialButton)));
    await tester.pumpAndSettle();

    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: hoverColor));

    await gesture.removePointer();
  });

  testWidgets('Does MaterialButton work with focus', (WidgetTester tester) async {
    const Color focusColor = Color(0xff001122);

    final FocusNode focusNode = FocusNode(debugLabel: 'MaterialButton Node');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialButton(
          focusColor: focusColor,
          focusNode: focusNode,
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );

    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    focusNode.requestFocus();
    await tester.pumpAndSettle();

    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: focusColor));
  });

  testWidgets('MaterialButton elevation and colors have proper precedence', (WidgetTester tester) async {
    const double elevation = 10.0;
    const double focusElevation = 11.0;
    const double hoverElevation = 12.0;
    const double highlightElevation = 13.0;
    const Color focusColor = Color(0xff001122);
    const Color hoverColor = Color(0xff112233);
    const Color highlightColor = Color(0xff223344);

    final Finder rawButtonMaterial = find.descendant(
      of: find.byType(MaterialButton),
      matching: find.byType(Material),
    );

    final FocusNode focusNode = FocusNode(debugLabel: 'MaterialButton Node');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialButton(
          focusColor: focusColor,
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          elevation: elevation,
          focusElevation: focusElevation,
          hoverElevation: hoverElevation,
          highlightElevation: highlightElevation,
          focusNode: focusNode,
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    // Base elevation
    Material material = tester.widget<Material>(rawButtonMaterial);
    expect(material.elevation, equals(elevation));

    // Focus elevation overrides base
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    material = tester.widget<Material>(rawButtonMaterial);
    RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: focusColor));
    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(material.elevation, equals(focusElevation));

    // Hover elevation overrides focus
    TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(() => gesture?.removePointer());
    await gesture.moveTo(tester.getCenter(find.byType(MaterialButton)));
    await tester.pumpAndSettle();
    material = tester.widget<Material>(rawButtonMaterial);
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: focusColor)..rect(color: hoverColor));
    expect(material.elevation, equals(hoverElevation));
    await gesture.removePointer();
    gesture = null;

    // Highlight elevation overrides hover
    final TestGesture gesture2 = await tester.startGesture(tester.getCenter(find.byType(MaterialButton)));
    addTearDown(gesture2.removePointer);
    await tester.pumpAndSettle();
    material = tester.widget<Material>(rawButtonMaterial);
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    expect(inkFeatures, paints..rect(color: focusColor)..rect(color: highlightColor));
    expect(material.elevation, equals(highlightElevation));
    await gesture2.up();
  });

  testWidgets('MaterialButton\'s disabledColor takes precedence over its default disabled color.', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/30012.

    final Finder rawButtonMaterial = find.descendant(
      of: find.byType(MaterialButton),
      matching: find.byType(Material),
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialButton(
          disabledColor: Color(0xff00ff00),
          onPressed: null,
          child: Text('button'),
        ),
      ),
    );

    final Material material = tester.widget<Material>(rawButtonMaterial);
    expect(material.color, const Color(0xff00ff00));
  });

  testWidgets('Default MaterialButton meets a11y contrast guidelines', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MaterialButton(
              child: const Text('MaterialButton'),
              onPressed: () { },
            ),
          ),
        ),
      ),
    );

    // Default, not disabled.
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Highlighted (pressed).
    final Offset center = tester.getCenter(find.byType(MaterialButton));
    await tester.startGesture(center);
    await tester.pump(); // Start the splash and highlight animations.
    await tester.pump(const Duration(milliseconds: 800)); // Wait for splash and highlight to be well under way.
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  },
    semanticsEnabled: true,
    skip: isBrowser,
  );

  testWidgets('MaterialButton gets focus when autofocus is set.', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'MaterialButton');
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: MaterialButton(
            focusNode: focusNode,
            onPressed: () {},
            child: Container(width: 100, height: 100, color: const Color(0xffff0000)),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: MaterialButton(
            autofocus: true,
            focusNode: focusNode,
            onPressed: () {},
            child: Container(width: 100, height: 100, color: const Color(0xffff0000)),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(focusNode.hasPrimaryFocus, isTrue);
  });

  testWidgets('MaterialButton onPressed and onLongPress callbacks are correctly called when non-null', (WidgetTester tester) async {

    bool wasPressed;
    Finder materialButton;

    Widget buildFrame({ VoidCallback onPressed, VoidCallback onLongPress }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialButton(
          child: const Text('button'),
          onPressed: onPressed,
          onLongPress: onLongPress,
        ),
      );
    }

    // onPressed not null, onLongPress null.
    wasPressed = false;
    await tester.pumpWidget(
      buildFrame(onPressed: () { wasPressed = true; }, onLongPress: null),
    );
    materialButton = find.byType(MaterialButton);
    expect(tester.widget<MaterialButton>(materialButton).enabled, true);
    await tester.tap(materialButton);
    expect(wasPressed, true);

    // onPressed null, onLongPress not null.
    wasPressed = false;
    await tester.pumpWidget(
      buildFrame(onPressed: null, onLongPress: () { wasPressed = true; }),
    );
    materialButton = find.byType(MaterialButton);
    expect(tester.widget<MaterialButton>(materialButton).enabled, true);
    await tester.longPress(materialButton);
    expect(wasPressed, true);

    // onPressed null, onLongPress null.
    await tester.pumpWidget(
      buildFrame(onPressed: null, onLongPress: null),
    );
    materialButton = find.byType(MaterialButton);
    expect(tester.widget<MaterialButton>(materialButton).enabled, false);
  });

  testWidgets('MaterialButton onPressed and onLongPress callbacks are distinctly recognized', (WidgetTester tester) async {
    bool didPressButton = false;
    bool didLongPressButton = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialButton(
          onPressed: () {
            didPressButton = true;
          },
          onLongPress: () {
            didLongPressButton = true;
          },
          child: const Text('button'),
        ),
      ),
    );

    final Finder materialButton = find.byType(MaterialButton);
    expect(tester.widget<MaterialButton>(materialButton).enabled, true);

    expect(didPressButton, isFalse);
    await tester.tap(materialButton);
    expect(didPressButton, isTrue);

    expect(didLongPressButton, isFalse);
    await tester.longPress(materialButton);
    expect(didLongPressButton, isTrue);
  });

  // This test is very similar to the '...explicit splashColor and highlightColor' test
  // in icon_button_test.dart. If you change this one, you may want to also change that one.
  testWidgets('MaterialButton with explicit splashColor and highlightColor', (WidgetTester tester) async {
    const Color directSplashColor = Color(0xFF000011);
    const Color directHighlightColor = Color(0xFF000011);

    Widget buttonWidget = Material(
      child: Center(
        child: MaterialButton(
          splashColor: directSplashColor,
          highlightColor: directHighlightColor,
          onPressed: () { /* to make sure the button is enabled */ },
          clipBehavior: Clip.antiAlias,
        ),
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: buttonWidget,
        ),
      ),
    );

    final Offset center = tester.getCenter(find.byType(MaterialButton));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    await tester.pump(const Duration(milliseconds: 200)); // wait for splash to be well under way

    const Rect expectedClipRect = Rect.fromLTRB(356.0, 282.0, 444.0, 318.0);
    final Path expectedClipPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
          expectedClipRect,
          const Radius.circular(2.0),
      ));
    expect(
      Material.of(tester.element(find.byType(MaterialButton))),
      paints
        ..clipPath(pathMatcher: coversSameAreaAs(
            expectedClipPath,
            areaToCompare: expectedClipRect.inflate(10.0),
        ))
        ..circle(color: directSplashColor)
        ..rect(color: directHighlightColor),
    );

    const Color themeSplashColor1 = Color(0xFF001100);
    const Color themeHighlightColor1 = Color(0xFF001100);

    buttonWidget = Material(
      child: Center(
        child: MaterialButton(
          onPressed: () { /* to make sure the button is enabled */ },
          clipBehavior: Clip.antiAlias,
        ),
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(
            highlightColor: themeHighlightColor1,
            splashColor: themeSplashColor1,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: buttonWidget,
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byType(MaterialButton))),
      paints
        ..clipPath(pathMatcher: coversSameAreaAs(
            expectedClipPath,
            areaToCompare: expectedClipRect.inflate(10.0),
        ))
        ..circle(color: themeSplashColor1)
        ..rect(color: themeHighlightColor1),
    );

    const Color themeSplashColor2 = Color(0xFF002200);
    const Color themeHighlightColor2 = Color(0xFF002200);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(
            highlightColor: themeHighlightColor2,
            splashColor: themeSplashColor2,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: buttonWidget, // same widget, so does not get updated because of us
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byType(MaterialButton))),
      paints
        ..circle(color: themeSplashColor2)
        ..rect(color: themeHighlightColor2),
    );

    await gesture.up();
  });

  testWidgets('MaterialButton has no clip by default', (WidgetTester tester) async {
    final GlobalKey buttonKey = GlobalKey();
    final Widget buttonWidget = Material(
      child: Center(
        child: MaterialButton(
          key: buttonKey,
          onPressed: () { /* to make sure the button is enabled */ },
        ),
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: buttonWidget,
        ),
      ),
    );

    expect(
      tester.renderObject(find.byKey(buttonKey)),
      paintsExactlyCountTimes(#clipPath, 0),
    );
  });

  testWidgets('Disabled MaterialButton has same semantic size as enabled and exposes disabled semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    const Rect expectedButtonSize = Rect.fromLTRB(0.0, 0.0, 116.0, 48.0);
    // Button is in center of screen
    final Matrix4 expectedButtonTransform = Matrix4.identity()
      ..translate(
        TestSemantics.fullScreen.width / 2 - expectedButtonSize.width /2,
        TestSemantics.fullScreen.height / 2 - expectedButtonSize.height /2,
      );

    // enabled button
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: Center(
          child: MaterialButton(
            child: const Text('Button'),
            onPressed: () { /* to make sure the button is enabled */ },
          ),
        ),
      ),
    ));

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics.rootChild(
            id: 1,
            rect: expectedButtonSize,
            transform: expectedButtonTransform,
            label: 'Button',
            actions: <SemanticsAction>[
              SemanticsAction.tap,
            ],
            flags: <SemanticsFlag>[
              SemanticsFlag.hasEnabledState,
              SemanticsFlag.isButton,
              SemanticsFlag.isEnabled,
              SemanticsFlag.isFocusable,
            ],
          ),
        ],
      ),
    ));

    // disabled button
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: Center(
          child: MaterialButton(
            child: Text('Button'),
            onPressed: null, // button is disabled
          ),
        ),
      ),
    ));

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics.rootChild(
            id: 1,
            rect: expectedButtonSize,
            transform: expectedButtonTransform,
            label: 'Button',
            flags: <SemanticsFlag>[
              SemanticsFlag.hasEnabledState,
              SemanticsFlag.isButton,
              SemanticsFlag.isFocusable,
            ],
          ),
        ],
      ),
    ));


    semantics.dispose();
  }, skip: isBrowser);

  testWidgets('MaterialButton minWidth and height parameters', (WidgetTester tester) async {
    Widget buildFrame({ double minWidth, double height, EdgeInsets padding = EdgeInsets.zero, Widget child }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: MaterialButton(
            padding: padding,
            minWidth: minWidth,
            height: height,
            onPressed: null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            child: child,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(minWidth: 8.0, height: 24.0));
    expect(tester.getSize(find.byType(MaterialButton)), const Size(8.0, 24.0));

    await tester.pumpWidget(buildFrame(minWidth: 8.0));
    // Default minHeight constraint is 36, see RawMaterialButton.
    expect(tester.getSize(find.byType(MaterialButton)), const Size(8.0, 36.0));

    await tester.pumpWidget(buildFrame(height: 8.0));
    // Default minWidth constraint is 88, see RawMaterialButton.
    expect(tester.getSize(find.byType(MaterialButton)), const Size(88.0, 8.0));

    await tester.pumpWidget(buildFrame());
    expect(tester.getSize(find.byType(MaterialButton)), const Size(88.0, 36.0));

    await tester.pumpWidget(buildFrame(padding: const EdgeInsets.all(4.0)));
    expect(tester.getSize(find.byType(MaterialButton)), const Size(88.0, 36.0));

    // Size is defined by the padding.
    await tester.pumpWidget(
      buildFrame(
        minWidth: 0.0,
        height: 0.0,
        padding: const EdgeInsets.all(4.0),
      ),
    );
    expect(tester.getSize(find.byType(MaterialButton)), const Size(8.0, 8.0));

    // Size is defined by the padded child.
    await tester.pumpWidget(
      buildFrame(
        minWidth: 0.0,
        height: 0.0,
        padding: const EdgeInsets.all(4.0),
        child: const SizedBox(width: 8.0, height: 8.0),
      ),
    );
    expect(tester.getSize(find.byType(MaterialButton)), const Size(16.0, 16.0));

    // Size is defined by the minWidth, height constraints.
    await tester.pumpWidget(
      buildFrame(
        minWidth: 18.0,
        height: 18.0,
        padding: const EdgeInsets.all(4.0),
        child: const SizedBox(width: 8.0, height: 8.0),
      ),
    );
    expect(tester.getSize(find.byType(MaterialButton)), const Size(18.0, 18.0));
  });

  testWidgets('MaterialButton size is configurable by ThemeData.materialTapTargetSize', (WidgetTester tester) async {
    final Key key1 = UniqueKey();
    await tester.pumpWidget(
      Theme(
        data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.padded),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: MaterialButton(
                key: key1,
                child: const SizedBox(width: 50.0, height: 8.0),
                onPressed: () { },
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key1)), const Size(88.0, 48.0));

    final Key key2 = UniqueKey();
    await tester.pumpWidget(
      Theme(
        data: ThemeData(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Center(
              child: MaterialButton(
                key: key2,
                child: const SizedBox(width: 50.0, height: 8.0),
                onPressed: () { },
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key2)), const Size(88.0, 36.0));
  });

  testWidgets('MaterialButton shape overrides ButtonTheme shape', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/29146
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialButton(
          onPressed: () { },
          shape: const StadiumBorder(),
          child: const Text('button'),
        ),
      ),
    );

    final Finder rawButtonMaterial = find.descendant(
      of: find.byType(MaterialButton),
      matching: find.byType(Material),
    );
    expect(tester.widget<Material>(rawButtonMaterial).shape, const StadiumBorder());
  });
}
