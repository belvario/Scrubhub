// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Verify that a BottomSheet can be rebuilt with ScaffoldFeatureController.setState()', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    PersistentBottomSheetController<void> bottomSheet;
    int buildCount = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        body: const Center(child: Text('body')),
      ),
    ));

    bottomSheet = scaffoldKey.currentState.showBottomSheet<void>((_) {
      return Builder(
        builder: (BuildContext context) {
          buildCount += 1;
          return Container(height: 200.0);
        }
      );
    });

    await tester.pump();
    expect(buildCount, equals(1));
    bottomSheet.setState(() { });
    await tester.pump();
    expect(buildCount, equals(2));
  });

  testWidgets('Verify that a persistent BottomSheet cannot be dismissed', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: const Center(child: Text('body')),
        bottomSheet: DraggableScrollableSheet(
          expand: false,
          builder: (_, ScrollController controller) {
            return ListView(
              controller: controller,
              shrinkWrap: true,
              children: <Widget>[
                Container(height: 100.0, child: const Text('One')),
                Container(height: 100.0, child: const Text('Two')),
                Container(height: 100.0, child: const Text('Three')),
              ],
            );
          },
        ),
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);

    await tester.drag(find.text('Two'), const Offset(0.0, 400.0));
    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('Verify that a scrollable BottomSheet can be dismissed', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        body: const Center(child: Text('body')),
      ),
    ));

    scaffoldKey.currentState.showBottomSheet<void>((BuildContext context) {
      return ListView(
        shrinkWrap: true,
        primary: false,
        children: <Widget>[
          Container(height: 100.0, child: const Text('One')),
          Container(height: 100.0, child: const Text('Two')),
          Container(height: 100.0, child: const Text('Three')),
        ],
      );
    });

    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);

    await tester.drag(find.text('Two'), const Offset(0.0, 400.0));
    await tester.pumpAndSettle();

    expect(find.text('Two'), findsNothing);
  });

  testWidgets('Verify that a scrollControlled BottomSheet can be dismissed', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        body: const Center(child: Text('body')),
      ),
    ));

    scaffoldKey.currentState.showBottomSheet<void>(
      (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, ScrollController controller) {
            return ListView(
              shrinkWrap: true,
              controller: controller,
              children: <Widget>[
                Container(height: 100.0, child: const Text('One')),
                Container(height: 100.0, child: const Text('Two')),
                Container(height: 100.0, child: const Text('Three')),
              ],
            );
          },
        );
      },
    );

    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);

    await tester.drag(find.text('Two'), const Offset(0.0, 400.0));
    await tester.pumpAndSettle();

    expect(find.text('Two'), findsNothing);
  });

  testWidgets('Verify that a persistent BottomSheet can fling up and hide the fab', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('body')),
          bottomSheet: DraggableScrollableSheet(
            expand: false,
            builder: (_, ScrollController controller) {
              return ListView.builder(
                itemExtent: 50.0,
                itemCount: 50,
                itemBuilder: (_, int index) => Text('Item $index'),
                controller: controller,
              );
            },
          ),
          floatingActionButton: const FloatingActionButton(
            onPressed: null,
            child: Text('fab'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 22'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(FloatingActionButton).hitTestable(), findsOneWidget);
    expect(find.byType(BackButton).hitTestable(), findsNothing);

    await tester.drag(find.text('Item 2'), const Offset(0, -20.0));
    await tester.pumpAndSettle();

    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 22'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(FloatingActionButton).hitTestable(), findsOneWidget);

    await tester.fling(find.text('Item 2'), const Offset(0.0, -600.0), 2000.0);
    await tester.pumpAndSettle();

    expect(find.text('Item 2'), findsNothing);
    expect(find.text('Item 22'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(FloatingActionButton).hitTestable(), findsNothing);
  });

  testWidgets('Verify that a back button resets a persistent BottomSheet', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('body')),
          bottomSheet: DraggableScrollableSheet(
            expand: false,
            builder: (_, ScrollController controller) {
              return ListView.builder(
                itemExtent: 50.0,
                itemCount: 50,
                itemBuilder: (_, int index) => Text('Item $index'),
                controller: controller,
              );
            },
          ),
          floatingActionButton: const FloatingActionButton(
            onPressed: null,
            child: Text('fab'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 22'), findsNothing);
    expect(find.byType(BackButton).hitTestable(), findsNothing);

    await tester.drag(find.text('Item 2'), const Offset(0, -20.0));
    await tester.pumpAndSettle();

    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 22'), findsNothing);
    // We've started to drag up, we should have a back button now for a11y
    expect(find.byType(BackButton).hitTestable(), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton).hitTestable(), findsNothing);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 22'), findsNothing);

    await tester.fling(find.text('Item 2'), const Offset(0.0, -600.0), 2000.0);
    await tester.pumpAndSettle();

    expect(find.text('Item 2'), findsNothing);
    expect(find.text('Item 22'), findsOneWidget);
    expect(find.byType(BackButton).hitTestable(), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton).hitTestable(), findsNothing);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 22'), findsNothing);
  });

  testWidgets('Verify that a scrollable BottomSheet hides the fab when scrolled up', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        body: const Center(child: Text('body')),
        floatingActionButton: const FloatingActionButton(
          onPressed: null,
          child: Text('fab'),
        ),
      ),
    ));

    scaffoldKey.currentState.showBottomSheet<void>(
      (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, ScrollController controller) {
            return ListView(
              controller: controller,
              shrinkWrap: true,
              children: <Widget>[
                Container(height: 100.0, child: const Text('One')),
                Container(height: 100.0, child: const Text('Two')),
                Container(height: 100.0, child: const Text('Three')),
                Container(height: 100.0, child: const Text('Three')),
                Container(height: 100.0, child: const Text('Three')),
                Container(height: 100.0, child: const Text('Three')),
                Container(height: 100.0, child: const Text('Three')),
                Container(height: 100.0, child: const Text('Three')),
                Container(height: 100.0, child: const Text('Three')),
                Container(height: 100.0, child: const Text('Three')),
                Container(height: 100.0, child: const Text('Three')),
              ],
            );
          },
        );
      },
    );

    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);
    expect(find.byType(FloatingActionButton).hitTestable(), findsOneWidget);

    await tester.drag(find.text('Two'), const Offset(0.0, -600.0));
    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(FloatingActionButton).hitTestable(), findsNothing);
  });

  testWidgets('showBottomSheet()', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Placeholder(key: key),
      ),
    ));

    int buildCount = 0;
    showBottomSheet<void>(
      context: key.currentContext,
      builder: (BuildContext context) {
        return Builder(
          builder: (BuildContext context) {
            buildCount += 1;
            return Container(height: 200.0);
          },
        );
      },
    );
    await tester.pump();
    expect(buildCount, equals(1));
  });

  testWidgets('Scaffold removes top MediaQuery padding', (WidgetTester tester) async {
    BuildContext scaffoldContext;
    BuildContext bottomSheetContext;

    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.all(50.0),
        ),
        child: Scaffold(
          resizeToAvoidBottomPadding: false,
          body: Builder(
            builder: (BuildContext context) {
              scaffoldContext = context;
              return Container();
            }
          ),
        ),
      ),
    ));

    await tester.pump();

    showBottomSheet<void>(
      context: scaffoldContext,
      builder: (BuildContext context) {
        bottomSheetContext = context;
        return Container();
      },
    );

    await tester.pump();

    expect(
      MediaQuery.of(bottomSheetContext).padding,
      const EdgeInsets.only(
        bottom: 50.0,
        left: 50.0,
        right: 50.0,
      ),
    );
  });

  testWidgets('Scaffold.bottomSheet', (WidgetTester tester) async {
    final Key bottomSheetKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const Placeholder(),
          bottomSheet: Container(
            key: bottomSheetKey,
            alignment: Alignment.center,
            height: 200.0,
            child: Builder(
              builder: (BuildContext context) {
                return RaisedButton(
                  child: const Text('showModalBottomSheet'),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext context) => const Text('modal bottom sheet'),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('showModalBottomSheet'), findsOneWidget);
    expect(tester.getSize(find.byKey(bottomSheetKey)), const Size(800.0, 200.0));
    expect(tester.getTopLeft(find.byKey(bottomSheetKey)), const Offset(0.0, 400.0));

    // Show the modal bottomSheet
    await tester.tap(find.text('showModalBottomSheet'));
    await tester.pumpAndSettle();
    expect(find.text('modal bottom sheet'), findsOneWidget);

    // Dismiss the modal bottomSheet by tapping above the sheet
    await tester.tapAt(const Offset(20.0, 20.0));
    await tester.pumpAndSettle();
    expect(find.text('modal bottom sheet'), findsNothing);
    expect(find.text('showModalBottomSheet'), findsOneWidget);

    // Remove the persistent bottomSheet
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomSheet: null,
          body: Placeholder(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('showModalBottomSheet'), findsNothing);
    expect(find.byKey(bottomSheetKey), findsNothing);
  });

  testWidgets('Verify that visual properties are passed through', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    const Color color = Colors.pink;
    const double elevation = 9.0;
    final ShapeBorder shape = BeveledRectangleBorder(borderRadius: BorderRadius.circular(12));
    const Clip clipBehavior = Clip.antiAlias;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        body: const Center(child: Text('body')),
      ),
    ));

    scaffoldKey.currentState.showBottomSheet<void>((BuildContext context) {
      return ListView(
        shrinkWrap: true,
        primary: false,
        children: <Widget>[
          Container(height: 100.0, child: const Text('One')),
          Container(height: 100.0, child: const Text('Two')),
          Container(height: 100.0, child: const Text('Three')),
        ],
      );
    }, backgroundColor: color, elevation: elevation, shape: shape, clipBehavior: clipBehavior);

    await tester.pumpAndSettle();

    final BottomSheet bottomSheet = tester.widget(find.byType(BottomSheet));
    expect(bottomSheet.backgroundColor, color);
    expect(bottomSheet.elevation, elevation);
    expect(bottomSheet.shape, shape);
    expect(bottomSheet.clipBehavior, clipBehavior);
  });

  testWidgets('PersistentBottomSheetController.close dismisses the bottom sheet', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        body: const Center(child: Text('body')),
      ),
    ));

    final PersistentBottomSheetController<void> bottomSheet = scaffoldKey.currentState.showBottomSheet<void>((_) {
      return Builder(
        builder: (BuildContext context) {
          return Container(height: 200.0);
        }
      );
    });

    await tester.pump();
    expect(find.byType(BottomSheet), findsOneWidget);

    bottomSheet.close();
    await tester.pump();
    expect(find.byType(BottomSheet), findsNothing);
  });
}
