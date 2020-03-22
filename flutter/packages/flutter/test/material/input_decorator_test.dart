// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('!chrome') // needs substantial triage.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

Widget buildInputDecorator({
  InputDecoration decoration = const InputDecoration(),
  InputDecorationTheme inputDecorationTheme,
  TextDirection textDirection = TextDirection.ltr,
  bool expands = false,
  bool isEmpty = false,
  bool isFocused = false,
  bool isHovering = false,
  TextStyle baseStyle,
  TextAlignVertical textAlignVertical,
  Widget child = const Text(
    'text',
    style: TextStyle(fontFamily: 'Ahem', fontSize: 16.0),
  ),
}) {
  return MaterialApp(
    home: Material(
      child: Builder(
        builder: (BuildContext context) {
          return Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: inputDecorationTheme,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Directionality(
                textDirection: textDirection,
                child: InputDecorator(
                  expands: expands,
                  decoration: decoration,
                  isEmpty: isEmpty,
                  isFocused: isFocused,
                  isHovering: isHovering,
                  baseStyle: baseStyle,
                  textAlignVertical: textAlignVertical,
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

Finder findBorderPainter() {
  return find.descendant(
    of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_BorderContainer'),
    matching: find.byWidgetPredicate((Widget w) => w is CustomPaint),
  );
}

double getBorderBottom(WidgetTester tester) {
  final RenderBox box = InputDecorator.containerOf(tester.element(findBorderPainter()));
  return box.size.height;
}

InputBorder getBorder(WidgetTester tester) {
  if (!tester.any(findBorderPainter()))
    return null;
  final CustomPaint customPaint = tester.widget(findBorderPainter());
  final dynamic/*_InputBorderPainter*/ inputBorderPainter = customPaint.foregroundPainter;
  final dynamic/*_InputBorderTween*/ inputBorderTween = inputBorderPainter.border;
  final Animation<double> animation = inputBorderPainter.borderAnimation;
  final dynamic/*_InputBorder*/ border = inputBorderTween.evaluate(animation);
  return border;
}

BorderSide getBorderSide(WidgetTester tester) {
  return getBorder(tester)?.borderSide;
}

BorderRadius getBorderRadius(WidgetTester tester) {
  final InputBorder border = getBorder(tester);
  if (border is UnderlineInputBorder) {
    return border.borderRadius;
  }
  return null;
}

double getBorderWeight(WidgetTester tester) => getBorderSide(tester)?.width;

Color getBorderColor(WidgetTester tester) => getBorderSide(tester)?.color;

Color getContainerColor(WidgetTester tester) {
  final CustomPaint customPaint = tester.widget(findBorderPainter());
  final dynamic/*_InputBorderPainter*/ inputBorderPainter = customPaint.foregroundPainter;
  return inputBorderPainter.blendedColor;
}

double getOpacity(WidgetTester tester, String textValue) {
  final FadeTransition opacityWidget = tester.widget<FadeTransition>(
    find.ancestor(
      of: find.text(textValue),
      matching: find.byType(FadeTransition),
    ).first,
  );
  return opacityWidget.opacity.value;
}

void main() {
  testWidgets('InputDecorator input/label layout', (WidgetTester tester) async {
    // The label appears above the input text
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
        ),
      ),
    );

    // Overall height for this InputDecorator is 56dps:
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);

    // isFocused: true increases the border's weight from 1.0 to 2.0
    // but does not change the overall height.
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        isFocused: true,
        decoration: const InputDecoration(
          labelText: 'label',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 2.0);

    // isEmpty: true causes the label to be aligned with the input text
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: false,
        decoration: const InputDecoration(
          labelText: 'label',
        ),
      ),
    );

    // The label animates downwards from it's initial position
    // above the input text. The animation's duration is 200ms.
    {
      await tester.pump(const Duration(milliseconds: 50));
      final double labelY50ms = tester.getTopLeft(find.text('label')).dy;
      expect(labelY50ms, inExclusiveRange(12.0, 20.0));
      await tester.pump(const Duration(milliseconds: 50));
      final double labelY100ms = tester.getTopLeft(find.text('label')).dy;
      expect(labelY100ms, inExclusiveRange(labelY50ms, 20.0));
    }
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);

    // isFocused: true causes the label to move back up above the input text.
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: true,
        decoration: const InputDecoration(
          labelText: 'label',
        ),
      ),
    );

    // The label animates upwards from it's initial position
    // above the input text. The animation's duration is 200ms.
    {
      await tester.pump(const Duration(milliseconds: 50));
      final double labelY50ms = tester.getTopLeft(find.text('label')).dy;
      expect(labelY50ms, inExclusiveRange(12.0, 28.0));
      await tester.pump(const Duration(milliseconds: 50));
      final double labelY100ms = tester.getTopLeft(find.text('label')).dy;
      expect(labelY100ms, inExclusiveRange(12.0, labelY50ms));
    }

    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 2.0);

    // enabled: false produces a hairline border if filled: false (the default)
    // The widget's size and layout is the same as for enabled: true.
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: false,
        decoration: const InputDecoration(
          labelText: 'label',
          enabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderWeight(tester), 0.0);

    // enabled: false produces a transparent border if filled: true.
    // The widget's size and layout is the same as for enabled: true.
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: false,
        decoration: const InputDecoration(
          labelText: 'label',
          enabled: false,
          filled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderColor(tester), Colors.transparent);

    // alignLabelWithHint: true positions the label at the text baseline,
    // aligned with the hint.
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: false,
        decoration: const InputDecoration(
          labelText: 'label',
          alignLabelWithHint: true,
          hintText: 'hint',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('label')).dy, tester.getTopLeft(find.text('hint')).dy);
    expect(tester.getBottomLeft(find.text('label')).dy, tester.getBottomLeft(find.text('hint')).dy);
  });

  group('alignLabelWithHint', () {
    group('expands false', () {
      testWidgets('multiline TextField no-strut', (WidgetTester tester) async {
        const String text = 'text';
        final FocusNode focusNode = FocusNode();
        final TextEditingController controller = TextEditingController();
        Widget buildFrame(bool alignLabelWithHint) {
          return MaterialApp(
            home: Material(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'label',
                    alignLabelWithHint: alignLabelWithHint,
                    hintText: 'hint',
                  ),
                  strutStyle: StrutStyle.disabled,
                ),
              ),
            ),
          );
        }

        // alignLabelWithHint: false centers the label in the TextField.
        await tester.pumpWidget(buildFrame(false));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('label')).dy, 76.0);
        expect(tester.getBottomLeft(find.text('label')).dy, 92.0);

        // Entering text still happens at the top.
        await tester.enterText(find.byType(TextField), text);
        expect(tester.getTopLeft(find.text(text)).dy, 28.0);
        controller.clear();
        focusNode.unfocus();

        // alignLabelWithHint: true aligns the label with the hint.
        await tester.pumpWidget(buildFrame(true));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('label')).dy, tester.getTopLeft(find.text('hint')).dy);
        expect(tester.getBottomLeft(find.text('label')).dy, tester.getBottomLeft(find.text('hint')).dy);

        // Entering text still happens at the top.
        await tester.enterText(find.byType(TextField), text);
        expect(tester.getTopLeft(find.text(text)).dy, 28.0);
        controller.clear();
        focusNode.unfocus();
      });

      testWidgets('multiline TextField', (WidgetTester tester) async {
        const String text = 'text';
        final FocusNode focusNode = FocusNode();
        final TextEditingController controller = TextEditingController();
        Widget buildFrame(bool alignLabelWithHint) {
          return MaterialApp(
            home: Material(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'label',
                    alignLabelWithHint: alignLabelWithHint,
                    hintText: 'hint',
                  ),
                ),
              ),
            ),
          );
        }

        // alignLabelWithHint: false centers the label in the TextField.
        await tester.pumpWidget(buildFrame(false));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('label')).dy, 76.0);
        expect(tester.getBottomLeft(find.text('label')).dy, 92.0);

        // Entering text still happens at the top.
        await tester.enterText(find.byType(InputDecorator), text);
        expect(tester.getTopLeft(find.text(text)).dy, 28.0);
        controller.clear();
        focusNode.unfocus();

        // alignLabelWithHint: true aligns the label with the hint.
        await tester.pumpWidget(buildFrame(true));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('label')).dy, tester.getTopLeft(find.text('hint')).dy);
        expect(tester.getBottomLeft(find.text('label')).dy, tester.getBottomLeft(find.text('hint')).dy);

        // Entering text still happens at the top.
        await tester.enterText(find.byType(InputDecorator), text);
        expect(tester.getTopLeft(find.text(text)).dy, 28.0);
        controller.clear();
        focusNode.unfocus();
      });
    });

    group('expands true', () {
      testWidgets('multiline TextField', (WidgetTester tester) async {
        const String text = 'text';
        final FocusNode focusNode = FocusNode();
        final TextEditingController controller = TextEditingController();
        Widget buildFrame(bool alignLabelWithHint) {
          return MaterialApp(
            home: Material(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    labelText: 'label',
                    alignLabelWithHint: alignLabelWithHint,
                    hintText: 'hint',
                  ),
                ),
              ),
            ),
          );
        }

        // alignLabelWithHint: false centers the label in the TextField.
        await tester.pumpWidget(buildFrame(false));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('label')).dy, 292.0);
        expect(tester.getBottomLeft(find.text('label')).dy, 308.0);

        // Entering text still happens at the top.
        await tester.enterText(find.byType(InputDecorator), text);
        expect(tester.getTopLeft(find.text(text)).dy, 28.0);
        controller.clear();
        focusNode.unfocus();

        // alignLabelWithHint: true aligns the label with the hint at the top.
        await tester.pumpWidget(buildFrame(true));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('label')).dy, 28.0);
        expect(tester.getTopLeft(find.text('label')).dy, tester.getTopLeft(find.text('hint')).dy);
        expect(tester.getBottomLeft(find.text('label')).dy, tester.getBottomLeft(find.text('hint')).dy);

        // Entering text still happens at the top.
        await tester.enterText(find.byType(InputDecorator), text);
        expect(tester.getTopLeft(find.text(text)).dy, 28.0);
        controller.clear();
        focusNode.unfocus();
      });

      testWidgets('multiline TextField with outline border', (WidgetTester tester) async {
        const String text = 'text';
        final FocusNode focusNode = FocusNode();
        final TextEditingController controller = TextEditingController();
        Widget buildFrame(bool alignLabelWithHint) {
          return MaterialApp(
            home: Material(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    labelText: 'label',
                    alignLabelWithHint: alignLabelWithHint,
                    hintText: 'hint',
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(width: 1, color: Colors.black, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // alignLabelWithHint: false centers the label in the TextField.
        await tester.pumpWidget(buildFrame(false));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('label')).dy, 292.0);
        expect(tester.getBottomLeft(find.text('label')).dy, 308.0);

        // Entering text happens in the center as well.
        await tester.enterText(find.byType(InputDecorator), text);
        expect(tester.getTopLeft(find.text(text)).dy, 291.0);
        controller.clear();
        focusNode.unfocus();

        // alignLabelWithHint: true aligns keeps the label in the center because
        // that's where the hint is.
        await tester.pumpWidget(buildFrame(true));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('label')).dy, 291.0);
        expect(tester.getTopLeft(find.text('label')).dy, tester.getTopLeft(find.text('hint')).dy);
        expect(tester.getBottomLeft(find.text('label')).dy, tester.getBottomLeft(find.text('hint')).dy);

        // Entering text still happens in the center.
        await tester.enterText(find.byType(InputDecorator), text);
        expect(tester.getTopLeft(find.text(text)).dy, 291.0);
        controller.clear();
        focusNode.unfocus();
      });
    });
  });

  // Overall height for this InputDecorator is 40.0dps
  //   12 - top padding
  //   16 - input text (ahem font size 16dps)
  //   12 - bottom padding
  testWidgets('InputDecorator input/hint layout', (WidgetTester tester) async {
    // The hint aligns with the input text
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          hintText: 'hint',
        ),
      ),
    );

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, kMinInteractiveDimension));
    expect(tester.getTopLeft(find.text('text')).dy, 16.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 32.0);
    expect(tester.getTopLeft(find.text('hint')).dy, 16.0);
    expect(tester.getBottomLeft(find.text('hint')).dy, 32.0);
    expect(getBorderBottom(tester), 48.0);
    expect(getBorderWeight(tester), 1.0);

    expect(tester.getSize(find.text('hint')).width, tester.getSize(find.text('text')).width);
  });

  testWidgets('InputDecorator input/label/hint layout', (WidgetTester tester) async {
    // Label is visible, hint is not (opacity 0.0).
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
        ),
      ),
    );

    // Overall height for this InputDecorator is 56dps. When the
    // label is "floating" (empty input or no focus) the layout is:
    //
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding
    //
    // When the label is not floating, it's vertically centered.
    //
    //   20 - top padding
    //   16 - label (ahem font size 16dps)
    //   20 - bottom padding (empty input text still appears here)


    // The label is not floating so it's vertically centered.
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getOpacity(tester, 'hint'), 0.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);

    // Label moves upwards, hint is visible (opacity 1.0).
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: true,
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
        ),
      ),
    );

    // The hint's opacity animates from 0.0 to 1.0.
    // The animation's duration is 200ms.
    {
      await tester.pump(const Duration(milliseconds: 50));
      final double hintOpacity50ms = getOpacity(tester, 'hint');
      expect(hintOpacity50ms, inExclusiveRange(0.0, 1.0));
      await tester.pump(const Duration(milliseconds: 50));
      final double hintOpacity100ms = getOpacity(tester, 'hint');
      expect(hintOpacity100ms, inExclusiveRange(hintOpacity50ms, 1.0));
    }

    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(tester.getTopLeft(find.text('hint')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('hint')).dy, 44.0);
    expect(getOpacity(tester, 'hint'), 1.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 2.0);

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: false,
        isFocused: true,
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
        ),
      ),
    );

    // The hint's opacity animates from 1.0 to 0.0.
    // The animation's duration is 200ms.
    {
      await tester.pump(const Duration(milliseconds: 50));
      final double hintOpacity50ms = getOpacity(tester, 'hint');
      expect(hintOpacity50ms, inExclusiveRange(0.0, 1.0));
      await tester.pump(const Duration(milliseconds: 50));
      final double hintOpacity100ms = getOpacity(tester, 'hint');
      expect(hintOpacity100ms, inExclusiveRange(0.0, hintOpacity50ms));
    }

    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(tester.getTopLeft(find.text('hint')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('hint')).dy, 44.0);
    expect(getOpacity(tester, 'hint'), 0.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 2.0);
  });

  testWidgets('InputDecorator input/label/hint dense layout', (WidgetTester tester) async {
    // Label is visible, hint is not (opacity 0.0).
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
          isDense: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 48dps. When the
    // label is "floating" (empty input or no focus) the layout is:
    //
    //    8 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //    8 - bottom padding
    //
    // When the label is not floating, it's vertically centered.
    //
    //   16 - top padding
    //   16 - label (ahem font size 16dps)
    //   16 - bottom padding (empty input text still appears here)

    // The label is not floating so it's vertically centered.
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 48.0));
    expect(tester.getTopLeft(find.text('text')).dy, 24.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 40.0);
    expect(tester.getTopLeft(find.text('label')).dy, 16.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 32.0);
    expect(getOpacity(tester, 'hint'), 0.0);
    expect(getBorderBottom(tester), 48.0);
    expect(getBorderWeight(tester), 1.0);

    // Label is visible, hint is not (opacity 0.0).
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: true,
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
          isDense: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 48.0));
    expect(tester.getTopLeft(find.text('text')).dy, 24.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 40.0);
    expect(tester.getTopLeft(find.text('label')).dy, 8.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 20.0);
    expect(getOpacity(tester, 'hint'), 1.0);
    expect(getBorderBottom(tester), 48.0);
    expect(getBorderWeight(tester), 2.0);
  });

  testWidgets('InputDecorator with no input border', (WidgetTester tester) async {
    // Label is visible, hint is not (opacity 0.0).
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
      ),
    );
    expect(getBorderWeight(tester), 0.0);
  });

  testWidgets('InputDecorator error/helper/counter layout', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: 'helper',
          counterText: 'counter',
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 76dps. When the label is
    // floating the layout is:
    //
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding
    //    8 - below the border padding
    //   12 - help/error/counter text (ahem font size 12dps)
    //
    // When the label is not floating, it's vertically centered in the space
    // above the subtext:
    //
    //   20 - top padding
    //   16 - label (ahem font size 16dps)
    //   20 - bottom padding (empty input text still appears here)
    //    8 - below the border padding
    //   12 - help/error/counter text (ahem font size 12dps)

    // isEmpty: true, the label is not floating
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 76.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);
    expect(tester.getTopLeft(find.text('helper')), const Offset(12.0, 64.0));
    expect(tester.getTopRight(find.text('counter')), const Offset(788.0, 64.0));

    // If errorText is specified then the helperText isn't shown
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          errorText: 'error',
          helperText: 'helper',
          counterText: 'counter',
          filled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // isEmpty: false, the label _is_ floating
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 76.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);
    expect(tester.getTopLeft(find.text('error')), const Offset(12.0, 64.0));
    expect(tester.getTopRight(find.text('counter')), const Offset(788.0, 64.0));
    expect(find.text('helper'), findsNothing);

    // Overall height for this dense layout InputDecorator is 68dps. When the
    // label is floating the layout is:
    //
    //    8 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //    8 - bottom padding
    //    8 - below the border padding
    //   12 - help/error/counter text (ahem font size 12dps)
    //
    // When the label is not floating, it's vertically centered in the space
    // above the subtext:
    //
    //   16 - top padding
    //   16 - label (ahem font size 16dps)
    //   16 - bottom padding (empty input text still appears here)
    //    8 - below the border padding
    //   12 - help/error/counter text (ahem font size 12dps)
    // The layout of the error/helper/counter subtext doesn't change for dense layout.
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          isDense: true,
          labelText: 'label',
          errorText: 'error',
          helperText: 'helper',
          counterText: 'counter',
          filled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // isEmpty: false, the label _is_ floating
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 68.0));
    expect(tester.getTopLeft(find.text('text')).dy, 24.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 40.0);
    expect(tester.getTopLeft(find.text('label')).dy, 8.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 20.0);
    expect(getBorderBottom(tester), 48.0);
    expect(getBorderWeight(tester), 1.0);
    expect(tester.getTopLeft(find.text('error')), const Offset(12.0, 56.0));
    expect(tester.getTopRight(find.text('counter')), const Offset(788.0, 56.0));

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          isDense: true,
          labelText: 'label',
          errorText: 'error',
          helperText: 'helper',
          counterText: 'counter',
          filled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // isEmpty: false, the label is not floating
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 68.0));
    expect(tester.getTopLeft(find.text('text')).dy, 24.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 40.0);
    expect(tester.getTopLeft(find.text('label')).dy, 16.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 32.0);
    expect(getBorderBottom(tester), 48.0);
    expect(getBorderWeight(tester), 1.0);
    expect(tester.getTopLeft(find.text('error')), const Offset(12.0, 56.0));
    expect(tester.getTopRight(find.text('counter')), const Offset(788.0, 56.0));
  });

  testWidgets('InputDecorator counter text, widget, and null', (WidgetTester tester) async {
    Widget buildFrame({
      InputCounterWidgetBuilder buildCounter,
      String counterText,
      Widget counter,
      int maxLength,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  buildCounter: buildCounter,
                  maxLength: maxLength,
                  decoration: InputDecoration(
                    counterText: counterText,
                    counter: counter,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // When counter, counterText, and buildCounter are null, defaults to showing
    // the built-in counter.
    int maxLength = 10;
    await tester.pumpWidget(buildFrame(maxLength: maxLength));
    Finder counterFinder = find.byType(Text);
    expect(counterFinder, findsOneWidget);
    final Text counterWidget = tester.widget(counterFinder);
    expect(counterWidget.data, '0/${maxLength.toString()}');

    // When counter, counterText, and buildCounter are set, shows the counter
    // widget.
    final Key counterKey = UniqueKey();
    final Key buildCounterKey = UniqueKey();
    const String counterText = 'I show instead of count';
    final Widget counter = Text('hello', key: counterKey);
    final InputCounterWidgetBuilder buildCounter =
      (BuildContext context, { int currentLength, int maxLength, bool isFocused }) {
        return Text(
          '${currentLength.toString()} of ${maxLength.toString()}',
          key: buildCounterKey,
        );
      };
    await tester.pumpWidget(buildFrame(
      counterText: counterText,
      counter: counter,
      buildCounter: buildCounter,
      maxLength: maxLength,
    ));
    counterFinder = find.byKey(counterKey);
    expect(counterFinder, findsOneWidget);
    expect(find.text(counterText), findsNothing);
    expect(find.byKey(buildCounterKey), findsNothing);

    // When counter is null but counterText and buildCounter are set, shows the
    // counterText.
    await tester.pumpWidget(buildFrame(
      counterText: counterText,
      buildCounter: buildCounter,
      maxLength: maxLength,
    ));
    expect(find.text(counterText), findsOneWidget);
    counterFinder = find.byKey(counterKey);
    expect(counterFinder, findsNothing);
    expect(find.byKey(buildCounterKey), findsNothing);

    // When counter and counterText are null but buildCounter is set, shows the
    // generated widget.
    await tester.pumpWidget(buildFrame(
      buildCounter: buildCounter,
      maxLength: maxLength,
    ));
    expect(find.byKey(buildCounterKey), findsOneWidget);
    expect(counterFinder, findsNothing);
    expect(find.text(counterText), findsNothing);

    // When counterText is empty string and counter and buildCounter are null,
    // shows nothing.
    await tester.pumpWidget(buildFrame(counterText: '', maxLength: maxLength));
    expect(find.byType(Text), findsNothing);

    // When no maxLength, can still show a counter
    maxLength = null;
    await tester.pumpWidget(buildFrame(
      buildCounter: buildCounter,
      maxLength: maxLength,
    ));
    expect(find.byKey(buildCounterKey), findsOneWidget);
  });

  testWidgets('InputDecoration errorMaxLines', (WidgetTester tester) async {
    const String kError1 = 'e0';
    const String kError2 = 'e0\ne1';
    const String kError3 = 'e0\ne1\ne2';

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: 'helper',
          errorText: kError3,
          errorMaxLines: 3,
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 100dps:
    //
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding
    //    8 - below the border padding
    //   36 - error text (3 lines, ahem font size 12dps)

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 100.0));
    expect(tester.getTopLeft(find.text(kError3)), const Offset(12.0, 64.0));
    expect(tester.getBottomLeft(find.text(kError3)), const Offset(12.0, 100.0));

    // Overall height for this InputDecorator is 12 less than the first
    // one, 88dps, because errorText only occupies two lines.

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: 'helper',
          errorText: kError2,
          errorMaxLines: 3,
          filled: true,
        ),
      ),
    );

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 88.0));
    expect(tester.getTopLeft(find.text(kError2)), const Offset(12.0, 64.0));
    expect(tester.getBottomLeft(find.text(kError2)), const Offset(12.0, 88.0));

    // Overall height for this InputDecorator is 24 less than the first
    // one, 88dps, because errorText only occupies one line.

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: 'helper',
          errorText: kError1,
          errorMaxLines: 3,
          filled: true,
        ),
      ),
    );

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 76.0));
    expect(tester.getTopLeft(find.text(kError1)), const Offset(12.0, 64.0));
    expect(tester.getBottomLeft(find.text(kError1)), const Offset(12.0, 76.0));
  });

  testWidgets('InputDecoration helperMaxLines', (WidgetTester tester) async {
    const String kHelper1 = 'e0';
    const String kHelper2 = 'e0\ne1';
    const String kHelper3 = 'e0\ne1\ne2';

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: kHelper3,
          helperMaxLines: 3,
          errorText: null,
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 100dps:
    //
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding
    //    8 - below the border padding
    //   36 - helper text (3 lines, ahem font size 12dps)

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 100.0));
    expect(tester.getTopLeft(find.text(kHelper3)), const Offset(12.0, 64.0));
    expect(tester.getBottomLeft(find.text(kHelper3)), const Offset(12.0, 100.0));

    // Overall height for this InputDecorator is 12 less than the first
    // one, 88dps, because helperText only occupies two lines.

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: kHelper3,
          helperMaxLines: 2,
          errorText: null,
          filled: true,
        ),
      ),
    );

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 88.0));
    expect(tester.getTopLeft(find.text(kHelper3)), const Offset(12.0, 64.0));
    expect(tester.getBottomLeft(find.text(kHelper3)), const Offset(12.0, 88.0));

    // Overall height for this InputDecorator is 12 less than the first
    // one, 88dps, because helperText only occupies two lines.

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: kHelper2,
          helperMaxLines: 3,
          errorText: null,
          filled: true,
        ),
      ),
    );

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 88.0));
    expect(tester.getTopLeft(find.text(kHelper2)), const Offset(12.0, 64.0));
    expect(tester.getBottomLeft(find.text(kHelper2)), const Offset(12.0, 88.0));

    // Overall height for this InputDecorator is 24 less than the first
    // one, 88dps, because helperText only occupies one line.

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: kHelper1,
          helperMaxLines: 3,
          errorText: null,
          filled: true,
        ),
      ),
    );

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 76.0));
    expect(tester.getTopLeft(find.text(kHelper1)), const Offset(12.0, 64.0));
    expect(tester.getBottomLeft(find.text(kHelper1)), const Offset(12.0, 76.0));
  });

  testWidgets('InputDecorator prefix/suffix texts', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          prefixText: 'p',
          suffixText: 's',
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 40dps:
    //   12 - top padding
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding
    //
    // The prefix and suffix wrap the input text and are left and right justified
    // respectively. They should have the same height as the input text (16).

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, kMinInteractiveDimension));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getSize(find.text('p')).height, 16.0);
    expect(tester.getSize(find.text('s')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 16.0);
    expect(tester.getTopLeft(find.text('p')).dy, 16.0);
    expect(tester.getTopLeft(find.text('p')).dx, 12.0);
    expect(tester.getTopLeft(find.text('s')).dy, 16.0);
    expect(tester.getTopRight(find.text('s')).dx, 788.0);

    // layout is a row: [p text s]
    expect(tester.getTopLeft(find.text('p')).dx, 12.0);
    expect(tester.getTopRight(find.text('p')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('text')).dx));
    expect(tester.getTopRight(find.text('text')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('s')).dx));
  });

  testWidgets('InputDecorator icon/prefix/suffix', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          prefixText: 'p',
          suffixText: 's',
          icon: Icon(Icons.android),
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 40dps:
    //   12 - top padding
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, kMinInteractiveDimension));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getSize(find.text('p')).height, 16.0);
    expect(tester.getSize(find.text('s')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 16.0);
    expect(tester.getTopLeft(find.text('p')).dy, 16.0);
    expect(tester.getTopLeft(find.text('s')).dy, 16.0);
    expect(tester.getTopRight(find.text('s')).dx, 788.0);
    expect(tester.getSize(find.byType(Icon)).height, 24.0);

    // The 24dps high icon is centered on the 16dps high input line
    expect(tester.getTopLeft(find.byType(Icon)).dy, 12.0);

    // layout is a row: [icon, p text s]
    expect(tester.getTopLeft(find.byType(Icon)).dx, 0.0);
    expect(tester.getTopRight(find.byType(Icon)).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('p')).dx));
    expect(tester.getTopRight(find.text('p')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('text')).dx));
    expect(tester.getTopRight(find.text('text')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('s')).dx));
  });

  testWidgets('InputDecorator prefix/suffix widgets', (WidgetTester tester) async {
    const Key pKey = Key('p');
    const Key sKey = Key('s');
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          prefix: Padding(
            key: pKey,
            padding: EdgeInsets.all(4.0),
            child: Text('p'),
          ),
          suffix: Padding(
            key: sKey,
            padding: EdgeInsets.all(4.0),
            child: Text('s'),
          ),
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 48dps because
    // the prefix and the suffix widget is surrounded with padding:
    //   12 - top padding
    //    4 - top prefix/suffix padding
    //   16 - input text (ahem font size 16dps)
    //    4 - bottom prefix/suffix padding
    //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 48.0));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getSize(find.byKey(pKey)).height, 24.0);
    expect(tester.getSize(find.text('p')).height, 16.0);
    expect(tester.getSize(find.byKey(sKey)).height, 24.0);
    expect(tester.getSize(find.text('s')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 16.0);
    expect(tester.getTopLeft(find.byKey(pKey)).dy, 12.0);
    expect(tester.getTopLeft(find.text('p')).dy, 16.0);
    expect(tester.getTopLeft(find.byKey(sKey)).dy, 12.0);
    expect(tester.getTopLeft(find.text('s')).dy, 16.0);
    expect(tester.getTopRight(find.byKey(sKey)).dx, 788.0);
    expect(tester.getTopRight(find.text('s')).dx, 784.0);

    // layout is a row: [prefix text suffix]
    expect(tester.getTopLeft(find.byKey(pKey)).dx, 12.0);
    expect(tester.getTopRight(find.byKey(pKey)).dx, tester.getTopLeft(find.text('text')).dx);
    expect(tester.getTopRight(find.text('text')).dx, lessThanOrEqualTo(tester.getTopRight(find.byKey(sKey)).dx));
  });

  testWidgets('InputDecorator tall prefix', (WidgetTester tester) async {
    const Key pKey = Key('p');
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: InputDecoration(
          prefix: Container(
            key: pKey,
            height: 100,
            width: 10,
          ),
          filled: true,
        ),
        // Set the fontSize so that everything works out to whole numbers.
        child: const Text(
          'text',
          style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
        ),
      ),
    );

    // Overall height for this InputDecorator is ~127.2dps because
    // the prefix is 100dps tall, but it aligns with the input's baseline,
    // overlapping the input a bit.
    //   12 - top padding
    //  100 - total height of prefix
    //  -16 - input prefix overlap (distance input top to baseline, not exact)
    //   20 - input text (ahem font size 16dps)
    //    0 - bottom prefix/suffix padding
    //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)).width, 800.0);
    expect(tester.getSize(find.byType(InputDecorator)).height, closeTo(128.0, .0001));
    expect(tester.getSize(find.text('text')).height, 20.0);
    expect(tester.getSize(find.byKey(pKey)).height, 100.0);
    expect(tester.getTopLeft(find.text('text')).dy, closeTo(96, .0001)); // 12 + 100 - 16
    expect(tester.getTopLeft(find.byKey(pKey)).dy, 12.0);

    // layout is a row: [prefix text suffix]
    expect(tester.getTopLeft(find.byKey(pKey)).dx, 12.0);
    expect(tester.getTopRight(find.byKey(pKey)).dx, tester.getTopLeft(find.text('text')).dx);
  });

  testWidgets('InputDecorator tall prefix with border', (WidgetTester tester) async {
    const Key pKey = Key('p');
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefix: Container(
            key: pKey,
            height: 100,
            width: 10,
          ),
          filled: true,
        ),
        // Set the fontSize so that everything works out to whole numbers.
        child: const Text(
          'text',
          style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
        ),
      ),
    );

    // Overall height for this InputDecorator is ~127.2dps because
    // the prefix is 100dps tall, but it aligns with the input's baseline,
    // overlapping the input a bit.
    //   24 - top padding
    //  100 - total height of prefix
    //  -16 - input prefix overlap (distance input top to baseline, not exact)
    //   20 - input text (ahem font size 16dps)
    //    0 - bottom prefix/suffix padding
    //   16 - bottom padding
    // When a border is present, the input text and prefix/suffix are centered
    // within the input. Here, that will be content of height 106, including 2
    // extra pixels of space, centered within an input of height 144. That gives
    // 19 pixels of space on each side of the content, so the prefix is
    // positioned at 19, and the text is at 19+100-16=103.

    expect(tester.getSize(find.byType(InputDecorator)).width, 800.0);
    expect(tester.getSize(find.byType(InputDecorator)).height, closeTo(144, .0001));
    expect(tester.getSize(find.text('text')).height, 20.0);
    expect(tester.getSize(find.byKey(pKey)).height, 100.0);
    expect(tester.getTopLeft(find.text('text')).dy, closeTo(103, .0001));
    expect(tester.getTopLeft(find.byKey(pKey)).dy, 19.0);

    // layout is a row: [prefix text suffix]
    expect(tester.getTopLeft(find.byKey(pKey)).dx, 12.0);
    expect(tester.getTopRight(find.byKey(pKey)).dx, tester.getTopLeft(find.text('text')).dx);
  });

  testWidgets('InputDecorator prefixIcon/suffixIcon', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.pages),
          suffixIcon: Icon(Icons.satellite),
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 48dps because the prefix icon's minimum size
    // is 48x48 and the rest of the elements only require 40dps:
     //   12 - top padding
     //   16 - input text (ahem font size 16dps)
     //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 48.0));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getSize(find.byIcon(Icons.pages)).height, 48.0);
    expect(tester.getSize(find.byIcon(Icons.satellite)).height, 48.0);
    expect(tester.getTopLeft(find.text('text')).dy, 12.0);
    expect(tester.getTopLeft(find.byIcon(Icons.pages)).dy, 0.0);
    expect(tester.getTopLeft(find.byIcon(Icons.satellite)).dy, 0.0);
    expect(tester.getTopRight(find.byIcon(Icons.satellite)).dx, 800.0);


    // layout is a row: [icon text icon]
    expect(tester.getTopLeft(find.byIcon(Icons.pages)).dx, 0.0);
    expect(tester.getTopRight(find.byIcon(Icons.pages)).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('text')).dx));
    expect(tester.getTopRight(find.text('text')).dx, lessThanOrEqualTo(tester.getTopLeft(find.byIcon(Icons.satellite)).dx));
  });

  testWidgets('prefix/suffix icons are centered when smaller than 48 by 48', (WidgetTester tester) async {
    const Key prefixKey = Key('prefix');
    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(width: 8.0, height: 8.0, key: prefixKey),
          ),
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 48dps because the prefix icon's minimum size
     // is 48x48 and the rest of the elements only require 40dps:
     //   12 - top padding
     //   16 - input text (ahem font size 16dps)
     //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 48.0));
    expect(tester.getSize(find.byKey(prefixKey)).height, 16.0);
    expect(tester.getTopLeft(find.byKey(prefixKey)).dy, 16.0);
  });

  testWidgets('prefix/suffix icons increase height of decoration when larger than 48 by 48', (WidgetTester tester) async {
    const Key prefixKey = Key('prefix');
    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration(
          prefixIcon: SizedBox(width: 100.0, height: 100.0, key: prefixKey),
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 100dps because the prefix icon's  size
    // is 100x100 and the rest of the elements only require 40dps:
     //   12 - top padding
     //   16 - input text (ahem font size 16dps)
     //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 100.0));
    expect(tester.getSize(find.byKey(prefixKey)).height, 100.0);
    expect(tester.getTopLeft(find.byKey(prefixKey)).dy, 0.0);
  });

  group('textAlignVertical position', () {
    group('simple case', () {
      testWidgets('align top (default)', (WidgetTester tester) async {
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            expands: true, // so we have a tall input where align can vary
            decoration: const InputDecoration(
              filled: true,
            ),
            textAlignVertical: TextAlignVertical.top, // default when no border
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // Same as the default case above.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(12.0, .0001));
      });

      testWidgets('align center', (WidgetTester tester) async {
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            expands: true,
            decoration: const InputDecoration(
              filled: true,
            ),
            textAlignVertical: TextAlignVertical.center,
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // Below the top aligned case.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(290.0, .0001));
      });

      testWidgets('align bottom', (WidgetTester tester) async {
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            expands: true,
            decoration: const InputDecoration(
              filled: true,
            ),
            textAlignVertical: TextAlignVertical.bottom,
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // Below the center aligned case.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(568.0, .0001));
      });

      testWidgets('align as a double', (WidgetTester tester) async {
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            expands: true,
            decoration: const InputDecoration(
              filled: true,
            ),
            textAlignVertical: const TextAlignVertical(y: 0.75),
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // In between the center and bottom aligned cases.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(498.5, .0001));
      });
    });

    group('outline border', () {
      testWidgets('align top', (WidgetTester tester) async {
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            expands: true, // so we have a tall input where align can vary
            decoration: const InputDecoration(
              filled: true,
              border: OutlineInputBorder(),
            ),
            textAlignVertical: TextAlignVertical.top,
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // Similar to the case without a border, but with a little extra room at
        // the top to make room for the border.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(24.0, .0001));
      });

      testWidgets('align center (default)', (WidgetTester tester) async {
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            expands: true,
            decoration: const InputDecoration(
              filled: true,
              border: OutlineInputBorder(),
            ),
            textAlignVertical: TextAlignVertical.center, // default when border
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // Below the top aligned case.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(289.0, .0001));
      });

      testWidgets('align bottom', (WidgetTester tester) async {
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            expands: true,
            decoration: const InputDecoration(
              filled: true,
              border: OutlineInputBorder(),
            ),
            textAlignVertical: TextAlignVertical.bottom,
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // Below the center aligned case.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(564.0, .0001));
      });
    });

    group('prefix', () {
      testWidgets('InputDecorator tall prefix align top', (WidgetTester tester) async {
        const Key pKey = Key('p');
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            decoration: InputDecoration(
              prefix: Container(
                key: pKey,
                height: 100,
                width: 10,
              ),
              filled: true,
            ),
            textAlignVertical: TextAlignVertical.top, // default when no border
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // Same as the default case above.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(96, .0001));
        expect(tester.getTopLeft(find.byKey(pKey)).dy, 12.0);
      });

      testWidgets('InputDecorator tall prefix align center', (WidgetTester tester) async {
        const Key pKey = Key('p');
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            decoration: InputDecoration(
              prefix: Container(
                key: pKey,
                height: 100,
                width: 10,
              ),
              filled: true,
            ),
            textAlignVertical: TextAlignVertical.center,
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // Same as the default case above.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(96.0, .0001));
        expect(tester.getTopLeft(find.byKey(pKey)).dy, 12.0);
      });

      testWidgets('InputDecorator tall prefix align bottom', (WidgetTester tester) async {
        const Key pKey = Key('p');
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            decoration: InputDecoration(
              prefix: Container(
                key: pKey,
                height: 100,
                width: 10,
              ),
              filled: true,
            ),
            textAlignVertical: TextAlignVertical.bottom,
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // Top of the input + 100 prefix height - overlap
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(96.0, .0001));
        expect(tester.getTopLeft(find.byKey(pKey)).dy, 12.0);
      });
    });

    group('outline border and prefix', () {
      testWidgets('InputDecorator tall prefix align center', (WidgetTester tester) async {
        const Key pKey = Key('p');
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            expands: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              prefix: Container(
                key: pKey,
                height: 100,
                width: 10,
              ),
              filled: true,
            ),
            textAlignVertical: TextAlignVertical.center, // default when border
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // In the middle of the expanded InputDecorator.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(331.0, .0001));
        expect(tester.getTopLeft(find.byKey(pKey)).dy, closeTo(247.0, .0001));
      });

      testWidgets('InputDecorator tall prefix with border align top', (WidgetTester tester) async {
        const Key pKey = Key('p');
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            expands: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              prefix: Container(
                key: pKey,
                height: 100,
                width: 10,
              ),
              filled: true,
            ),
            textAlignVertical: TextAlignVertical.top,
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // Above the center example.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(108.0, .0001));
        // The prefix is positioned at the top of the input, so this value is
        // the same as the top aligned test without a prefix.
        expect(tester.getTopLeft(find.byKey(pKey)).dy, 24.0);
      });

      testWidgets('InputDecorator tall prefix with border align bottom', (WidgetTester tester) async {
        const Key pKey = Key('p');
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            expands: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              prefix: Container(
                key: pKey,
                height: 100,
                width: 10,
              ),
              filled: true,
            ),
            textAlignVertical: TextAlignVertical.bottom,
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // Below the center example.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(564.0, .0001));
        expect(tester.getTopLeft(find.byKey(pKey)).dy, closeTo(480.0, .0001));
      });

      testWidgets('InputDecorator tall prefix with border align double', (WidgetTester tester) async {
        const Key pKey = Key('p');
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            expands: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              prefix: Container(
                key: pKey,
                height: 100,
                width: 10,
              ),
              filled: true,
            ),
            textAlignVertical: const TextAlignVertical(y: 0.1),
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // Between the top and center examples.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(354.3, .0001));
        expect(tester.getTopLeft(find.byKey(pKey)).dy, closeTo(270.3, .0001));
      });
    });

    group('label', () {
      testWidgets('align top (default)', (WidgetTester tester) async {
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            expands: true, // so we have a tall input where align can vary
            decoration: const InputDecoration(
              labelText: 'label',
              filled: true,
            ),
            textAlignVertical: TextAlignVertical.top, // default
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // The label causes the text to start slightly lower than it would
        // otherwise.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(28.0, .0001));
      });

      testWidgets('align center', (WidgetTester tester) async {
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            expands: true, // so we have a tall input where align can vary
            decoration: const InputDecoration(
              labelText: 'label',
              filled: true,
            ),
            textAlignVertical: TextAlignVertical.center,
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // The label reduces the amount of space available for text, so the
        // center is slightly lower.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(298.0, .0001));
      });

      testWidgets('align bottom', (WidgetTester tester) async {
        const String text = 'text';
        await tester.pumpWidget(
          buildInputDecorator(
            // isEmpty: false (default)
            // isFocused: false (default)
            expands: true, // so we have a tall input where align can vary
            decoration: const InputDecoration(
              labelText: 'label',
              filled: true,
            ),
            textAlignVertical: TextAlignVertical.bottom,
            // Set the fontSize so that everything works out to whole numbers.
            child: const Text(
              text,
              style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0),
            ),
          ),
        );

        // The label reduces the amount of space available for text, but the
        // bottom line is still in the same place.
        expect(tester.getTopLeft(find.text(text)).dy, closeTo(568.0, .0001));
      });
    });
  });

  group('OutlineInputBorder', () {
    group('default alignment', () {
      testWidgets('Centers when border', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildInputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        );

        expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
        expect(tester.getTopLeft(find.text('text')).dy, 19.0);
        expect(tester.getBottomLeft(find.text('text')).dy, 35.0);
        expect(getBorderBottom(tester), 56.0);
        expect(getBorderWeight(tester), 1.0);
      });

      testWidgets('Centers when border and label', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildInputDecorator(
            decoration: const InputDecoration(
              labelText: 'label',
              border: OutlineInputBorder(),
            ),
          ),
        );

        expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
        expect(tester.getTopLeft(find.text('text')).dy, 19.0);
        expect(tester.getBottomLeft(find.text('text')).dy, 35.0);
        expect(getBorderBottom(tester), 56.0);
        expect(getBorderWeight(tester), 1.0);
      });

      testWidgets('Centers when border and contentPadding', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildInputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.fromLTRB(
                12.0, 14.0,
                8.0, 14.0,
              ),
            ),
          ),
        );

        expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 48.0));
        expect(tester.getTopLeft(find.text('text')).dy, 15.0);
        expect(tester.getBottomLeft(find.text('text')).dy, 31.0);
        expect(getBorderBottom(tester), 48.0);
        expect(getBorderWeight(tester), 1.0);
      });

      testWidgets('Centers when border and contentPadding and label', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildInputDecorator(
            decoration: const InputDecoration(
              labelText: 'label',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.fromLTRB(
                12.0, 14.0,
                8.0, 14.0,
              ),
            ),
          ),
        );

        expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, kMinInteractiveDimension));
        expect(tester.getTopLeft(find.text('text')).dy, 15.0);
        expect(tester.getBottomLeft(find.text('text')).dy, 31.0);
        expect(getBorderBottom(tester), 48.0);
        expect(getBorderWeight(tester), 1.0);
      });

      testWidgets('Centers when border and lopsided contentPadding and label', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildInputDecorator(
            decoration: const InputDecoration(
              labelText: 'label',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.fromLTRB(
                12.0, 104.0,
                8.0, 0.0,
              ),
            ),
          ),
        );

        expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 120.0));
        expect(tester.getTopLeft(find.text('text')).dy, 51.0);
        expect(tester.getBottomLeft(find.text('text')).dy, 67.0);
        expect(getBorderBottom(tester), 120.0);
        expect(getBorderWeight(tester), 1.0);
      });
    });

    group('3 point interpolation alignment', () {
      testWidgets('top align includes padding', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildInputDecorator(
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.fromLTRB(
                12.0, 24.0,
                8.0, 2.0,
              ),
            ),
          ),
        );

        expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 600.0));
        // Aligned to the top including the 24px padding.
        expect(tester.getTopLeft(find.text('text')).dy, 24.0);
        expect(tester.getBottomLeft(find.text('text')).dy, 40.0);
        expect(getBorderBottom(tester), 600.0);
        expect(getBorderWeight(tester), 1.0);
      });

      testWidgets('center align ignores padding', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildInputDecorator(
            expands: true,
            textAlignVertical: TextAlignVertical.center,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.fromLTRB(
                12.0, 24.0,
                8.0, 2.0,
              ),
            ),
          ),
        );

        expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 600.0));
        // Baseline is on the center of the 600px high input.
        expect(tester.getTopLeft(find.text('text')).dy, 291.0);
        expect(tester.getBottomLeft(find.text('text')).dy, 307.0);
        expect(getBorderBottom(tester), 600.0);
        expect(getBorderWeight(tester), 1.0);
      });

      testWidgets('bottom align includes padding', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildInputDecorator(
            expands: true,
            textAlignVertical: TextAlignVertical.bottom,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.fromLTRB(
                12.0, 24.0,
                8.0, 2.0,
              ),
            ),
          ),
        );

        expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 600.0));
        // Includes bottom padding of 2px.
        expect(tester.getTopLeft(find.text('text')).dy, 582.0);
        expect(tester.getBottomLeft(find.text('text')).dy, 598.0);
        expect(getBorderBottom(tester), 600.0);
        expect(getBorderWeight(tester), 1.0);
      });

      testWidgets('padding exceeds middle keeps top at middle', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildInputDecorator(
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.fromLTRB(
                12.0, 504.0,
                8.0, 0.0,
              ),
            ),
          ),
        );

        expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 600.0));
        // Same position as the center example above.
        expect(tester.getTopLeft(find.text('text')).dy, 291.0);
        expect(tester.getBottomLeft(find.text('text')).dy, 307.0);
        expect(getBorderBottom(tester), 600.0);
        expect(getBorderWeight(tester), 1.0);
      });
    });
  });

  testWidgets('counter text has correct right margin - LTR, not dense', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          counterText: 'test',
          filled: true,
        ),
      ),
    );

    // Margin for text decoration is 12 when filled
    // (dx) - 12 = (text offset)x.
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 68.0));
    final double dx = tester.getRect(find.byType(InputDecorator)).right;
    expect(tester.getRect(find.text('test')).right, dx - 12.0);
  });

  testWidgets('counter text has correct right margin - RTL, not dense', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        textDirection: TextDirection.rtl,
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          counterText: 'test',
          filled: true,
        ),
      ),
    );

    // Margin for text decoration is 12 when filled and top left offset is (0, 0)
    // 0 + 12 = 12.
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 68.0));
    expect(tester.getRect(find.text('test')).left, 12.0);
  });

  testWidgets('counter text has correct right margin - LTR, dense', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          counterText: 'test',
          filled: true,
          isDense: true,
        ),
      ),
    );

    // Margin for text decoration is 12 when filled
    // (dx) - 12 = (text offset)x.
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 52.0));
    final double dx = tester.getRect(find.byType(InputDecorator)).right;
    expect(tester.getRect(find.text('test')).right, dx - 12.0);
  });

  testWidgets('counter text has correct right margin - RTL, dense', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        textDirection: TextDirection.rtl,
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          counterText: 'test',
          filled: true,
          isDense: true,
        ),
      ),
    );

    // Margin for text decoration is 12 when filled and top left offset is (0, 0)
    // 0 + 12 = 12.
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 52.0));
    expect(tester.getRect(find.text('test')).left, 12.0);
  });

  testWidgets('InputDecorator error/helper/counter RTL layout', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        textDirection: TextDirection.rtl,
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: 'helper',
          counterText: 'counter',
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 76dps:
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding
    //    8 - below the border padding
    //   12 - [counter helper/error] (ahem font size 12dps)

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 76.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);
    expect(tester.getTopLeft(find.text('counter')), const Offset(12.0, 64.0));
    expect(tester.getTopRight(find.text('helper')), const Offset(788.0, 64.0));

    // If both error and helper are specified, show the error
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        textDirection: TextDirection.rtl,
        decoration: const InputDecoration(
          labelText: 'label',
          helperText: 'helper',
          errorText: 'error',
          counterText: 'counter',
          filled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('counter')), const Offset(12.0, 64.0));
    expect(tester.getTopRight(find.text('error')), const Offset(788.0, 64.0));
    expect(find.text('helper'), findsNothing);
  });

  testWidgets('InputDecorator prefix/suffix RTL', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        textDirection: TextDirection.rtl,
        decoration: const InputDecoration(
          prefixText: 'p',
          suffixText: 's',
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 40dps:
    //   12 - top padding
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, kMinInteractiveDimension)); // 40 bumped up to minimum.
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getSize(find.text('p')).height, 16.0);
    expect(tester.getSize(find.text('s')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 16.0);
    expect(tester.getTopLeft(find.text('p')).dy, 16.0);
    expect(tester.getTopLeft(find.text('s')).dy, 16.0);

    // layout is a row: [s text p]
    expect(tester.getTopLeft(find.text('s')).dx, 12.0);
    expect(tester.getTopRight(find.text('s')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('text')).dx));
    expect(tester.getTopRight(find.text('text')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('p')).dx));
  });

  testWidgets('InputDecorator contentPadding RTL layout', (WidgetTester tester) async {
    // LTR: content left edge is contentPadding.start: 40.0
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        textDirection: TextDirection.ltr,
        decoration: const InputDecoration(
          contentPadding: EdgeInsetsDirectional.only(start: 40.0, top: 12.0, bottom: 12.0),
          labelText: 'label',
          hintText: 'hint',
          filled: true,
        ),
      ),
    );
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('text')).dx, 40.0);
    expect(tester.getTopLeft(find.text('label')).dx, 40.0);
    expect(tester.getTopLeft(find.text('hint')).dx, 40.0);

    // RTL: content right edge is 800 - contentPadding.start: 760.0.
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        isFocused: true, // label is floating, still adjusted for contentPadding
        textDirection: TextDirection.rtl,
        decoration: const InputDecoration(
          contentPadding: EdgeInsetsDirectional.only(start: 40.0, top: 12.0, bottom: 12.0),
          labelText: 'label',
          hintText: 'hint',
          filled: true,
        ),
      ),
    );
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopRight(find.text('text')).dx, 760.0);
    expect(tester.getTopRight(find.text('label')).dx, 760.0);
    expect(tester.getTopRight(find.text('hint')).dx, 760.0);
  });

  testWidgets('InputDecorator prefix/suffix dense layout', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        isFocused: true,
        decoration: const InputDecoration(
          isDense: true,
          prefixText: 'p',
          suffixText: 's',
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 32dps:
    //    8 - top padding
    //   16 - input text (ahem font size 16dps)
    //    8 - bottom padding
    //
    // The only difference from normal layout for this case is that the
    // padding above and below the prefix, input text, suffix, is 8 instead of 12.

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 32.0));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getSize(find.text('p')).height, 16.0);
    expect(tester.getSize(find.text('s')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 8.0);
    expect(tester.getTopLeft(find.text('p')).dy, 8.0);
    expect(tester.getTopLeft(find.text('p')).dx, 12.0);
    expect(tester.getTopLeft(find.text('s')).dy, 8.0);
    expect(tester.getTopRight(find.text('s')).dx, 788.0);

    // layout is a row: [p text s]
    expect(tester.getTopLeft(find.text('p')).dx, 12.0);
    expect(tester.getTopRight(find.text('p')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('text')).dx));
    expect(tester.getTopRight(find.text('text')).dx, lessThanOrEqualTo(tester.getTopLeft(find.text('s')).dx));

    expect(getBorderBottom(tester), 32.0);
    expect(getBorderWeight(tester), 2.0);
  });

  testWidgets('InputDecorator with empty InputDecoration', (WidgetTester tester) async {
    await tester.pumpWidget(buildInputDecorator());

    // Overall height for this InputDecorator is 40dps:
    //   12 - top padding
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, kMinInteractiveDimension)); // 40 bumped up to minimum.
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 16.0);
    expect(getBorderBottom(tester), kMinInteractiveDimension); // 40 bumped up to minimum.
    expect(getBorderWeight(tester), 1.0);
  }, skip: isBrowser);

  testWidgets('InputDecorator.collapsed', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default),
        // isFocused: false (default)
        decoration: const InputDecoration.collapsed(
          hintText: 'hint',
        ),
      ),
    );

    // Overall height for this InputDecorator is 16dps:
    //   16 - input text (ahem font size 16dps)

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, kMinInteractiveDimension)); // 16 bumped up to minimum.
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 16.0);
    expect(getOpacity(tester, 'hint'), 0.0);
    expect(getBorderWeight(tester), 0.0);

    // The hint should appear
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: true,
        decoration: const InputDecoration.collapsed(
          hintText: 'hint',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, kMinInteractiveDimension));
    expect(tester.getSize(find.text('text')).height, 16.0);
    expect(tester.getTopLeft(find.text('text')).dy, 16.0);
    expect(tester.getSize(find.text('hint')).height, 16.0);
    expect(tester.getTopLeft(find.text('hint')).dy, 16.0);
    expect(getBorderWeight(tester), 0.0);
  }, skip: isBrowser);

  testWidgets('InputDecorator with baseStyle', (WidgetTester tester) async {
    // Setting the baseStyle of the InputDecoration and the style of the input
    // text child to a smaller font reduces the InputDecoration's vertical size.
    const TextStyle style = TextStyle(fontFamily: 'Ahem', fontSize: 10.0);
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true,
        isFocused: false,
        baseStyle: style,
        decoration: const InputDecoration(
          hintText: 'hint',
          labelText: 'label',
        ),
        child: const Text('text', style: style),
      ),
    );

    // Overall height for this InputDecorator is 45.5dps. When the label is
    // floating the layout is:
    //
    //    12  - top padding
    //    7.5 - floating label (ahem font size 10dps * 0.75 = 7.5)
    //    4   - floating label / input text gap
    //   10   - input text (ahem font size 10dps)
    //   12   - bottom padding
    //
    // When the label is not floating, it's vertically centered.
    //
    //   17.75 - top padding
    //      10 - label (ahem font size 10dps)
    //   17.75 - bottom padding (empty input text still appears here)

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, kMinInteractiveDimension)); // 45.5 bumped up to minimum.
    expect(tester.getSize(find.text('hint')).height, 10.0);
    expect(tester.getSize(find.text('label')).height, 10.0);
    expect(tester.getSize(find.text('text')).height, 10.0);
    expect(tester.getTopLeft(find.text('hint')).dy, 24.75);
    expect(tester.getTopLeft(find.text('label')).dy, 19.0);
    expect(tester.getTopLeft(find.text('text')).dy, 24.75);
  }, skip: isBrowser);

  testWidgets('InputDecorator with empty style overrides', (WidgetTester tester) async {
    // Same as not specifying any style overrides
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
          helperText: 'helper',
          counterText: 'counter',
          labelStyle: TextStyle(),
          hintStyle: TextStyle(),
          errorStyle: TextStyle(),
          helperStyle: TextStyle(),
          filled: true,
        ),
      ),
    );

    // Overall height for this InputDecorator is 76dps. When the label is
    // floating the layout is:
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding
    //    8 - below the border padding
    //   12 - help/error/counter text (ahem font size 12dps)

    // Label is floating because isEmpty is false.
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 76.0));
    expect(tester.getTopLeft(find.text('text')).dy, 28.0);
    expect(tester.getBottomLeft(find.text('text')).dy, 44.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);
    expect(tester.getTopLeft(find.text('helper')), const Offset(12.0, 64.0));
    expect(tester.getTopRight(find.text('counter')), const Offset(788.0, 64.0));
  }, skip: isBrowser);

  testWidgets('InputDecoration outline shape with no border and no floating placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isFocused: false (default)
        isEmpty: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          hasFloatingPlaceholder: false,
          labelText: 'label',
        ),
      ),
    );

    // Overall height for this InputDecorator is 56dps. Layout is:
    //   20 - top padding
    //   16 - label (ahem font size 16dps)
    //   20 - bottom padding
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 0.0);
  });

  testWidgets('InputDecoration outline shape with no border and no floating placeholder not empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide.none),
          hasFloatingPlaceholder: false,
          labelText: 'label',
        ),
      ),
    );

    // Overall height for this InputDecorator is 56dps. Layout is:
    //   20 - top padding
    //   16 - label (ahem font size 16dps)
    //   20 - bottom padding
    //    expect(tester.widget<Text>(find.text('prefix')).style.color, prefixStyle.color);
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 0.0);

    // The label should not be seen.
    expect(getOpacity(tester, 'label'), 0.0);
  }, skip: isBrowser);

  test('InputDecorationTheme copyWith, ==, hashCode basics', () {
    expect(const InputDecorationTheme(), const InputDecorationTheme().copyWith());
    expect(const InputDecorationTheme().hashCode, const InputDecorationTheme().copyWith().hashCode);
  });

  test('InputDecorationTheme copyWith correctly copies and replaces values', () {
    const InputDecorationTheme original = InputDecorationTheme(
      focusColor: Colors.orange,
      fillColor: Colors.green,
    );
    final InputDecorationTheme copy = original.copyWith(
      focusColor: Colors.yellow,
      fillColor: Colors.blue,
    );

    expect(original.focusColor, Colors.orange);
    expect(original.fillColor, Colors.green);
    expect(copy.focusColor, Colors.yellow);
    expect(copy.fillColor, Colors.blue);
  });

  testWidgets('InputDecorationTheme outline border', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true, // label appears, vertically centered
        // isFocused: false (default)
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        decoration: const InputDecoration(
          labelText: 'label',
        ),
      ),
    );

    // Overall height for this InputDecorator is 56dps. Layout is:
    //   20 - top padding
    //   16 - label (ahem font size 16dps)
    //   20 - bottom padding
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);
  }, skip: isBrowser);

  testWidgets('InputDecorationTheme outline border, dense layout', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true, // label appears, vertically centered
        // isFocused: false (default)
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
        ),
      ),
    );

    // Overall height for this InputDecorator is 56dps. Layout is:
    //   16 - top padding
    //   16 - label (ahem font size 16dps)
    //   16 - bottom padding
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 48.0));
    expect(tester.getTopLeft(find.text('label')).dy, 16.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 32.0);
    expect(getBorderBottom(tester), 48.0);
    expect(getBorderWeight(tester), 1.0);
  });

  testWidgets('InputDecorationTheme style overrides', (WidgetTester tester) async {
    const TextStyle style16 = TextStyle(fontFamily: 'Ahem', fontSize: 16.0);
    final TextStyle labelStyle = style16.merge(const TextStyle(color: Colors.red));
    final TextStyle hintStyle = style16.merge(const TextStyle(color: Colors.green));
    final TextStyle prefixStyle = style16.merge(const TextStyle(color: Colors.blue));
    final TextStyle suffixStyle = style16.merge(const TextStyle(color: Colors.purple));

    const TextStyle style12 = TextStyle(fontFamily: 'Ahem', fontSize: 12.0);
    final TextStyle helperStyle = style12.merge(const TextStyle(color: Colors.orange));
    final TextStyle counterStyle = style12.merge(const TextStyle(color: Colors.orange));

    // This test also verifies that the default InputDecorator provides a
    // "small concession to backwards compatibility" by not padding on
    // the left and right. If filled is true or an outline border is
    // provided then the horizontal padding is included.

    await tester.pumpWidget(
      buildInputDecorator(
        isEmpty: true, // label appears, vertically centered
        // isFocused: false (default)
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: labelStyle,
          hintStyle: hintStyle,
          prefixStyle: prefixStyle,
          suffixStyle: suffixStyle,
          helperStyle: helperStyle,
          counterStyle: counterStyle,
          // filled: false (default) - don't pad by left/right 12dps
        ),
        decoration: const InputDecoration(
          labelText: 'label',
          hintText: 'hint',
          prefixText: 'prefix',
          suffixText: 'suffix',
          helperText: 'helper',
          counterText: 'counter',
        ),
      ),
    );

    // Overall height for this InputDecorator is 76dps. Layout is:
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - prefix/hint/input/suffix text (ahem font size 16dps)
    //   12 - bottom padding
    //    8 - below the border padding
    //   12 - help/error/counter text (ahem font size 12dps)
    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 76.0));
    expect(tester.getTopLeft(find.text('label')).dy, 20.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 36.0);
    expect(getBorderBottom(tester), 56.0);
    expect(getBorderWeight(tester), 1.0);
    expect(tester.getTopLeft(find.text('helper')), const Offset(0.0, 64.0));
    expect(tester.getTopRight(find.text('counter')), const Offset(800.0, 64.0));

    // Verify that the styles were passed along
    expect(tester.widget<Text>(find.text('prefix')).style.color, prefixStyle.color);
    expect(tester.widget<Text>(find.text('suffix')).style.color, suffixStyle.color);
    expect(tester.widget<Text>(find.text('helper')).style.color, helperStyle.color);
    expect(tester.widget<Text>(find.text('counter')).style.color, counterStyle.color);

    TextStyle getLabelStyle() {
      return tester.firstWidget<AnimatedDefaultTextStyle>(
        find.ancestor(
          of: find.text('label'),
          matching: find.byType(AnimatedDefaultTextStyle),
        ),
      ).style;
    }
    expect(getLabelStyle().color, labelStyle.color);
  });

  testWidgets('InputDecorator.toString()', (WidgetTester tester) async {
    const Widget child = InputDecorator(
      key: Key('key'),
      decoration: InputDecoration(),
      baseStyle: TextStyle(),
      textAlign: TextAlign.center,
      isFocused: false,
      isEmpty: false,
      child: Placeholder(),
    );
    expect(
      child.toString(),
      "InputDecorator-[<'key'>](decoration: InputDecoration(), baseStyle: TextStyle(<all styles inherited>), isFocused: false, isEmpty: false)",
    );
  });

  testWidgets('InputDecorator.debugDescribeChildren', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration(
          icon: Text('icon'),
          labelText: 'label',
          hintText: 'hint',
          prefixText: 'prefix',
          suffixText: 'suffix',
          prefixIcon: Text('prefixIcon'),
          suffixIcon: Text('suffixIcon'),
          helperText: 'helper',
          counterText: 'counter',
        ),
        child: const Text('text'),
      ),
    );

    final RenderObject renderer = tester.renderObject(find.byType(InputDecorator));
    final Iterable<String> nodeNames = renderer.debugDescribeChildren()
      .map((DiagnosticsNode node) => node.name);
    expect(nodeNames, unorderedEquals(<String>[
      'container',
      'counter',
      'helperError',
      'hint',
      'icon',
      'input',
      'label',
      'prefix',
      'prefixIcon',
      'suffix',
      'suffixIcon',
    ]));

    final Set<Object> nodeValues = Set<Object>.from(
      renderer.debugDescribeChildren().map<Object>((DiagnosticsNode node) => node.value)
    );
    expect(nodeValues.length, 11);
  });

  testWidgets('InputDecorator with empty border and label', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/14165
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          labelText: 'label',
          border: InputBorder.none,
        ),
      ),
    );

    expect(tester.getSize(find.byType(InputDecorator)), const Size(800.0, 56.0));
    expect(getBorderWeight(tester), 0.0);
    expect(tester.getTopLeft(find.text('label')).dy, 12.0);
    expect(tester.getBottomLeft(find.text('label')).dy, 24.0);
  });

  testWidgets('InputDecorationTheme.inputDecoration', (WidgetTester tester) async {
    const TextStyle themeStyle = TextStyle(color: Colors.green);
    const TextStyle decorationStyle = TextStyle(color: Colors.blue);

    // InputDecorationTheme arguments define InputDecoration properties.
    InputDecoration decoration = const InputDecoration().applyDefaults(
      const InputDecorationTheme(
        labelStyle: themeStyle,
        helperStyle: themeStyle,
        hintStyle: themeStyle,
        errorStyle: themeStyle,
        isDense: true,
        contentPadding: EdgeInsets.all(1.0),
        prefixStyle: themeStyle,
        suffixStyle: themeStyle,
        counterStyle: themeStyle,
        filled: true,
        fillColor: Colors.red,
        focusColor: Colors.blue,
        border: InputBorder.none,
        alignLabelWithHint: true,
      ),
    );

    expect(decoration.labelStyle, themeStyle);
    expect(decoration.helperStyle, themeStyle);
    expect(decoration.hintStyle, themeStyle);
    expect(decoration.errorStyle, themeStyle);
    expect(decoration.isDense, true);
    expect(decoration.contentPadding, const EdgeInsets.all(1.0));
    expect(decoration.prefixStyle, themeStyle);
    expect(decoration.suffixStyle, themeStyle);
    expect(decoration.counterStyle, themeStyle);
    expect(decoration.filled, true);
    expect(decoration.fillColor, Colors.red);
    expect(decoration.border, InputBorder.none);
    expect(decoration.alignLabelWithHint, true);

    // InputDecoration (baseDecoration) defines InputDecoration properties
    decoration = const InputDecoration(
      labelStyle: decorationStyle,
      helperStyle: decorationStyle,
      hintStyle: decorationStyle,
      errorStyle: decorationStyle,
      isDense: false,
      contentPadding: EdgeInsets.all(4.0),
      prefixStyle: decorationStyle,
      suffixStyle: decorationStyle,
      counterStyle: decorationStyle,
      filled: false,
      fillColor: Colors.blue,
      border: OutlineInputBorder(),
      alignLabelWithHint: false,
    ).applyDefaults(
      const InputDecorationTheme(
        labelStyle: themeStyle,
        helperStyle: themeStyle,
        helperMaxLines: 5,
        hintStyle: themeStyle,
        errorStyle: themeStyle,
        errorMaxLines: 4,
        isDense: true,
        contentPadding: EdgeInsets.all(1.0),
        prefixStyle: themeStyle,
        suffixStyle: themeStyle,
        counterStyle: themeStyle,
        filled: true,
        fillColor: Colors.red,
        focusColor: Colors.blue,
        border: InputBorder.none,
        alignLabelWithHint: true,
      ),
    );

    expect(decoration.labelStyle, decorationStyle);
    expect(decoration.helperStyle, decorationStyle);
    expect(decoration.helperMaxLines, 5);
    expect(decoration.hintStyle, decorationStyle);
    expect(decoration.errorStyle, decorationStyle);
    expect(decoration.errorMaxLines, 4);
    expect(decoration.isDense, false);
    expect(decoration.contentPadding, const EdgeInsets.all(4.0));
    expect(decoration.prefixStyle, decorationStyle);
    expect(decoration.suffixStyle, decorationStyle);
    expect(decoration.counterStyle, decorationStyle);
    expect(decoration.filled, false);
    expect(decoration.fillColor, Colors.blue);
    expect(decoration.border, const OutlineInputBorder());
    expect(decoration.alignLabelWithHint, false);
  });

  testWidgets('InputDecorator OutlineInputBorder fillColor is clipped by border', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/15742

    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF00FF00),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(InputDecorator));

    // Fill is the border's outer path, a rounded rectangle
    expect(box, paints..path(
      style: PaintingStyle.fill,
      color: const Color(0xFF00FF00),
      includes: <Offset>[const Offset(800.0/2.0, 56/2.0)],
      excludes: <Offset>[
        const Offset(1.0, 6.0), // outside the rounded corner, top left
        const Offset(800.0 - 1.0, 6.0), // top right
        const Offset(1.0, 56.0 - 6.0), // bottom left
        const Offset(800 - 1.0, 56.0 - 6.0), // bottom right
      ],
    ));

    // Border outline. The rrect is the -center- of the 1.0 stroked outline.
    expect(box, paints..rrect(
      style: PaintingStyle.stroke,
      strokeWidth: 1.0,
      rrect: RRect.fromLTRBR(0.5, 0.5, 799.5, 55.5, const Radius.circular(11.5)),
    ));
  });

  testWidgets('InputDecorator UnderlineInputBorder fillColor is clipped by border', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildInputDecorator(
        // isEmpty: false (default)
        // isFocused: false (default)
        decoration: const InputDecoration(
          filled: true,
          fillColor: Color(0xFF00FF00),
          border: UnderlineInputBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12.0),
              bottomRight: Radius.circular(12.0),
            ),
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(InputDecorator));

    // Fill is the border's outer path, a rounded rectangle
    expect(box, paints..path(
      style: PaintingStyle.fill,
      color: const Color(0xFF00FF00),
      includes: <Offset>[const Offset(800.0/2.0, 56/2.0)],
      excludes: <Offset>[
        const Offset(1.0, 56.0 - 6.0), // bottom left
        const Offset(800 - 1.0, 56.0 - 6.0), // bottom right
      ],
    ));
  });

  testWidgets('InputDecorator constrained to 0x0', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/17710
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: UnconstrainedBox(child: ConstrainedBox(
            constraints: BoxConstraints.tight(Size.zero),
            child: const InputDecorator(
              decoration: InputDecoration(
                labelText: 'XP',
                border: OutlineInputBorder(),
              ),
            ),
          )),
        ),
      ),
    );
  });

  testWidgets(
    'InputDecorator OutlineBorder focused label with icon',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/18111

      Widget buildFrame(TextDirection textDirection) {
        return MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.center,
              child: Directionality(
                textDirection: textDirection,
                child: const RepaintBoundary(
                  child: InputDecorator(
                    isFocused: true,
                    isEmpty: true,
                    decoration: InputDecoration(
                      icon: Icon(Icons.insert_link),
                      labelText: 'primaryLink',
                      hintText: 'Primary link to story',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildFrame(TextDirection.ltr));
      await expectLater(
        find.byType(InputDecorator),
        matchesGoldenFile('input_decorator.outline_icon_label.ltr.png'),
      );

      await tester.pumpWidget(buildFrame(TextDirection.rtl));
      await expectLater(
        find.byType(InputDecorator),
        matchesGoldenFile('input_decorator.outline_icon_label.rtl.png'),
      );
    },
  );

  testWidgets('InputDecorator draws and animates hoverColor', (WidgetTester tester) async {
    const Color fillColor = Color(0x0A000000);
    const Color hoverColor = Color(0xFF00FF00);
    const Color disabledColor = Color(0x05000000);
    const Color enabledBorderColor = Color(0x61000000);

    Future<void> pumpDecorator({bool hovering, bool enabled = true, bool filled = true}) async {
      return await tester.pumpWidget(
        buildInputDecorator(
          isHovering: hovering,
          decoration: InputDecoration(
            enabled: enabled,
            filled: filled,
            hoverColor: hoverColor,
            disabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: disabledColor)),
            border: const OutlineInputBorder(borderSide: BorderSide(color: enabledBorderColor)),
          ),
        ),
      );
    }

    // Test filled text field.
    await pumpDecorator(hovering: false);
    expect(getContainerColor(tester), equals(fillColor));
    await tester.pump(const Duration(seconds: 10));
    expect(getContainerColor(tester), equals(fillColor));

    await pumpDecorator(hovering: true);
    expect(getContainerColor(tester), equals(fillColor));
    await tester.pump(const Duration(milliseconds: 15));
    expect(getContainerColor(tester), equals(hoverColor));

    await pumpDecorator(hovering: false);
    expect(getContainerColor(tester), equals(hoverColor));
    await tester.pump(const Duration(milliseconds: 15));
    expect(getContainerColor(tester), equals(fillColor));

    await pumpDecorator(hovering: false, enabled: false);
    expect(getContainerColor(tester), equals(disabledColor));
    await tester.pump(const Duration(seconds: 10));
    expect(getContainerColor(tester), equals(disabledColor));

    await pumpDecorator(hovering: true, enabled: false);
    expect(getContainerColor(tester), equals(disabledColor));
    await tester.pump(const Duration(seconds: 10));
    expect(getContainerColor(tester), equals(disabledColor));

    // Test outline text field.
    const Color blendedHoverColor = Color(0x74004400);
    await pumpDecorator(hovering: false, filled: false);
    await tester.pumpAndSettle();
    expect(getBorderColor(tester), equals(enabledBorderColor));
    await tester.pump(const Duration(seconds: 10));
    expect(getBorderColor(tester), equals(enabledBorderColor));

    await pumpDecorator(hovering: true, filled: false);
    expect(getBorderColor(tester), equals(enabledBorderColor));
    await tester.pump(const Duration(milliseconds: 200));
    expect(getBorderColor(tester), equals(blendedHoverColor));

    await pumpDecorator(hovering: false, filled: false);
    expect(getBorderColor(tester), equals(blendedHoverColor));
    await tester.pump(const Duration(milliseconds: 200));
    expect(getBorderColor(tester), equals(enabledBorderColor));

    await pumpDecorator(hovering: false, filled: false, enabled: false);
    expect(getBorderColor(tester), equals(enabledBorderColor));
    await tester.pump(const Duration(milliseconds: 200));
    expect(getBorderColor(tester), equals(disabledColor));

    await pumpDecorator(hovering: true, filled: false, enabled: false);
    expect(getBorderColor(tester), equals(disabledColor));
    await tester.pump(const Duration(seconds: 10));
    expect(getBorderColor(tester), equals(disabledColor));
  });

  testWidgets('InputDecorator draws and animates focusColor', (WidgetTester tester) async {
    const Color focusColor = Color(0xFF0000FF);
    const Color disabledColor = Color(0x05000000);
    const Color enabledBorderColor = Color(0x61000000);

    Future<void> pumpDecorator({bool focused, bool enabled = true, bool filled = true}) async {
      return await tester.pumpWidget(
        buildInputDecorator(
          isFocused: focused,
          decoration: InputDecoration(
            enabled: enabled,
            filled: filled,
            focusColor: focusColor,
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: focusColor)),
            disabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: disabledColor)),
            border: const OutlineInputBorder(borderSide: BorderSide(color: enabledBorderColor)),
          ),
        ),
      );
    }

    // Test outline text field default border.
    await pumpDecorator(focused: false, filled: false);
    await tester.pumpAndSettle();
    expect(getBorderColor(tester), equals(enabledBorderColor));
    await tester.pump(const Duration(seconds: 10));
    expect(getBorderColor(tester), equals(enabledBorderColor));

    await pumpDecorator(focused: true, filled: false);
    expect(getBorderColor(tester), equals(enabledBorderColor));
    await tester.pump(const Duration(milliseconds: 200));
    expect(getBorderColor(tester), equals(focusColor));

    await pumpDecorator(focused: false, filled: false);
    expect(getBorderColor(tester), equals(focusColor));
    await tester.pump(const Duration(milliseconds: 200));
    expect(getBorderColor(tester), equals(enabledBorderColor));

    await pumpDecorator(focused: false, filled: false, enabled: false);
    expect(getBorderColor(tester), equals(enabledBorderColor));
    await tester.pump(const Duration(milliseconds: 200));
    expect(getBorderColor(tester), equals(disabledColor));

    await pumpDecorator(focused: true, filled: false, enabled: false);
    expect(getBorderColor(tester), equals(disabledColor));
    await tester.pump(const Duration(seconds: 10));
    expect(getBorderColor(tester), equals(disabledColor));
  });

  testWidgets('InputDecorationTheme.toString()', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/19305
    expect(
      const InputDecorationTheme(
        contentPadding: EdgeInsetsDirectional.only(start: 5.0),
      ).toString(),
      contains('contentPadding: EdgeInsetsDirectional(5.0, 0.0, 0.0, 0.0)'),
    );

    // Regression test for https://github.com/flutter/flutter/issues/20374
    expect(
      const InputDecorationTheme(
        contentPadding: EdgeInsets.only(left: 5.0),
      ).toString(),
      contains('contentPadding: EdgeInsets(5.0, 0.0, 0.0, 0.0)'),
    );

    // Verify that the toString() method succeeds.
    final String debugString = const InputDecorationTheme(
      labelStyle: TextStyle(height: 1.0),
      helperStyle: TextStyle(height: 2.0),
      helperMaxLines: 5,
      hintStyle: TextStyle(height: 3.0),
      errorStyle: TextStyle(height: 4.0),
      errorMaxLines: 5,
      isDense: true,
      contentPadding: EdgeInsets.only(right: 6.0),
      isCollapsed: true,
      prefixStyle: TextStyle(height: 7.0),
      suffixStyle: TextStyle(height: 8.0),
      counterStyle: TextStyle(height: 9.0),
      filled: true,
      fillColor: Color(0x00000010),
      focusColor: Color(0x00000020),
      errorBorder: UnderlineInputBorder(),
      focusedBorder: OutlineInputBorder(),
      focusedErrorBorder: UnderlineInputBorder(),
      disabledBorder: OutlineInputBorder(),
      enabledBorder: UnderlineInputBorder(),
      border: OutlineInputBorder(),
    ).toString();

    // Spot check
    expect(debugString, contains('labelStyle: TextStyle(inherit: true, height: 1.0x)'));
    expect(debugString, contains('isDense: true'));
    expect(debugString, contains('fillColor: Color(0x00000010)'));
    expect(debugString, contains('focusColor: Color(0x00000020)'));
    expect(debugString, contains('errorBorder: UnderlineInputBorder()'));
    expect(debugString, contains('focusedBorder: OutlineInputBorder()'));
  });

  testWidgets('InputDecoration borders', (WidgetTester tester) async {
    const InputBorder errorBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 1.5),
    );
    const InputBorder focusedBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.green, width: 4.0),
    );
    const InputBorder focusedErrorBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.teal, width: 5.0),
    );
    const InputBorder disabledBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey, width: 0.0),
    );
    const InputBorder enabledBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue, width: 2.5),
    );

    await tester.pumpWidget(
      buildInputDecorator(
        // isFocused: false (default)
        decoration: const InputDecoration(
          // errorText: null (default)
          // enabled: true (default)
          errorBorder: errorBorder,
          focusedBorder: focusedBorder,
          focusedErrorBorder: focusedErrorBorder,
          disabledBorder: disabledBorder,
          enabledBorder: enabledBorder,
        ),
      ),
    );
    expect(getBorder(tester), enabledBorder);

    await tester.pumpWidget(
      buildInputDecorator(
        isFocused: true,
        decoration: const InputDecoration(
          // errorText: null (default)
          // enabled: true (default)
          errorBorder: errorBorder,
          focusedBorder: focusedBorder,
          focusedErrorBorder: focusedErrorBorder,
          disabledBorder: disabledBorder,
          enabledBorder: enabledBorder,
        ),
      ),
    );
    await tester.pumpAndSettle(); // border changes are animated
    expect(getBorder(tester), focusedBorder);

    await tester.pumpWidget(
      buildInputDecorator(
        isFocused: true,
        decoration: const InputDecoration(
          errorText: 'error',
          // enabled: true (default)
          errorBorder: errorBorder,
          focusedBorder: focusedBorder,
          focusedErrorBorder: focusedErrorBorder,
          disabledBorder: disabledBorder,
          enabledBorder: enabledBorder,
        ),
      ),
    );
    await tester.pumpAndSettle(); // border changes are animated
    expect(getBorder(tester), focusedErrorBorder);

    await tester.pumpWidget(
      buildInputDecorator(
        // isFocused: false (default)
        decoration: const InputDecoration(
          errorText: 'error',
          // enabled: true (default)
          errorBorder: errorBorder,
          focusedBorder: focusedBorder,
          focusedErrorBorder: focusedErrorBorder,
          disabledBorder: disabledBorder,
          enabledBorder: enabledBorder,
        ),
      ),
    );
    await tester.pumpAndSettle(); // border changes are animated
    expect(getBorder(tester), errorBorder);

    await tester.pumpWidget(
      buildInputDecorator(
        // isFocused: false (default)
        decoration: const InputDecoration(
          errorText: 'error',
          enabled: false,
          errorBorder: errorBorder,
          focusedBorder: focusedBorder,
          focusedErrorBorder: focusedErrorBorder,
          disabledBorder: disabledBorder,
          enabledBorder: enabledBorder,
        ),
      ),
    );
    await tester.pumpAndSettle(); // border changes are animated
    expect(getBorder(tester), errorBorder);

    await tester.pumpWidget(
      buildInputDecorator(
        // isFocused: false (default)
        decoration: const InputDecoration(
          // errorText: false (default)
          enabled: false,
          errorBorder: errorBorder,
          focusedBorder: focusedBorder,
          focusedErrorBorder: focusedErrorBorder,
          disabledBorder: disabledBorder,
          enabledBorder: enabledBorder,
        ),
      ),
    );
    await tester.pumpAndSettle(); // border changes are animated
    expect(getBorder(tester), disabledBorder);

    await tester.pumpWidget(
      buildInputDecorator(
        isFocused: true,
        decoration: const InputDecoration(
          // errorText: null (default)
          enabled: false,
          errorBorder: errorBorder,
          focusedBorder: focusedBorder,
          focusedErrorBorder: focusedErrorBorder,
          disabledBorder: disabledBorder,
          enabledBorder: enabledBorder,
        ),
      ),
    );
    await tester.pumpAndSettle(); // border changes are animated
    expect(getBorder(tester), disabledBorder);
  });

  testWidgets('OutlineInputBorder borders scale down to fit when large values are passed in', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/34327
    const double largerBorderRadius = 200.0;
    const double smallerBorderRadius = 100.0;

    // Overall height for this InputDecorator is 56dps:
    //   12 - top padding
    //   12 - floating label (ahem font size 16dps * 0.75 = 12)
    //    4 - floating label / input text gap
    //   16 - input text (ahem font size 16dps)
    //   12 - bottom padding
    const double inputDecoratorHeight = 56.0;
    const double inputDecoratorWidth = 800.0;

    await tester.pumpWidget(
      buildInputDecorator(
        decoration: const InputDecoration(
          filled: true,
          fillColor: Color(0xFF00FF00),
          labelText: 'label text',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.only(
              // Intentionally large values that are larger than the InputDecorator
              topLeft: Radius.circular(smallerBorderRadius),
              bottomLeft: Radius.circular(smallerBorderRadius),
              topRight: Radius.circular(largerBorderRadius),
              bottomRight: Radius.circular(largerBorderRadius),
            ),
          ),
        ),
      ),
    );

    // Skia determines the scale based on the ratios of radii to the total
    // height or width allowed. In this case, it is the right side of the
    // border, which have two corners with largerBorderRadius that add up
    // to be 400.0.
    const double denominator = largerBorderRadius * 2.0;

    const double largerBorderRadiusScaled = largerBorderRadius / denominator * inputDecoratorHeight;
    const double smallerBorderRadiusScaled = smallerBorderRadius / denominator * inputDecoratorHeight;

    expect(findBorderPainter(), paints
      ..save()
      ..path(
        style: PaintingStyle.fill,
        color: const Color(0xFF00FF00),
        includes: const <Offset>[
          // The border should draw along the four edges of the
          // InputDecorator.

          // Top center
          Offset(inputDecoratorWidth / 2.0, 0.0),
          // Bottom center
          Offset(inputDecoratorWidth / 2.0, inputDecoratorHeight),
          // Left center
          Offset(0.0, inputDecoratorHeight / 2.0),
          // Right center
          Offset(inputDecoratorWidth, inputDecoratorHeight / 2.0),

          // The border path should contain points where each rounded corner
          // ends.

          // Bottom-right arc
          Offset(inputDecoratorWidth, inputDecoratorHeight - largerBorderRadiusScaled),
          Offset(inputDecoratorWidth - largerBorderRadiusScaled, inputDecoratorHeight),
          // Top-right arc
          Offset(inputDecoratorWidth,0.0 + largerBorderRadiusScaled),
          Offset(inputDecoratorWidth - largerBorderRadiusScaled, 0.0),
          // Bottom-left arc
          Offset(0.0, inputDecoratorHeight - smallerBorderRadiusScaled),
          Offset(0.0 + smallerBorderRadiusScaled, inputDecoratorHeight),
          // Top-left arc
          Offset(0.0,0.0 + smallerBorderRadiusScaled),
          Offset(0.0 + smallerBorderRadiusScaled, 0.0),
        ],
        excludes: const <Offset>[
          // The border should not contain the corner points, since the border
          // is rounded.

          // Top-left
          Offset(0.0, 0.0),
          // Top-right
          Offset(inputDecoratorWidth, 0.0),
          // Bottom-left
          Offset(0.0, inputDecoratorHeight),
          // Bottom-right
          Offset(inputDecoratorWidth, inputDecoratorHeight),

          // Corners with larger border ratio should not contain points outside
          // of the larger radius.

          // Bottom-right arc
          Offset(inputDecoratorWidth, inputDecoratorHeight - smallerBorderRadiusScaled),
          Offset(inputDecoratorWidth - smallerBorderRadiusScaled, inputDecoratorWidth),
          // Top-left arc
          Offset(inputDecoratorWidth, 0.0 + smallerBorderRadiusScaled),
          Offset(inputDecoratorWidth - smallerBorderRadiusScaled, 0.0),
        ],
      )
      ..restore(),
    );
  });

  testWidgets('OutlineInputBorder radius carries over when lerping', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/23982
    const Key key = Key('textField');

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              key: key,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // TextField has the given border
    expect(getBorderRadius(tester), BorderRadius.zero);

    // Focusing does not change the border
    await tester.tap(find.byKey(key));
    await tester.pump();
    expect(getBorderRadius(tester), BorderRadius.zero);
    await tester.pump(const Duration(milliseconds: 100));
    expect(getBorderRadius(tester), BorderRadius.zero);
    await tester.pumpAndSettle();
    expect(getBorderRadius(tester), BorderRadius.zero);
  });

  testWidgets('OutlineInputBorder async lerp', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/28724

    final Completer<void> completer = Completer<void>();
    bool waitIsOver = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return GestureDetector(
              onTap: () async {
                setState(() { waitIsOver = true; });
                await completer.future;
                setState(() { waitIsOver = false;  });
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Test',
                  enabledBorder: !waitIsOver ? null : const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(StatefulBuilder));
    await tester.pumpAndSettle();

    completer.complete();
    await tester.pumpAndSettle();
  });

  test('InputBorder equality', () {
    // OutlineInputBorder's equality is defined by the borderRadius, borderSide, & gapPadding
    const OutlineInputBorder outlineInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(9.0)),
      borderSide: BorderSide(color: Colors.blue),
      gapPadding: 32.0,
    );
    expect(outlineInputBorder, const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue),
      borderRadius: BorderRadius.all(Radius.circular(9.0)),
      gapPadding: 32.0,
    ));
    expect(outlineInputBorder, isNot(const OutlineInputBorder()));

    // UnderlineInputBorder's equality is defined only by the borderSide
    const UnderlineInputBorder underlineInputBorder = UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue));
    expect(underlineInputBorder, const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)));
    expect(underlineInputBorder, isNot(const UnderlineInputBorder()));
  });


  test('InputBorder hashCodes', () {
    // OutlineInputBorder's hashCode is defined by the borderRadius, borderSide, & gapPadding
    const OutlineInputBorder outlineInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(9.0)),
      borderSide: BorderSide(color: Colors.blue),
      gapPadding: 32.0,
    );
    expect(outlineInputBorder.hashCode, const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(9.0)),
      borderSide: BorderSide(color: Colors.blue),
      gapPadding: 32.0,
    ).hashCode);
    expect(outlineInputBorder.hashCode, isNot(const OutlineInputBorder().hashCode));

    // UnderlineInputBorder's hashCode is defined only by the borderSide
    const UnderlineInputBorder underlineInputBorder = UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue));
    expect(underlineInputBorder.hashCode, const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)).hashCode);
    expect(underlineInputBorder.hashCode, isNot(const UnderlineInputBorder().hashCode));
  });

  testWidgets('InputDecorationTheme implements debugFillDescription', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const InputDecorationTheme(
      labelStyle: TextStyle(),
      helperStyle: TextStyle(),
      helperMaxLines: 6,
      hintStyle: TextStyle(),
      errorMaxLines: 5,
      hasFloatingPlaceholder: false,
      contentPadding: EdgeInsetsDirectional.only(start: 40.0, top: 12.0, bottom: 12.0),
      prefixStyle: TextStyle(),
      suffixStyle: TextStyle(),
      counterStyle: TextStyle(),
      filled: true,
      fillColor: Colors.red,
      focusColor: Colors.blue,
      errorBorder: UnderlineInputBorder(),
      focusedBorder: UnderlineInputBorder(),
      focusedErrorBorder: UnderlineInputBorder(),
      disabledBorder: UnderlineInputBorder(),
      enabledBorder: UnderlineInputBorder(),
      border: UnderlineInputBorder(),
      alignLabelWithHint: true,
    ).debugFillProperties(builder);
    final List<String> description = builder.properties
        .where((DiagnosticsNode n) => !n.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode n) => n.toString()).toList();
    expect(description, <String>[
      'labelStyle: TextStyle(<all styles inherited>)',
      'helperStyle: TextStyle(<all styles inherited>)',
      'helperMaxLines: 6',
      'hintStyle: TextStyle(<all styles inherited>)',
      'errorMaxLines: 5',
      'hasFloatingPlaceholder: false',
      'contentPadding: EdgeInsetsDirectional(40.0, 12.0, 0.0, 12.0)',
      'prefixStyle: TextStyle(<all styles inherited>)',
      'suffixStyle: TextStyle(<all styles inherited>)',
      'counterStyle: TextStyle(<all styles inherited>)',
      'filled: true',
      'fillColor: MaterialColor(primary value: Color(0xfff44336))',
      'focusColor: MaterialColor(primary value: Color(0xff2196f3))',
      'errorBorder: UnderlineInputBorder()',
      'focusedBorder: UnderlineInputBorder()',
      'focusedErrorBorder: UnderlineInputBorder()',
      'disabledBorder: UnderlineInputBorder()',
      'enabledBorder: UnderlineInputBorder()',
      'border: UnderlineInputBorder()',
      'alignLabelWithHint: true',
    ]);
  });

  testWidgets('uses alphabetic baseline for CJK layout', (WidgetTester tester) async {
    await tester.binding.setLocale('zh', 'CN');
    final Typography typography = Typography();

    final FocusNode focusNode = FocusNode();
    final TextEditingController controller = TextEditingController();
    // The dense theme uses ideographic baselines
    Widget buildFrame(bool alignLabelWithHint) {
      return MaterialApp(
        theme: ThemeData(
          textTheme: typography.dense,
        ),
        home: Material(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'label',
                alignLabelWithHint: alignLabelWithHint,
                hintText: 'hint',
                hintStyle: const TextStyle(
                  fontFamily: 'Cough',
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(true));
    await tester.pumpAndSettle();

    // These numbers should be the values from using alphabetic baselines:
    // Ideographic (incorrect) value is 31.299999713897705
    expect(tester.getTopLeft(find.text('hint')).dy, 28.75);

    // Ideographic (incorrect) value is 50.299999713897705
    expect(tester.getBottomLeft(find.text('hint')).dy, 47.75);
  });
}
