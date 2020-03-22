// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('LayoutBuilder parent size', (WidgetTester tester) async {
    Size layoutBuilderSize;
    final Key childKey = UniqueKey();
    final Key parentKey = UniqueKey();

    await tester.pumpWidget(
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100.0, maxHeight: 200.0),
          child: LayoutBuilder(
            key: parentKey,
            builder: (BuildContext context, BoxConstraints constraints) {
              layoutBuilderSize = constraints.biggest;
              return SizedBox(
                key: childKey,
                width: layoutBuilderSize.width / 2.0,
                height: layoutBuilderSize.height / 2.0,
              );
            },
          ),
        ),
      ),
    );

    expect(layoutBuilderSize, const Size(100.0, 200.0));
    final RenderBox parentBox = tester.renderObject(find.byKey(parentKey));
    expect(parentBox.size, equals(const Size(50.0, 100.0)));
    final RenderBox childBox = tester.renderObject(find.byKey(childKey));
    expect(childBox.size, equals(const Size(50.0, 100.0)));
  });

  testWidgets('SliverLayoutBuilder parent geometry', (WidgetTester tester) async {
    SliverConstraints parentConstraints1;
    SliverConstraints parentConstraints2;
    final Key childKey1 = UniqueKey();
    final Key parentKey1 = UniqueKey();
    final Key childKey2 = UniqueKey();
    final Key parentKey2 = UniqueKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverLayoutBuilder(
              key: parentKey1,
              builder: (BuildContext context, SliverConstraints constraint) {
                parentConstraints1 = constraint;
                return SliverPadding(key: childKey1, padding: const EdgeInsets.fromLTRB(1, 2, 3, 4));
              },
            ),
            SliverLayoutBuilder(
              key: parentKey2,
              builder: (BuildContext context, SliverConstraints constraint) {
                parentConstraints2 = constraint;
                return SliverPadding(key: childKey2, padding: const EdgeInsets.fromLTRB(5, 7, 11, 13));
              },
            ),
          ],
        ),
      ),
    );

    expect(parentConstraints1.crossAxisExtent, 800);
    expect(parentConstraints1.remainingPaintExtent, 600);

    expect(parentConstraints2.crossAxisExtent, 800);
    expect(parentConstraints2.remainingPaintExtent, 600 - 2 - 4);
    final RenderSliver parentSliver1 = tester.renderObject(find.byKey(parentKey1));
    final RenderSliver parentSliver2 = tester.renderObject(find.byKey(parentKey2));

    // scrollExtent == top + bottom.
    expect(parentSliver1.geometry.scrollExtent, 2 + 4);
    expect(parentSliver2.geometry.scrollExtent, 7 + 13);

    final RenderSliver childSliver1 = tester.renderObject(find.byKey(childKey1));
    final RenderSliver childSliver2 = tester.renderObject(find.byKey(childKey2));
    expect(childSliver1.geometry, parentSliver1.geometry);
    expect(childSliver2.geometry, parentSliver2.geometry);
  });

  testWidgets('LayoutBuilder stateful child', (WidgetTester tester) async {
    Size layoutBuilderSize;
    StateSetter setState;
    final Key childKey = UniqueKey();
    final Key parentKey = UniqueKey();
    double childWidth = 10.0;
    double childHeight = 20.0;

    await tester.pumpWidget(
      Center(
        child: LayoutBuilder(
          key: parentKey,
          builder: (BuildContext context, BoxConstraints constraints) {
            layoutBuilderSize = constraints.biggest;
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setter) {
                setState = setter;
                return SizedBox(
                  key: childKey,
                  width: childWidth,
                  height: childHeight,
                );
              }
            );
          },
        ),
      ),
    );

    expect(layoutBuilderSize, equals(const Size(800.0, 600.0)));
    RenderBox parentBox = tester.renderObject(find.byKey(parentKey));
    expect(parentBox.size, equals(const Size(10.0, 20.0)));
    RenderBox childBox = tester.renderObject(find.byKey(childKey));
    expect(childBox.size, equals(const Size(10.0, 20.0)));

    setState(() {
      childWidth = 100.0;
      childHeight = 200.0;
    });
    await tester.pump();
    parentBox = tester.renderObject(find.byKey(parentKey));
    expect(parentBox.size, equals(const Size(100.0, 200.0)));
    childBox = tester.renderObject(find.byKey(childKey));
    expect(childBox.size, equals(const Size(100.0, 200.0)));
  });

  testWidgets('SliverLayoutBuilder stateful descendants', (WidgetTester tester) async {
    StateSetter setState;
    double childWidth = 10.0;
    double childHeight = 20.0;
    final Key parentKey = UniqueKey();
    final Key childKey = UniqueKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverLayoutBuilder(
              key: parentKey,
              builder: (BuildContext context, SliverConstraints constraint) {
                return SliverToBoxAdapter(
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setter) {
                      setState = setter;
                      return SizedBox(
                        key: childKey,
                        width: childWidth,
                        height: childHeight,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    RenderBox childBox = tester.renderObject(find.byKey(childKey));
    RenderSliver parentSliver = tester.renderObject(find.byKey(parentKey));
    expect(childBox.size.width, 800);
    expect(childBox.size.height, childHeight);
    expect(parentSliver.geometry.scrollExtent, childHeight);
    expect(parentSliver.geometry.paintExtent, childHeight);

    setState(() {
      childWidth = 100.0;
      childHeight = 200.0;
    });

    await tester.pump();
    childBox = tester.renderObject(find.byKey(childKey));
    parentSliver = tester.renderObject(find.byKey(parentKey));
    expect(childBox.size.width, 800);
    expect(childBox.size.height, childHeight);
    expect(parentSliver.geometry.scrollExtent, childHeight);
    expect(parentSliver.geometry.paintExtent, childHeight);

    // Make child wider and higher than the viewport.
    setState(() {
      childWidth = 900.0;
      childHeight = 900.0;
    });

    await tester.pump();
    childBox = tester.renderObject(find.byKey(childKey));
    parentSliver = tester.renderObject(find.byKey(parentKey));
    expect(childBox.size.width, 800);
    expect(childBox.size.height, childHeight);
    expect(parentSliver.geometry.scrollExtent, childHeight);
    expect(parentSliver.geometry.paintExtent, 600);
  });

  testWidgets('LayoutBuilder stateful parent', (WidgetTester tester) async {
    Size layoutBuilderSize;
    StateSetter setState;
    final Key childKey = UniqueKey();
    double childWidth = 10.0;
    double childHeight = 20.0;

    await tester.pumpWidget(
      Center(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setter) {
            setState = setter;
            return SizedBox(
              width: childWidth,
              height: childHeight,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  layoutBuilderSize = constraints.biggest;
                  return SizedBox(
                    key: childKey,
                    width: layoutBuilderSize.width,
                    height: layoutBuilderSize.height,
                  );
                }
              ),
            );
          }
        ),
      ),
    );

    expect(layoutBuilderSize, equals(const Size(10.0, 20.0)));
    RenderBox box = tester.renderObject(find.byKey(childKey));
    expect(box.size, equals(const Size(10.0, 20.0)));

    setState(() {
      childWidth = 100.0;
      childHeight = 200.0;
    });
    await tester.pump();
    box = tester.renderObject(find.byKey(childKey));
    expect(box.size, equals(const Size(100.0, 200.0)));
  });

  testWidgets('LayoutBuilder and Inherited -- do not rebuild when not using inherited', (WidgetTester tester) async {
    int built = 0;
    final Widget target = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        built += 1;
        return Container();
      }
    );
    expect(built, 0);

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(400.0, 300.0)),
      child: target,
    ));
    expect(built, 1);

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(300.0, 400.0)),
      child: target,
    ));
    expect(built, 1);
  });

  testWidgets('LayoutBuilder and Inherited -- do rebuild when using inherited', (WidgetTester tester) async {
    int built = 0;
    final Widget target = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        built += 1;
        MediaQuery.of(context);
        return Container();
      }
    );
    expect(built, 0);

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(400.0, 300.0)),
      child: target,
    ));
    expect(built, 1);

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(300.0, 400.0)),
      child: target,
    ));
    expect(built, 2);
  });

  testWidgets('SliverLayoutBuilder and Inherited -- do not rebuild when not using inherited', (WidgetTester tester) async {
    int built = 0;
    final Widget target = Directionality(
      textDirection: TextDirection.ltr,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverLayoutBuilder(
            builder: (BuildContext context, SliverConstraints constraint) {
              built++;
              return SliverToBoxAdapter(child: Container());
            },
          ),
        ],
      ),
    );

    expect(built, 0);

    await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(400.0, 300.0)),
        child: target,
    ));
    expect(built, 1);

    await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(size: Size(300.0, 400.0)),
        child: target,
    ));
    expect(built, 1);
  });

  testWidgets('SliverLayoutBuilder and Inherited -- do rebuild when not using inherited',
    (WidgetTester tester) async {

      int built = 0;
      final Widget target = Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverLayoutBuilder(
              builder: (BuildContext context, SliverConstraints constraint) {
                built++;
                MediaQuery.of(context);
                return SliverToBoxAdapter(child: Container());
              },
            ),
          ],
        ),
      );

      expect(built, 0);

      await tester.pumpWidget(MediaQuery(
          data: const MediaQueryData(size: Size(400.0, 300.0)),
          child: target,
      ));
      expect(built, 1);

      await tester.pumpWidget(MediaQuery(
          data: const MediaQueryData(size: Size(300.0, 400.0)),
          child: target,
      ));
      expect(built, 2);
  });

  testWidgets('nested SliverLayoutBuilder', (WidgetTester tester) async {
    SliverConstraints parentConstraints1;
    SliverConstraints parentConstraints2;
    final Key childKey = UniqueKey();
    final Key parentKey1 = UniqueKey();
    final Key parentKey2 = UniqueKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverLayoutBuilder(
              key: parentKey1,
              builder: (BuildContext context, SliverConstraints constraint) {
                parentConstraints1 = constraint;
                return SliverLayoutBuilder(
                  key: parentKey2,
                  builder: (BuildContext context, SliverConstraints constraint) {
                    parentConstraints2 = constraint;
                    return SliverPadding(key: childKey, padding: const EdgeInsets.fromLTRB(1, 2, 3, 4));
                  },
                );
              },
            ),
          ],
        ),
      ),
    );

    expect(parentConstraints1, parentConstraints2);

    expect(parentConstraints1.crossAxisExtent, 800);
    expect(parentConstraints1.remainingPaintExtent, 600);

    final RenderSliver parentSliver1 = tester.renderObject(find.byKey(parentKey1));
    final RenderSliver parentSliver2 = tester.renderObject(find.byKey(parentKey2));
    // scrollExtent == top + bottom.
    expect(parentSliver1.geometry.scrollExtent, 2 + 4);

    final RenderSliver childSliver = tester.renderObject(find.byKey(childKey));
    expect(childSliver.geometry, parentSliver1.geometry);
    expect(parentSliver1.geometry, parentSliver2.geometry);
  });

  testWidgets('localToGlobal works with SliverLayoutBuilder', (WidgetTester tester) async {
    final Key childKey1 = UniqueKey();
    final Key childKey2 = UniqueKey();
    final ScrollController scrollController = ScrollController();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: scrollController,
          slivers: <Widget>[
            const SliverToBoxAdapter(
              child: SizedBox(height: 300),
            ),
            SliverLayoutBuilder(
              builder: (BuildContext context, SliverConstraints constraint) => SliverToBoxAdapter(
                child: SizedBox(key: childKey1, height: 200),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(key: childKey2, height: 100),
            ),
          ],
        ),
      ),
    );

    final RenderBox renderChild1 = tester.renderObject(find.byKey(childKey1));
    final RenderBox renderChild2 = tester.renderObject(find.byKey(childKey2));

    // Test with scrollController.scrollOffset = 0.
    expect(
      renderChild1.localToGlobal(const Offset(100, 100)),
      const Offset(100, 300.0 + 100),
    );

    expect(
      renderChild2.localToGlobal(const Offset(100, 100)),
      const Offset(100, 300.0 + 200 + 100),
    );

    scrollController.jumpTo(100);
    await tester.pump();
    expect(
      renderChild1.localToGlobal(const Offset(100, 100)),
      // -100 because the scroll offset is now 100.
      const Offset(100, 300.0 + 100 - 100),
    );

    expect(
      renderChild2.localToGlobal(const Offset(100, 100)),
      // -100 because the scroll offset is now 100.
      const Offset(100, 300.0 + 100 + 200 - 100),
    );
  });

  testWidgets('hitTest works within SliverLayoutBuilder', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    List<int> hitCounts = <int> [0, 0, 0];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: GestureDetector(onTap: () => hitCounts[0]++),
                ),
              ),
              SliverLayoutBuilder(
                builder: (BuildContext context, SliverConstraints constraint) => SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: GestureDetector(onTap: () => hitCounts[1]++),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: GestureDetector(onTap: () => hitCounts[2]++),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Tap item 1.
    await tester.tapAt(const Offset(300, 50.0 + 100));
    await tester.pump();
    expect(hitCounts, const <int> [1, 0, 0]);

    // Tap item 2.
    await tester.tapAt(const Offset(300, 50.0 + 100 + 200));
    await tester.pump();
    expect(hitCounts, const <int> [1, 1, 0]);

    // Tap item 3. Shift the touch point up to ensure the touch lands within the viewport.
    await tester.tapAt(const Offset(300, 50.0 + 200 + 200 + 10));
    await tester.pump();
    expect(hitCounts, const <int> [1, 1, 1]);

    // Scrolling doesn't break it.
    hitCounts = <int> [0, 0, 0];
    scrollController.jumpTo(100);
    await tester.pump();

    // Tap item 1.
    await tester.tapAt(const Offset(300, 50.0 + 100 - 100));
    await tester.pump();
    expect(hitCounts, const <int> [1, 0, 0]);

    // Tap item 2.
    await tester.tapAt(const Offset(300, 50.0 + 100 + 200 - 100));
    await tester.pump();
    expect(hitCounts, const <int> [1, 1, 0]);

    // Tap item 3.
    await tester.tapAt(const Offset(300, 50.0 + 100 + 200 + 200 - 100));
    await tester.pump();
    expect(hitCounts, const <int> [1, 1, 1]);

    // Tapping outside of the viewport shouldn't do anything.
    await tester.tapAt(const Offset(300, 1));
    await tester.pump();
    expect(hitCounts, const <int> [1, 1, 1]);

    await tester.tapAt(const Offset(300, 599));
    await tester.pump();
    expect(hitCounts, const <int> [1, 1, 1]);

    await tester.tapAt(const Offset(1, 100));
    await tester.pump();
    expect(hitCounts, const <int> [1, 1, 1]);

    await tester.tapAt(const Offset(799, 100));
    await tester.pump();
    expect(hitCounts, const <int> [1, 1, 1]);

    // Tap the no-content area in the viewport shouldn't do anything
    hitCounts = <int> [0, 0, 0];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          controller: scrollController,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: GestureDetector(onTap: () => hitCounts[0]++),
              ),
            ),
            SliverLayoutBuilder(
              builder: (BuildContext context, SliverConstraints constraint) => SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                  child: GestureDetector(onTap: () => hitCounts[1]++),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: GestureDetector(onTap: () => hitCounts[2]++),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tapAt(const Offset(300, 301));
    await tester.pump();
    expect(hitCounts, const <int> [0, 0, 0]);
  });
}
