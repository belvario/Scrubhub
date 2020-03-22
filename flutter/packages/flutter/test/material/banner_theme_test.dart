// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MaterialBannerThemeData copyWith, ==, hashCode basics', () {
    expect(const MaterialBannerThemeData(), const MaterialBannerThemeData().copyWith());
    expect(const MaterialBannerThemeData().hashCode, const MaterialBannerThemeData().copyWith().hashCode);
  });

  test('MaterialBannerThemeData null fields by default', () {
    const MaterialBannerThemeData bannerTheme = MaterialBannerThemeData();
    expect(bannerTheme.backgroundColor, null);
    expect(bannerTheme.contentTextStyle, null);
  });

  testWidgets('Default MaterialBannerThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const MaterialBannerThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgets('MaterialBannerThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const MaterialBannerThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      contentTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'backgroundColor: Color(0xffffffff)',
      'contentTextStyle: TextStyle(inherit: true, color: Color(0xffffffff))',
    ]);
  });

  testWidgets('Passing no MaterialBannerThemeData returns defaults', (WidgetTester tester) async {
    const String contentText = 'Content';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MaterialBanner(
          content: const Text(contentText),
          actions: <Widget>[
            FlatButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    ));

    final Container container = _getContainerFromBanner(tester);
    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(container.decoration, const BoxDecoration(color: Color(0xffffffff)));
    expect(content.text.style, Typography().englishLike.body1.merge(Typography().black.body1));
  });

  testWidgets('MaterialBanner uses values from MaterialBannerThemeData', (WidgetTester tester) async {
    final MaterialBannerThemeData bannerTheme = _bannerTheme();
    const String contentText = 'Content';
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(bannerTheme: bannerTheme),
      home: Scaffold(
        body: MaterialBanner(
          leading: const Icon(Icons.ac_unit),
          content: const Text(contentText),
          actions: <Widget>[
            FlatButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    ));

    final Container container = _getContainerFromBanner(tester);
    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(container.decoration, BoxDecoration(color: bannerTheme.backgroundColor));
    expect(content.text.style, bannerTheme.contentTextStyle);

    final Offset contentTopLeft = tester.getTopLeft(_textFinder(contentText));
    final Offset containerTopLeft = tester.getTopLeft(_containerFinder());
    final Offset leadingTopLeft = tester.getTopLeft(find.byIcon(Icons.ac_unit));
    expect(contentTopLeft.dy - containerTopLeft.dy, 24);
    expect(contentTopLeft.dx - containerTopLeft.dx, 39);
    expect(leadingTopLeft.dy - containerTopLeft.dy, 19);
    expect(leadingTopLeft.dx - containerTopLeft.dx, 10);
  });

  testWidgets('MaterialBanner widget properties take priority over theme', (WidgetTester tester) async {
    const Color backgroundColor = Colors.purple;
    const TextStyle textStyle = TextStyle(color: Colors.green);
    final MaterialBannerThemeData bannerTheme = _bannerTheme();
    const String contentText = 'Content';
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(bannerTheme: bannerTheme),
      home: Scaffold(
        body: MaterialBanner(
          backgroundColor: backgroundColor,
          leading: const Icon(Icons.ac_unit),
          contentTextStyle: textStyle,
          content: const Text(contentText),
          padding: const EdgeInsets.all(10),
          leadingPadding: const EdgeInsets.all(10),
          actions: <Widget>[
            FlatButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    ));

    final Container container = _getContainerFromBanner(tester);
    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(container.decoration, const BoxDecoration(color: backgroundColor));
    expect(content.text.style, textStyle);

    final Offset contentTopLeft = tester.getTopLeft(_textFinder(contentText));
    final Offset containerTopLeft = tester.getTopLeft(_containerFinder());
    final Offset leadingTopLeft = tester.getTopLeft(find.byIcon(Icons.ac_unit));
    expect(contentTopLeft.dy - containerTopLeft.dy, 29);
    expect(contentTopLeft.dx - containerTopLeft.dx, 54);
    expect(leadingTopLeft.dy - containerTopLeft.dy, 24);
    expect(leadingTopLeft.dx - containerTopLeft.dx, 20);
  });

  testWidgets('MaterialBanner uses color scheme when necessary', (WidgetTester tester) async {
    final ColorScheme colorScheme = const ColorScheme.light().copyWith(surface: Colors.purple);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(colorScheme: colorScheme),
      home: Scaffold(
        body: MaterialBanner(
          content: const Text('Content'),
          actions: <Widget>[
            FlatButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    ));

    final Container container = _getContainerFromBanner(tester);
    expect(container.decoration, BoxDecoration(color: colorScheme.surface));
  });
}

MaterialBannerThemeData _bannerTheme() {
  return const MaterialBannerThemeData(
    backgroundColor: Colors.orange,
    contentTextStyle: TextStyle(color: Colors.pink),
    padding: EdgeInsets.all(5),
    leadingPadding: EdgeInsets.all(5),
  );
}

Container _getContainerFromBanner(WidgetTester tester) {
  return tester.widget<Container>(_containerFinder());
}

Finder _containerFinder() {
  return find.descendant(of: find.byType(MaterialBanner), matching: find.byType(Container)).first;
}

RenderParagraph _getTextRenderObjectFromDialog(WidgetTester tester, String text) {
  return tester.element<StatelessElement>(_textFinder(text)).renderObject;
}

Finder _textFinder(String text) {
  return find.descendant(of: find.byType(MaterialBanner), matching: find.text(text));
}
