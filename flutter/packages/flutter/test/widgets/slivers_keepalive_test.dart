// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

void main() {
  testWidgets('Sliver with keep alive without key - should dispose after reodering', (WidgetTester tester) async {
    List<Widget> childList= <Widget>[
      const WidgetTest0(text: 'child 0', keepAlive: true),
      const WidgetTest1(text: 'child 1', keepAlive: true),
      const WidgetTest2(text: 'child 2', keepAlive: true),
    ];
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest0State state0 = tester.state(find.byType(WidgetTest0));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    childList = createSwitchedChildList(childList, 0, 2);
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest2State state2 = tester.state(find.byType(WidgetTest2));
    expect(find.text('child 2'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 0', skipOffstage: false), findsNothing);

    expect(state0.hasBeenDisposed, true);
    expect(state2.hasBeenDisposed, false);
  });

  testWidgets('Sliver without keep alive without key - should dispose after reodering', (WidgetTester tester) async {
    List<Widget> childList= <Widget>[
      const WidgetTest0(text: 'child 0'),
      const WidgetTest1(text: 'child 1'),
      const WidgetTest2(text: 'child 2'),
    ];
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest0State state0 = tester.state(find.byType(WidgetTest0));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    childList = createSwitchedChildList(childList, 0, 2);
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest2State state2 = tester.state(find.byType(WidgetTest2));
    expect(find.text('child 2'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 0', skipOffstage: false), findsNothing);

    expect(state0.hasBeenDisposed, true);
    expect(state2.hasBeenDisposed, false);
  });

  testWidgets('Sliver without keep alive with key - should dispose after reodering', (WidgetTester tester) async {
    List<Widget> childList= <Widget>[
      WidgetTest0(text: 'child 0', key: GlobalKey()),
      WidgetTest1(text: 'child 1', key: GlobalKey()),
      WidgetTest2(text: 'child 2', key: GlobalKey()),
    ];
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest0State state0 = tester.state(find.byType(WidgetTest0));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    childList = createSwitchedChildList(childList, 0, 2);
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest2State state2 = tester.state(find.byType(WidgetTest2));
    expect(find.text('child 2'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 0', skipOffstage: false), findsNothing);

    expect(state0.hasBeenDisposed, true);
    expect(state2.hasBeenDisposed, false);
  });

  testWidgets('Sliver with keep alive with key - should not dispose after reodering', (WidgetTester tester) async {
    List<Widget> childList= <Widget>[
      WidgetTest0(text: 'child 0', key: GlobalKey(), keepAlive: true),
      WidgetTest1(text: 'child 1', key: GlobalKey(), keepAlive: true),
      WidgetTest2(text: 'child 2', key: GlobalKey(), keepAlive: true),
    ];
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest0State state0 = tester.state(find.byType(WidgetTest0));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    childList = createSwitchedChildList(childList, 0, 2);
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest2State state2 = tester.state(find.byType(WidgetTest2));
    expect(find.text('child 2'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 0', skipOffstage: false), findsOneWidget);
    expect(state0.hasBeenDisposed, false);
    expect(state2.hasBeenDisposed, false);
  });

  testWidgets('Sliver with keep alive with Unique key - should not dispose after reodering', (WidgetTester tester) async {
    List<Widget> childList= <Widget>[
      WidgetTest0(text: 'child 0', key: UniqueKey(), keepAlive: true),
      WidgetTest1(text: 'child 1', key: UniqueKey(), keepAlive: true),
      WidgetTest2(text: 'child 2', key: UniqueKey(), keepAlive: true),
    ];
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest0State state0 = tester.state(find.byType(WidgetTest0));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    childList = createSwitchedChildList(childList, 0, 2);
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest2State state2 = tester.state(find.byType(WidgetTest2));
    expect(find.text('child 2'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 0', skipOffstage: false), findsOneWidget);
    expect(state0.hasBeenDisposed, false);
    expect(state2.hasBeenDisposed, false);
  });

  testWidgets('Sliver with keep alive with Value key - should not dispose after reodering', (WidgetTester tester) async {
    List<Widget> childList= <Widget>[
      const WidgetTest0(text: 'child 0', key: ValueKey<int>(0), keepAlive: true),
      const WidgetTest1(text: 'child 1', key: ValueKey<int>(1), keepAlive: true),
      const WidgetTest2(text: 'child 2', key: ValueKey<int>(2), keepAlive: true),
    ];
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest0State state0 = tester.state(find.byType(WidgetTest0));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    childList = createSwitchedChildList(childList, 0, 2);
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest2State state2 = tester.state(find.byType(WidgetTest2));
    expect(find.text('child 2'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 0', skipOffstage: false), findsOneWidget);
    expect(state0.hasBeenDisposed, false);
    expect(state2.hasBeenDisposed, false);
  });

  testWidgets('Sliver complex case 1', (WidgetTester tester) async {
    List<Widget> childList= <Widget>[
      WidgetTest0(text: 'child 0', key: GlobalKey(), keepAlive: true),
      WidgetTest1(text: 'child 1', key: GlobalKey(), keepAlive: true),
      const WidgetTest2(text: 'child 2', keepAlive: true),
    ];
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest0State state0 = tester.state(find.byType(WidgetTest0));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    childList = createSwitchedChildList(childList, 0, 2);
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest2State state2 = tester.state(find.byType(WidgetTest2));
    expect(find.text('child 2'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 0', skipOffstage: false), findsOneWidget);

    childList = createSwitchedChildList(childList, 0, 1);
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest1State state1 = tester.state(find.byType(WidgetTest1));
    expect(find.text('child 1'), findsOneWidget);
    expect(find.text('child 2', skipOffstage: false), findsNothing);
    expect(find.text('child 0', skipOffstage: false), findsOneWidget);

    childList = createSwitchedChildList(childList, 1, 2);
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    expect(find.text('child 1'), findsOneWidget);
    expect(find.text('child 0', skipOffstage: false), findsOneWidget);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    childList = createSwitchedChildList(childList, 0, 1);
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsOneWidget);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    expect(state0.hasBeenDisposed, false);
    expect(state1.hasBeenDisposed, false);
    // Child 2 does not have a key.
    expect(state2.hasBeenDisposed, true);
  });

  testWidgets('Sliver complex case 2', (WidgetTester tester) async {
    List<Widget> childList= <Widget>[
      WidgetTest0(text: 'child 0', key: GlobalKey(), keepAlive: true),
      WidgetTest1(text: 'child 1', key: UniqueKey()),
      const WidgetTest2(text: 'child 2', keepAlive: true),
    ];
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest0State state0 = tester.state(find.byType(WidgetTest0));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    childList = createSwitchedChildList(childList, 0, 2);
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest2State state2 = tester.state(find.byType(WidgetTest2));
    expect(find.text('child 2'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 0', skipOffstage: false), findsOneWidget);

    childList = createSwitchedChildList(childList, 0, 1);
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    final _WidgetTest1State state1 = tester.state(find.byType(WidgetTest1));
    expect(find.text('child 1'), findsOneWidget);
    expect(find.text('child 2', skipOffstage: false), findsNothing);
    expect(find.text('child 0', skipOffstage: false), findsOneWidget);

    childList = createSwitchedChildList(childList, 1, 2);
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    expect(find.text('child 1'), findsOneWidget);
    expect(find.text('child 0', skipOffstage: false), findsOneWidget);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    childList = createSwitchedChildList(childList, 0, 1);
    await tester.pumpWidget(SwitchingChildListTest(children: childList));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    expect(state0.hasBeenDisposed, false);
    expect(state1.hasBeenDisposed, true);
    expect(state2.hasBeenDisposed, true);
  });

  testWidgets('Sliver with SliverChildBuilderDelegate', (WidgetTester tester) async {
    List<Widget> childList= <Widget>[
      WidgetTest0(text: 'child 0', key: UniqueKey(), keepAlive: true),
      WidgetTest1(text: 'child 1', key: GlobalKey()),
      const WidgetTest2(text: 'child 2', keepAlive: true),
    ];
    await tester.pumpWidget(SwitchingChildBuilderTest(children: childList));
    final _WidgetTest0State state0 = tester.state(find.byType(WidgetTest0));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    childList = createSwitchedChildList(childList, 0, 2);
    await tester.pumpWidget(SwitchingChildBuilderTest(children: childList));
    final _WidgetTest2State state2 = tester.state(find.byType(WidgetTest2));
    expect(find.text('child 2'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 0', skipOffstage: false), findsOneWidget);

    childList = createSwitchedChildList(childList, 0, 1);
    await tester.pumpWidget(SwitchingChildBuilderTest(children: childList));
    final _WidgetTest1State state1 = tester.state(find.byType(WidgetTest1));
    expect(find.text('child 1'), findsOneWidget);
    expect(find.text('child 2', skipOffstage: false), findsNothing);
    expect(find.text('child 0', skipOffstage: false), findsOneWidget);

    childList = createSwitchedChildList(childList, 1, 2);
    await tester.pumpWidget(SwitchingChildBuilderTest(children: childList));
    expect(find.text('child 1'), findsOneWidget);
    expect(find.text('child 0', skipOffstage: false), findsOneWidget);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    childList = createSwitchedChildList(childList, 0, 1);
    await tester.pumpWidget(SwitchingChildBuilderTest(children: childList));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1', skipOffstage: false), findsNothing);
    expect(find.text('child 2', skipOffstage: false), findsNothing);

    expect(state0.hasBeenDisposed, false);
    expect(state1.hasBeenDisposed, true);
    expect(state2.hasBeenDisposed, true);
  });

  testWidgets('SliverFillViewport should not dispose widget with key during in screen reordering', (WidgetTester tester) async {
    List<Widget> childList= <Widget>[
      WidgetTest0(text: 'child 0', key: UniqueKey(), keepAlive: true),
      WidgetTest1(text: 'child 1', key: UniqueKey()),
      const WidgetTest2(text: 'child 2', keepAlive: true),
    ];
    await tester.pumpWidget(
        SwitchingChildListTest(children: childList, viewportFraction: 0.1)
    );
    final _WidgetTest0State state0 = tester.state(find.byType(WidgetTest0));
    final _WidgetTest1State state1 = tester.state(find.byType(WidgetTest1));
    final _WidgetTest2State state2 = tester.state(find.byType(WidgetTest2));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1'), findsOneWidget);
    expect(find.text('child 2'), findsOneWidget);

    childList = createSwitchedChildList(childList, 0, 2);
    await tester.pumpWidget(
        SwitchingChildListTest(children: childList, viewportFraction: 0.1)
    );

    childList = createSwitchedChildList(childList, 0, 1);
    await tester.pumpWidget(
        SwitchingChildListTest(children: childList, viewportFraction: 0.1)
    );

    childList = createSwitchedChildList(childList, 1, 2);
    await tester.pumpWidget(
        SwitchingChildListTest(children: childList, viewportFraction: 0.1)
    );

    childList = createSwitchedChildList(childList, 0, 1);
    await tester.pumpWidget(
        SwitchingChildListTest(children: childList, viewportFraction: 0.1)
    );

    expect(state0.hasBeenDisposed, false);
    expect(state1.hasBeenDisposed, false);
    expect(state2.hasBeenDisposed, true);
  });

  testWidgets('SliverList should not dispose widget with key during in screen reordering', (WidgetTester tester) async {
    List<Widget> childList= <Widget>[
      WidgetTest0(text: 'child 0', key: UniqueKey(), keepAlive: true),
      const WidgetTest1(text: 'child 1', keepAlive: true),
      WidgetTest2(text: 'child 2', key: UniqueKey()),
    ];
    await tester.pumpWidget(
        SwitchingSliverListTest(children: childList, viewportFraction: 0.1)
    );
    final _WidgetTest0State state0 = tester.state(find.byType(WidgetTest0));
    final _WidgetTest1State state1 = tester.state(find.byType(WidgetTest1));
    final _WidgetTest2State state2 = tester.state(find.byType(WidgetTest2));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1'), findsOneWidget);
    expect(find.text('child 2'), findsOneWidget);

    childList = createSwitchedChildList(childList, 0, 2);
    await tester.pumpWidget(
        SwitchingSliverListTest(children: childList, viewportFraction: 0.1)
    );

    childList = createSwitchedChildList(childList, 1, 2);
    await tester.pumpWidget(
        SwitchingSliverListTest(children: childList, viewportFraction: 0.1)
    );

    childList = createSwitchedChildList(childList, 1, 2);
    await tester.pumpWidget(
        SwitchingSliverListTest(children: childList, viewportFraction: 0.1)
    );

    childList = createSwitchedChildList(childList, 0, 1);
    await tester.pumpWidget(
        SwitchingSliverListTest(children: childList, viewportFraction: 0.1)
    );

    childList = createSwitchedChildList(childList, 0, 2);
    await tester.pumpWidget(
        SwitchingSliverListTest(children: childList, viewportFraction: 0.1)
    );

    childList = createSwitchedChildList(childList, 0, 1);
    await tester.pumpWidget(
        SwitchingSliverListTest(children: childList, viewportFraction: 0.1)
    );
    expect(state0.hasBeenDisposed, false);
    expect(state1.hasBeenDisposed, true);
    expect(state2.hasBeenDisposed, false);
  });

  testWidgets('SliverList remove child from child list', (WidgetTester tester) async {
    List<Widget> childList= <Widget>[
      WidgetTest0(text: 'child 0', key: UniqueKey(), keepAlive: true),
      const WidgetTest1(text: 'child 1', keepAlive: true),
      WidgetTest2(text: 'child 2', key: UniqueKey()),
    ];
    await tester.pumpWidget(
        SwitchingSliverListTest(children: childList, viewportFraction: 0.1)
    );
    final _WidgetTest0State state0 = tester.state(find.byType(WidgetTest0));
    final _WidgetTest1State state1 = tester.state(find.byType(WidgetTest1));
    final _WidgetTest2State state2 = tester.state(find.byType(WidgetTest2));
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1'), findsOneWidget);
    expect(find.text('child 2'), findsOneWidget);

    childList = createSwitchedChildList(childList, 0, 1);
    childList.removeAt(2);
    await tester.pumpWidget(
        SwitchingSliverListTest(children: childList, viewportFraction: 0.1)
    );
    expect(find.text('child 0'), findsOneWidget);
    expect(find.text('child 1'), findsOneWidget);
    expect(find.text('child 2'), findsNothing);
    expect(state0.hasBeenDisposed, false);
    expect(state1.hasBeenDisposed, true);
    expect(state2.hasBeenDisposed, true);
  });
}

List<Widget> createSwitchedChildList(List<Widget> childList, int i, int j) {
  final Widget w = childList[i];
  childList[i] = childList[j];
  childList[j] = w;
  return List<Widget>.from(childList);
}

class SwitchingChildBuilderTest extends StatefulWidget {
  const SwitchingChildBuilderTest({
    this.children,
    Key key,
  }) : super(key: key);

  final List<Widget> children;

  @override
  _SwitchingChildBuilderTest createState() => _SwitchingChildBuilderTest();
}

class _SwitchingChildBuilderTest extends State<SwitchingChildBuilderTest> {
  List<Widget> children;
  Map<Key, int> _mapKeyToIndex;

  @override
  void initState() {
    super.initState();
    children = widget.children;
    _mapKeyToIndex = <Key, int>{};
    for (int index = 0; index < children.length; index += 1) {
      final Key key = children[index].key;
      if (key != null) {
        _mapKeyToIndex[key] = index;
      }
    }
  }

  @override
  void didUpdateWidget(SwitchingChildBuilderTest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children != widget.children) {
      children = widget.children;
      _mapKeyToIndex = <Key, int>{};
      for (int index = 0; index < children.length; index += 1) {
        final Key key = children[index].key;
        if (key != null) {
          _mapKeyToIndex[key] = index;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Container(
          height: 100,
          child: CustomScrollView(
            cacheExtent: 0,
            slivers: <Widget>[
              SliverFillViewport(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return children[index];
                  },
                  childCount: children.length,
                  findChildIndexCallback: (Key key) => _mapKeyToIndex[key] ?? -1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SwitchingChildListTest extends StatefulWidget {
  const SwitchingChildListTest({
    this.children,
    this.viewportFraction = 1.0,
    Key key,
  }) : super(key: key);

  final List<Widget> children;
  final double viewportFraction;

  @override
  _SwitchingChildListTest createState() => _SwitchingChildListTest();
}

class _SwitchingChildListTest extends State<SwitchingChildListTest> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Container(
          height: 100,
          child: CustomScrollView(
            cacheExtent: 0,
            slivers: <Widget>[
              SliverFillViewport(
                viewportFraction: widget.viewportFraction,
                delegate: SliverChildListDelegate(widget.children),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SwitchingSliverListTest extends StatefulWidget {
  const SwitchingSliverListTest({
    this.children,
    this.viewportFraction = 1.0,
    Key key,
  }) : super(key: key);

  final List<Widget> children;
  final double viewportFraction;

  @override
  _SwitchingSliverListTest createState() => _SwitchingSliverListTest();
}

class _SwitchingSliverListTest extends State<SwitchingSliverListTest> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Container(
          height: 100,
          child: CustomScrollView(
            cacheExtent: 0,
            slivers: <Widget>[
              SliverList(
                delegate: SliverChildListDelegate(widget.children),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WidgetTest0 extends StatefulWidget {
  const WidgetTest0({
    this.text,
    this.keepAlive = false,
    Key key,
  }) : super(key: key);

  final String text;
  final bool keepAlive;

  @override
  _WidgetTest0State createState() => _WidgetTest0State();
}

class _WidgetTest0State extends State<WidgetTest0> with AutomaticKeepAliveClientMixin{
  bool hasBeenDisposed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Text(widget.text);
  }

  @override
  void dispose() {
    hasBeenDisposed = true;
    super.dispose();
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}

class WidgetTest1 extends StatefulWidget {
  const WidgetTest1({
    this.text,
    this.keepAlive = false,
    Key key,
  }) : super(key: key);

  final String text;
  final bool keepAlive;

  @override
  _WidgetTest1State createState() => _WidgetTest1State();
}

class _WidgetTest1State extends State<WidgetTest1> with AutomaticKeepAliveClientMixin{
  bool hasBeenDisposed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Text(widget.text);
  }

  @override
  void dispose() {
    hasBeenDisposed = true;
    super.dispose();
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}

class WidgetTest2 extends StatefulWidget {
  const WidgetTest2({
    this.text,
    this.keepAlive = false,
    Key key,
  }) : super(key: key);

  final String text;
  final bool keepAlive;

  @override
  _WidgetTest2State createState() => _WidgetTest2State();
}

class _WidgetTest2State extends State<WidgetTest2> with AutomaticKeepAliveClientMixin{
  bool hasBeenDisposed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Text(widget.text);
  }

  @override
  void dispose() {
    hasBeenDisposed = true;
    super.dispose();
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}
