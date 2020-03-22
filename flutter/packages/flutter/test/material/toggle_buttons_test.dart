// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

const double _defaultBorderWidth = 1.0;

Widget boilerplate({Widget child}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  );
}

void main() {
  testWidgets('Initial toggle state is reflected', (WidgetTester tester) async {
    TextStyle buttonTextStyle(String text) {
      return tester.widget<DefaultTextStyle>(find.descendant(
        of: find.widgetWithText(RawMaterialButton, text),
        matching: find.byType(DefaultTextStyle),
      )).style;
    }
    final ThemeData theme = ThemeData();
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            onPressed: (int index) {},
            isSelected: const <bool>[false, true],
            children: const <Widget>[
              Text('First child'),
              Text('Second child'),
            ],
          ),
        ),
      ),
    );

    expect(
      buttonTextStyle('First child').color,
      theme.colorScheme.onSurface.withOpacity(0.87),
    );
    expect(
      buttonTextStyle('Second child').color,
      theme.colorScheme.primary,
    );
  });

  testWidgets(
    'onPressed is triggered on button tap',
    (WidgetTester tester) async {
      TextStyle buttonTextStyle(String text) {
        return tester.widget<DefaultTextStyle>(find.descendant(
          of: find.widgetWithText(RawMaterialButton, text),
          matching: find.byType(DefaultTextStyle),
        )).style;
      }

      final List<bool> _isSelected = <bool>[false, true];
      final ThemeData theme = ThemeData();
      await tester.pumpWidget(
        Material(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return boilerplate(
                child: ToggleButtons(
                  onPressed: (int index) {
                    setState(() {
                      _isSelected[index] = !_isSelected[index];
                    });
                  },
                  isSelected: _isSelected,
                  children: const <Widget>[
                    Text('First child'),
                    Text('Second child'),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(_isSelected[0], isFalse);
      expect(_isSelected[1], isTrue);
      expect(
        buttonTextStyle('First child').color,
        theme.colorScheme.onSurface.withOpacity(0.87),
      );
      expect(
        buttonTextStyle('Second child').color,
        theme.colorScheme.primary,
      );

      await tester.tap(find.text('Second child'));
      await tester.pumpAndSettle();

      expect(_isSelected[0], isFalse);
      expect(_isSelected[1], isFalse);
      expect(
        buttonTextStyle('First child').color,
        theme.colorScheme.onSurface.withOpacity(0.87),
      );
      expect(
        buttonTextStyle('Second child').color,
        theme.colorScheme.onSurface.withOpacity(0.87),
      );
    },
  );

  testWidgets(
    'onPressed that is null disables buttons',
    (WidgetTester tester) async {
      TextStyle buttonTextStyle(String text) {
        return tester.widget<DefaultTextStyle>(find.descendant(
          of: find.widgetWithText(RawMaterialButton, text),
          matching: find.byType(DefaultTextStyle),
        )).style;
      }
      final List<bool> _isSelected = <bool>[false, true];
      final ThemeData theme = ThemeData();

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: _isSelected,
              children: const <Widget>[
                Text('First child'),
                Text('Second child'),
              ],
            ),
          ),
        ),
      );

      expect(_isSelected[0], isFalse);
      expect(_isSelected[1], isTrue);
      expect(
        buttonTextStyle('First child').color,
        theme.colorScheme.onSurface.withOpacity(0.38),
      );
      expect(
        buttonTextStyle('Second child').color,
        theme.colorScheme.onSurface.withOpacity(0.38),
      );

      await tester.tap(find.text('Second child'));
      await tester.pumpAndSettle();

      // Nothing should change
      expect(_isSelected[0], isFalse);
      expect(_isSelected[1], isTrue);
      expect(
        buttonTextStyle('First child').color,
        theme.colorScheme.onSurface.withOpacity(0.38),
      );
      expect(
        buttonTextStyle('Second child').color,
        theme.colorScheme.onSurface.withOpacity(0.38),
      );
    },
  );

  testWidgets('children property cannot be null', (WidgetTester tester) async {
    try {
      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[false, true],
              onPressed: (int index) {},
              children: null,
            ),
          ),
        ),
      );
      fail('Should not be possible to create a toggle button with no children.');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('children != null'));
    }
  });

  testWidgets(
    'isSelected property cannot be null',
    (WidgetTester tester) async {
      try {
        await tester.pumpWidget(
          Material(
            child: boilerplate(
              child: ToggleButtons(
                isSelected: null,
                onPressed: (int index) {},
                children: const <Widget>[
                  Text('First child'),
                  Text('Second child'),
                ],
              ),
            ),
          ),
        );
        fail('Should not be possible to create a toggle button with no isSelected.');
      } on AssertionError catch (e) {
        expect(e.toString(), contains('isSelected != null'));
      }
    },
  );

  testWidgets(
    'children and isSelected properties have to be the same length',
    (WidgetTester tester) async {
      try {
        await tester.pumpWidget(
          Material(
            child: boilerplate(
              child: ToggleButtons(
                isSelected: const <bool>[false],
                children: const <Widget>[
                  Text('First child'),
                  Text('Second child'),
                ],
              ),
            ),
          ),
        );
        fail('Should not be possible to create a toggle button with mismatching'
            'children.length and isSelected.length.');
      } on AssertionError catch (e) {
        expect(e.toString(), contains('children.length'));
        expect(e.toString(), contains('isSelected.length'));
      }
    },
  );

  testWidgets('Default text style is applied', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[false, true],
            onPressed: (int index) {},
            children: const <Widget>[
              Text('First child'),
              Text('Second child'),
            ],
          ),
        ),
      ),
    );

    TextStyle textStyle;
    textStyle = tester.widget<DefaultTextStyle>(find.descendant(
        of: find.widgetWithText(RawMaterialButton, 'First child'),
        matching: find.byType(DefaultTextStyle),
    )).style;
    expect(textStyle.fontFamily, theme.textTheme.body1.fontFamily);
    expect(textStyle.decoration, theme.textTheme.body1.decoration);

    textStyle = tester.widget<DefaultTextStyle>(find.descendant(
        of: find.widgetWithText(RawMaterialButton, 'Second child'),
        matching: find.byType(DefaultTextStyle),
    )).style;
    expect(textStyle.fontFamily, theme.textTheme.body1.fontFamily);
    expect(textStyle.decoration, theme.textTheme.body1.decoration);
  });

  testWidgets('Custom text style except color is applied', (WidgetTester tester) async {
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[false, true],
            onPressed: (int index) {},
            textStyle: const TextStyle(
              textBaseline: TextBaseline.ideographic,
              fontSize: 20.0,
              color: Colors.orange,
            ),
            children: const <Widget>[
              Text('First child'),
              Text('Second child'),
            ],
          ),
        ),
      ),
    );

    TextStyle textStyle;
    textStyle = tester.widget<DefaultTextStyle>(find.descendant(
        of: find.widgetWithText(RawMaterialButton, 'First child'),
        matching: find.byType(DefaultTextStyle),
    )).style;
    expect(textStyle.textBaseline, TextBaseline.ideographic);
    expect(textStyle.fontSize, 20.0);
    expect(textStyle.color, isNot(Colors.orange));

    textStyle = tester.widget<DefaultTextStyle>(find.descendant(
        of: find.widgetWithText(RawMaterialButton, 'Second child'),
        matching: find.byType(DefaultTextStyle),
    )).style;
    expect(textStyle.textBaseline, TextBaseline.ideographic);
    expect(textStyle.fontSize, 20.0);
    expect(textStyle.color, isNot(Colors.orange));
  });

  testWidgets('Default BoxConstraints', (WidgetTester tester) async {
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[false, false, false],
            onPressed: (int index) {},
            children: const <Widget>[
              Icon(Icons.check),
              Icon(Icons.access_alarm),
              Icon(Icons.cake),
            ],
          ),
        ),
      ),
    );

    final Rect firstRect = tester.getRect(find.byType(RawMaterialButton).at(0));
    expect(firstRect.width, 48.0);
    expect(firstRect.height, 48.0);
    final Rect secondRect = tester.getRect(find.byType(RawMaterialButton).at(1));
    expect(secondRect.width, 48.0);
    expect(secondRect.height, 48.0);
    final Rect thirdRect = tester.getRect(find.byType(RawMaterialButton).at(2));
    expect(thirdRect.width, 48.0);
    expect(thirdRect.height, 48.0);
  });

  testWidgets('Custom BoxConstraints', (WidgetTester tester) async {
    // Test for minimum constraints
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            constraints: const BoxConstraints(
              minWidth: 50.0,
              minHeight: 60.0,
            ),
            isSelected: const <bool>[false, false, false],
            onPressed: (int index) {},
            children: const <Widget>[
              Icon(Icons.check),
              Icon(Icons.access_alarm),
              Icon(Icons.cake),
            ],
          ),
        ),
      ),
    );

    Rect firstRect = tester.getRect(find.byType(RawMaterialButton).at(0));
    expect(firstRect.width, 50.0);
    expect(firstRect.height, 60.0);
    Rect secondRect = tester.getRect(find.byType(RawMaterialButton).at(1));
    expect(secondRect.width, 50.0);
    expect(secondRect.height, 60.0);
    Rect thirdRect = tester.getRect(find.byType(RawMaterialButton).at(2));
    expect(thirdRect.width, 50.0);
    expect(thirdRect.height, 60.0);

    // Test for maximum constraints
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            constraints: const BoxConstraints(
              maxWidth: 20.0,
              maxHeight: 10.0,
            ),
            isSelected: const <bool>[false, false, false],
            onPressed: (int index) {},
            children: const <Widget>[
              Icon(Icons.check),
              Icon(Icons.access_alarm),
              Icon(Icons.cake),
            ],
          ),
        ),
      ),
    );

    firstRect = tester.getRect(find.byType(RawMaterialButton).at(0));
    expect(firstRect.width, 20.0);
    expect(firstRect.height, 10.0);
    secondRect = tester.getRect(find.byType(RawMaterialButton).at(1));
    expect(secondRect.width, 20.0);
    expect(secondRect.height, 10.0);
    thirdRect = tester.getRect(find.byType(RawMaterialButton).at(2));
    expect(thirdRect.width, 20.0);
    expect(thirdRect.height, 10.0);
  });

  testWidgets(
    'Default text/icon colors for enabled, selected and disabled states',
    (WidgetTester tester) async {
      TextStyle buttonTextStyle(String text) {
        return tester.widget<DefaultTextStyle>(find.descendant(
          of: find.widgetWithText(RawMaterialButton, text),
          matching: find.byType(DefaultTextStyle),
        )).style;
      }
      IconTheme iconTheme(IconData icon) {
        return tester.widget(find.descendant(
          of: find.widgetWithIcon(RawMaterialButton, icon),
          matching: find.byType(IconTheme),
        ));
      }
      final ThemeData theme = ThemeData();
      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[false],
              onPressed: (int index) {},
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );

      // Default enabled color
      expect(
        buttonTextStyle('First child').color,
        theme.colorScheme.onSurface.withOpacity(0.87),
      );
      expect(
        iconTheme(Icons.check).data.color,
        theme.colorScheme.onSurface.withOpacity(0.87),
      );

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[true],
              onPressed: (int index) {},
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Default selected color
      expect(
        buttonTextStyle('First child').color,
        theme.colorScheme.primary,
      );
      expect(
        iconTheme(Icons.check).data.color,
        theme.colorScheme.primary,
      );

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[true],
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Default disabled color
      expect(
        buttonTextStyle('First child').color,
        theme.colorScheme.onSurface.withOpacity(0.38),
      );
      expect(
        iconTheme(Icons.check).data.color,
        theme.colorScheme.onSurface.withOpacity(0.38),
      );
    },
  );

  testWidgets(
    'Custom text/icon colors for enabled, selected and disabled states',
    (WidgetTester tester) async {
      TextStyle buttonTextStyle(String text) {
        return tester.widget<DefaultTextStyle>(find.descendant(
          of: find.widgetWithText(RawMaterialButton, text),
          matching: find.byType(DefaultTextStyle),
        )).style;
      }
      IconTheme iconTheme(IconData icon) {
        return tester.widget(find.descendant(
          of: find.widgetWithIcon(RawMaterialButton, icon),
          matching: find.byType(IconTheme),
        ));
      }
      final ThemeData theme = ThemeData();
      const Color enabledColor = Colors.lime;
      const Color selectedColor = Colors.green;
      const Color disabledColor = Colors.yellow;

      // Tests are ineffective if the custom colors are the same as the theme's
      expect(theme.colorScheme.onSurface, isNot(enabledColor));
      expect(theme.colorScheme.primary, isNot(selectedColor));
      expect(theme.colorScheme.onSurface.withOpacity(0.38), isNot(disabledColor));

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              color: enabledColor,
              isSelected: const <bool>[false],
              onPressed: (int index) {},
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );

      // Custom enabled color
      expect(buttonTextStyle('First child').color, enabledColor);
      expect(iconTheme(Icons.check).data.color, enabledColor);

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              selectedColor: selectedColor,
              isSelected: const <bool>[true],
              onPressed: (int index) {},
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Custom selected color
      expect(buttonTextStyle('First child').color, selectedColor);
      expect(iconTheme(Icons.check).data.color, selectedColor);

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              disabledColor: disabledColor,
              isSelected: const <bool>[true],
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Custom disabled color
      expect(buttonTextStyle('First child').color, disabledColor);
      expect(iconTheme(Icons.check).data.color, disabledColor);
    },
  );

  testWidgets('Default button fillColor - unselected', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[false],
            onPressed: (int index) {},
            children: <Widget>[
              Row(children: const <Widget>[
                Text('First child'),
              ]),
            ],
          ),
        ),
      ),
    );

    final Material material = tester.widget<Material>(find.descendant(
      of: find.byType(RawMaterialButton),
      matching: find.byType(Material),
    ));
    expect(
      material.color,
      theme.colorScheme.surface.withOpacity(0.0),
    );
    expect(material.type, MaterialType.button);
  });

  testWidgets('Default button fillColor - selected', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[true],
            onPressed: (int index) {},
            children: <Widget>[
              Row(children: const <Widget>[
                Text('First child'),
              ]),
            ],
          ),
        ),
      ),
    );

    final Material material = tester.widget<Material>(find.descendant(
      of: find.byType(RawMaterialButton),
      matching: find.byType(Material),
    ));
    expect(
      material.color,
      theme.colorScheme.primary.withOpacity(0.12),
    );
    expect(material.type, MaterialType.button);
  });

  testWidgets('Default button fillColor - disabled', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[true],
            onPressed: null,
            children: <Widget>[
              Row(children: const <Widget>[
                Text('First child'),
              ]),
            ],
          ),
        ),
      ),
    );

    final Material material = tester.widget<Material>(find.descendant(
      of: find.byType(RawMaterialButton),
      matching: find.byType(Material),
    ));
    expect(
      material.color,
      theme.colorScheme.surface.withOpacity(0.0),
    );
    expect(material.type, MaterialType.button);
  });

  testWidgets('Custom button fillColor', (WidgetTester tester) async {
    const Color customFillColor = Colors.green;
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            fillColor: customFillColor,
            isSelected: const <bool>[true],
            onPressed: (int index) {},
            children: <Widget>[
              Row(children: const <Widget>[
                Text('First child'),
              ]),
            ],
          ),
        ),
      ),
    );

    final Material material = tester.widget<Material>(find.descendant(
      of: find.byType(RawMaterialButton),
      matching: find.byType(Material),
    ));
    expect(material.color, customFillColor);
    expect(material.type, MaterialType.button);
  });

  testWidgets('Default InkWell colors - unselected', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    final FocusNode focusNode = FocusNode();
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[false],
            onPressed: (int index) {},
            focusNodes: <FocusNode>[focusNode],
            children: const <Widget>[
              Text('First child'),
            ],
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.text('First child'));

    // splashColor
    final TestGesture touchGesture = await tester.createGesture();
    await touchGesture.down(center);
    await tester.pumpAndSettle();

    RenderObject inkFeatures;
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(
      inkFeatures,
      paints
        ..circle(color: theme.colorScheme.onSurface.withOpacity(0.16)),
    );

    await touchGesture.up();
    await tester.pumpAndSettle();

    // hoverColor
    final TestGesture hoverGesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await hoverGesture.addPointer();
    await hoverGesture.moveTo(center);
    await tester.pumpAndSettle();

    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(
      inkFeatures,
      paints..rect(color: theme.colorScheme.onSurface.withOpacity(0.04)),
    );
    await hoverGesture.removePointer();

    // focusColor
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(inkFeatures, paints..rect(color: theme.colorScheme.onSurface.withOpacity(0.12)));
  });

  testWidgets('Default InkWell colors - selected', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    final FocusNode focusNode = FocusNode();
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[true],
            onPressed: (int index) {},
            focusNodes: <FocusNode>[focusNode],
            children: const <Widget>[
              Text('First child'),
            ],
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.text('First child'));

    // splashColor
    final TestGesture touchGesture = await tester.createGesture();
    await touchGesture.down(center);
    await tester.pumpAndSettle();

    RenderObject inkFeatures;
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(
      inkFeatures,
      paints
        ..circle(color: theme.colorScheme.primary.withOpacity(0.16)),
    );

    await touchGesture.up();
    await tester.pumpAndSettle();

    // hoverColor
    final TestGesture hoverGesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await hoverGesture.addPointer();
    await hoverGesture.moveTo(center);
    await tester.pumpAndSettle();

    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(
      inkFeatures,
      paints..rect(color: theme.colorScheme.primary.withOpacity(0.04)),
    );
    await hoverGesture.removePointer();

    // focusColor
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(inkFeatures, paints..rect(color: theme.colorScheme.primary.withOpacity(0.12)));
  });

  testWidgets('Custom InkWell colors', (WidgetTester tester) async {
    const Color splashColor = Color(0xff4caf50);
    const Color highlightColor = Color(0xffcddc39);
    const Color hoverColor = Color(0xffffeb3b);
    const Color focusColor = Color(0xffffff00);
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            splashColor: splashColor,
            highlightColor: highlightColor,
            hoverColor: hoverColor,
            focusColor: focusColor,
            isSelected: const <bool>[true],
            onPressed: (int index) {},
            focusNodes: <FocusNode>[focusNode],
            children: const <Widget>[
              Text('First child'),
            ],
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.text('First child'));

    // splashColor
    final TestGesture touchGesture = await tester.createGesture();
    await touchGesture.down(center);
    await tester.pumpAndSettle();

    RenderObject inkFeatures;
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(
      inkFeatures,
      paints
        ..circle(color: splashColor),
    );

    await touchGesture.up();
    await tester.pumpAndSettle();

    // hoverColor
    final TestGesture hoverGesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await hoverGesture.addPointer();
    await hoverGesture.moveTo(center);
    await tester.pumpAndSettle();

    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(inkFeatures, paints..rect(color: hoverColor));
    await hoverGesture.removePointer();

    // focusColor
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(inkFeatures, paints..rect(color: focusColor));
  });

  testWidgets(
    'Default border width and border colors for enabled, selected and disabled states',
    (WidgetTester tester) async {
      final ThemeData theme = ThemeData();
      const double defaultBorderWidth = 1.0;
      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[false],
              onPressed: (int index) {},
              children: const <Widget>[
                Text('First child'),
              ],
            ),
          ),
        ),
      );

      RenderObject toggleButtonRenderObject;
      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: theme.colorScheme.onSurface.withOpacity(0.12),
            strokeWidth: defaultBorderWidth,
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: theme.colorScheme.onSurface.withOpacity(0.12),
            strokeWidth: defaultBorderWidth,
          ),
      );

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[true],
              onPressed: (int index) {},
              children: const <Widget>[
                Text('First child'),
              ],
            ),
          ),
        ),
      );

      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: theme.colorScheme.onSurface.withOpacity(0.12),
            strokeWidth: defaultBorderWidth,
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: theme.colorScheme.onSurface.withOpacity(0.12),
            strokeWidth: defaultBorderWidth,
          ),
      );

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[false],
              children: const <Widget>[
                Text('First child'),
              ],
            ),
          ),
        ),
      );

      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: theme.colorScheme.onSurface.withOpacity(0.12),
            strokeWidth: defaultBorderWidth,
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: theme.colorScheme.onSurface.withOpacity(0.12),
            strokeWidth: defaultBorderWidth,
          ),
      );
    },
  );

  testWidgets(
    'Custom border width and border colors for enabled, selected and disabled states',
    (WidgetTester tester) async {
      const Color borderColor = Color(0xff4caf50);
      const Color selectedBorderColor = Color(0xffcddc39);
      const Color disabledBorderColor = Color(0xffffeb3b);
      const double customWidth = 2.0;

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              borderColor: borderColor,
              borderWidth: customWidth,
              isSelected: const <bool>[false],
              onPressed: (int index) {},
              children: const <Widget>[
                Text('First child'),
              ],
            ),
          ),
        ),
      );

      RenderObject toggleButtonRenderObject;
      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: borderColor,
            strokeWidth: customWidth,
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: borderColor,
            strokeWidth: customWidth,
          ),
      );

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              selectedBorderColor: selectedBorderColor,
              borderWidth: customWidth,
              isSelected: const <bool>[true],
              onPressed: (int index) {},
              children: const <Widget>[
                Text('First child'),
              ],
            ),
          ),
        ),
      );

      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: selectedBorderColor,
            strokeWidth: customWidth,
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: selectedBorderColor,
            strokeWidth: customWidth,
          ),
      );

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              disabledBorderColor: disabledBorderColor,
              borderWidth: customWidth,
              isSelected: const <bool>[false],
              children: const <Widget>[
                Text('First child'),
              ],
            ),
          ),
        ),
      );

      toggleButtonRenderObject = tester.allRenderObjects.firstWhere((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      });
      expect(
        toggleButtonRenderObject,
        paints
          // trailing side
          ..path(
            style: PaintingStyle.stroke,
            color: disabledBorderColor,
            strokeWidth: customWidth,
          )
          // leading side, top and bottom
          ..path(
            style: PaintingStyle.stroke,
            color: disabledBorderColor,
            strokeWidth: customWidth,
          ),
      );
    },
  );

  testWidgets('Height of segmented control is determined by tallest widget', (WidgetTester tester) async {
    final List<Widget> children = <Widget>[
      Container(
        constraints: const BoxConstraints.tightFor(height: 100.0),
      ),
      Container(
        constraints: const BoxConstraints.tightFor(height: 400.0), // tallest widget
      ),
      Container(
        constraints: const BoxConstraints.tightFor(height: 200.0),
      ),
    ];

    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[false, true, false],
            children: children,
          ),
        ),
      ),
    );

    final List<Widget> toggleButtons = tester.allWidgets.where((Widget widget) {
      return widget.runtimeType.toString() == '_SelectToggleButton';
    }).toList();

    for (int i = 0; i < toggleButtons.length; i++) {
      final Rect rect = tester.getRect(find.byWidget(toggleButtons[i]));
      expect(rect.height, 400.0 + 2 * _defaultBorderWidth);
    }
  });

  testWidgets('Sizes of toggle buttons rebuilds with the correct dimensions', (WidgetTester tester) async {
    final List<Widget> children = <Widget>[
      Container(
        constraints: const BoxConstraints.tightFor(
          width: 100.0,
          height: 100.0,
        ),
      ),
      Container(
        constraints: const BoxConstraints.tightFor(
          width: 100.0,
          height: 100.0,
        ),
      ),
      Container(
        constraints: const BoxConstraints.tightFor(
          width: 100.0,
          height: 100.0,
        ),
      ),
    ];

    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[false, true, false],
            children: children,
          ),
        ),
      ),
    );

    List<Widget> toggleButtons;
    toggleButtons = tester.allWidgets.where((Widget widget) {
      return widget.runtimeType.toString() == '_SelectToggleButton';
    }).toList();

    for (int i = 0; i < toggleButtons.length; i++) {
      final Rect rect = tester.getRect(find.byWidget(toggleButtons[i]));
      expect(rect.height, 100.0 + 2 * _defaultBorderWidth);

      // Only the last button paints both leading and trailing borders.
      // Other buttons only paint the leading border.
      if (i == toggleButtons.length - 1) {
        expect(rect.width, 100.0 + 2 * _defaultBorderWidth);
      } else {
        expect(rect.width, 100.0 + 1 * _defaultBorderWidth);
      }
    }

    final List<Widget> childrenRebuilt = <Widget>[
      Container(
        constraints: const BoxConstraints.tightFor(
          width: 200.0,
          height: 200.0,
        ),
      ),
      Container(
        constraints: const BoxConstraints.tightFor(
          width: 200.0,
          height: 200.0,
        ),
      ),
      Container(
        constraints: const BoxConstraints.tightFor(
          width: 200.0,
          height: 200.0,
        ),
      ),
    ];

    // Update border width and widget sized to verify layout updates correctly
    const double customBorderWidth = 5.0;
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            borderWidth: customBorderWidth,
            isSelected: const <bool>[false, true, false],
            children: childrenRebuilt,
          ),
        ),
      ),
    );

    toggleButtons = tester.allWidgets.where((Widget widget) {
      return widget.runtimeType.toString() == '_SelectToggleButton';
    }).toList();

    // Only the last button paints both leading and trailing borders.
    // Other buttons only paint the leading border.
    for (int i = 0; i < toggleButtons.length; i++) {
      final Rect rect = tester.getRect(find.byWidget(toggleButtons[i]));
      expect(rect.height, 200.0 + 2 * customBorderWidth);
      if (i == toggleButtons.length - 1) {
        expect(rect.width, 200.0 + 2 * customBorderWidth);
      } else {
        expect(rect.width, 200.0 + 1 * customBorderWidth);
      }
    }
  });

  testWidgets('ToggleButtons text baseline alignment', (WidgetTester tester) async {
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              ToggleButtons(
                borderWidth: 5.0,
                isSelected: const <bool>[false, true],
                children: const <Widget>[
                  Text('First child', style: TextStyle(fontFamily: 'Ahem', fontSize: 10.0)),
                  Text('Second child', style: TextStyle(fontFamily: 'Ahem', fontSize: 10.0)),
                ],
              ),
              const MaterialButton(
                onPressed: null,
                child: Text('Material Button', style: TextStyle(fontFamily: 'Ahem', fontSize: 20.0)),
              ),
              const Text('Text', style: TextStyle(fontFamily: 'Ahem', fontSize: 30.0)),
            ],
          ),
        ),
      ),
    );

    // The Ahem font extends 0.2 * fontSize below the baseline.
    // So the three row elements line up like this:
    //
    //  ToggleButton  MaterialButton  Text
    //  ------------------------------------   baseline
    //  2             4               6        space below the baseline = 0.2 * fontSize
    //  ------------------------------------   widget text dy values

    final double firstToggleButtonDy = tester.getBottomLeft(find.text('First child')).dy;
    final double secondToggleButtonDy = tester.getBottomLeft(find.text('Second child')).dy;
    final double materialButtonDy = tester.getBottomLeft(find.text('Material Button')).dy;
    final double textDy = tester.getBottomLeft(find.text('Text')).dy;

    expect(firstToggleButtonDy, secondToggleButtonDy);
    expect(firstToggleButtonDy, closeTo(materialButtonDy - 2.0, 0.001));
    expect(firstToggleButtonDy, closeTo(textDy - 4.0, 0.001));
  });

  testWidgets('Directionality test', (WidgetTester tester) async {
    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ToggleButtons(
              onPressed: (int index) {},
              isSelected: const <bool>[false, true],
              children: const <Widget>[
                Text('First child'),
                Text('Second child'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getTopRight(find.text('First child')).dx < tester.getTopRight(find.text('Second child')).dx,
      isTrue,
    );

    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: ToggleButtons(
              onPressed: (int index) {},
              isSelected: const <bool>[false, true],
              children: const <Widget>[
                Text('First child'),
                Text('Second child'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getTopRight(find.text('First child')).dx > tester.getTopRight(find.text('Second child')).dx,
      isTrue,
    );
  });

  testWidgets(
    'Properly draws borders based on state',
    (WidgetTester tester) async {
      final ThemeData theme = ThemeData();
      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[false, true, false],
              onPressed: (int index) {},
              children: const <Widget>[
                Text('First child'),
                Text('Second child'),
                Text('Third child'),
              ],
            ),
          ),
        ),
      );

      final List<RenderObject> toggleButtonRenderObject = tester.allRenderObjects.where((RenderObject object) {
        return object.runtimeType.toString() == '_SelectToggleButtonRenderObject';
      }).toSet().toList();

      // The first button paints the leading, top and bottom sides with a path
      expect(
        toggleButtonRenderObject[0],
        paints
          // leading side, top and bottom - enabled
          ..path(
            style: PaintingStyle.stroke,
            color: theme.colorScheme.onSurface.withOpacity(0.12),
            strokeWidth: _defaultBorderWidth,
          ),
      );

      // The middle buttons paint a leading side path first, followed by a
      // top and bottom side path
      expect(
        toggleButtonRenderObject[1],
        paints
          // leading side - selected
          ..path(
            style: PaintingStyle.stroke,
            color: theme.colorScheme.onSurface.withOpacity(0.12),
            strokeWidth: _defaultBorderWidth,
          )
          // top and bottom - selected
          ..path(
            style: PaintingStyle.stroke,
            color: theme.colorScheme.onSurface.withOpacity(0.12),
            strokeWidth: _defaultBorderWidth,
          ),
      );

      // The last button paints a leading side path first, followed by
      // a trailing, top and bottom side path
      expect(
        toggleButtonRenderObject[2],
        paints
          // leading side - selected, since previous button is selected
          ..path(
            style: PaintingStyle.stroke,
            color: theme.colorScheme.onSurface.withOpacity(0.12),
            strokeWidth: _defaultBorderWidth,
          )
          // trailing side, top and bottom - enabled
          ..path(
            style: PaintingStyle.stroke,
            color: theme.colorScheme.onSurface.withOpacity(0.12),
            strokeWidth: _defaultBorderWidth,
          ),
      );
    },
  );
}
