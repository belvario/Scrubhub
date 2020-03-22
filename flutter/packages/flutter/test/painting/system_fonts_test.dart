// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RenderParagraph relayout upon system fonts changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Text('text widget'),
      ),
    );
    const Map<String, dynamic> data = <String, dynamic>{
      'type': 'fontsChange',
    };
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
      (ByteData data) { },
    );
    final RenderObject renderObject = tester.renderObject(find.text('text widget'));
    expect(renderObject.debugNeedsLayout, isTrue);
  });

  testWidgets('RenderEditable relayout upon system fonts changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SelectableText('text widget'),
      ),
    );
    const Map<String, dynamic> data = <String, dynamic>{
      'type': 'fontsChange',
    };
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
        (ByteData data) { },
    );
    final EditableTextState state = tester.state(find.byType(EditableText));
    expect(state.renderEditable.debugNeedsLayout, isTrue);
  });

  testWidgets('Banner repaint upon system fonts changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Banner(
        message: 'message',
        location: BannerLocation.topStart,
        textDirection: TextDirection.ltr,
        layoutDirection: TextDirection.ltr,
      ),
    );
    const Map<String, dynamic> data = <String, dynamic>{
      'type': 'fontsChange',
    };
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
        (ByteData data) { },
    );
    final RenderObject renderObject = tester.renderObject(find.byType(Banner));
    expect(renderObject.debugNeedsPaint, isTrue);
  });

  testWidgets('CupertinoDatePicker reset cache upon system fonts change - date time mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoDatePicker(
          onDateTimeChanged: (DateTime dateTime) { },
        ),
      ),
    );
    final dynamic state = tester.state(find.byType(CupertinoDatePicker));
    final Map<int, double> cache = state.estimatedColumnWidths;
    expect(cache.isNotEmpty, isTrue);
    const Map<String, dynamic> data = <String, dynamic>{
      'type': 'fontsChange',
    };
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
        (ByteData data) { },
    );
    // Cache should be cleaned.
    expect(cache.isEmpty, isTrue);
    final Element element = tester.element(find.byType(CupertinoDatePicker));
    expect(element.dirty, isTrue);
  }, skip: isBrowser);  // TODO(yjbanov): cupertino does not work on the Web yet: https://github.com/flutter/flutter/issues/41920

  testWidgets('CupertinoDatePicker reset cache upon system fonts change - date mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (DateTime dateTime) { },
        ),
      ),
    );
    final dynamic state = tester.state(find.byType(CupertinoDatePicker));
    final Map<int, double> cache = state.estimatedColumnWidths;
    // Simulates font missing.
    cache.clear();
    const Map<String, dynamic> data = <String, dynamic>{
      'type': 'fontsChange',
    };
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
        (ByteData data) { },
    );
    // Cache should be replenished
    expect(cache.isNotEmpty, isTrue);
    final Element element = tester.element(find.byType(CupertinoDatePicker));
    expect(element.dirty, isTrue);
  }, skip: isBrowser);  // TODO(yjbanov): cupertino does not work on the Web yet: https://github.com/flutter/flutter/issues/41920

  testWidgets('CupertinoDatePicker reset cache upon system fonts change - time mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoTimerPicker(
          onTimerDurationChanged: (Duration d) { },
        ),
      ),
    );
    final dynamic state = tester.state(find.byType(CupertinoTimerPicker));
    // Simulates wrong metrics due to font missing.
    state.numberLabelWidth = 0.0;
    state.numberLabelHeight = 0.0;
    state.numberLabelBaseline = 0.0;
    const Map<String, dynamic> data = <String, dynamic>{
      'type': 'fontsChange',
    };
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
        (ByteData data) { },
    );
    // Metrics should be refreshed
    expect(state.numberLabelWidth - 46.0 < precisionErrorTolerance, isTrue);
    expect(state.numberLabelHeight - 23.0 < precisionErrorTolerance, isTrue);
    expect(state.numberLabelBaseline - 18.400070190429688 < precisionErrorTolerance, isTrue);
    final Element element = tester.element(find.byType(CupertinoTimerPicker));
    expect(element.dirty, isTrue);
  }, skip: isBrowser);  // TODO(yjbanov): cupertino does not work on the Web yet: https://github.com/flutter/flutter/issues/41920

  testWidgets('RangeSlider relayout upon system fonts changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: RangeSlider(
            values: const RangeValues(0.0, 1.0),
            onChanged: (RangeValues values) { },
          ),
        ),
      ),
    );
    const Map<String, dynamic> data = <String, dynamic>{
      'type': 'fontsChange',
    };
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
        (ByteData data) { },
    );
    final RenderObject renderObject = tester.renderObject(find.byType(RangeSlider));
    expect(renderObject.debugNeedsLayout, isTrue);
  });

  testWidgets('Slider relayout upon system fonts changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Slider(
            value: 0.0,
            onChanged: (double value) { },
          ),
        ),
      ),
    );
    const Map<String, dynamic> data = <String, dynamic>{
      'type': 'fontsChange',
    };
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
        (ByteData data) { },
    );
    final RenderObject renderObject = tester.renderObject(find.byType(Slider));
    expect(renderObject.debugNeedsLayout, isTrue);
  });

  testWidgets('TimePicker relayout upon system fonts changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: Builder(
              builder: (BuildContext context) {
                return RaisedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 7, minute: 0),
                      builder: (BuildContext context, Widget child) {
                        return Directionality(
                          key: const Key('parent'),
                          textDirection: TextDirection.ltr,
                          child: child,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();
    const Map<String, dynamic> data = <String, dynamic>{
      'type': 'fontsChange',
    };
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      SystemChannels.system.codec.encodeMessage(data),
        (ByteData data) { },
    );
    final RenderObject renderObject = tester.renderObject(
      find.descendant(
        of: find.byKey(const Key('parent')),
        matching: find.byType(CustomPaint),
      ).first,
    );
    expect(renderObject.debugNeedsPaint, isTrue);
  });
}
