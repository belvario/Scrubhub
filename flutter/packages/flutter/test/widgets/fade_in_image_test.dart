// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import '../painting/image_data.dart';
import '../painting/image_test_utils.dart';

const Duration animationDuration = Duration(milliseconds: 50);

class FadeInImageParts {
  const FadeInImageParts(this.fadeInImageElement, this.placeholder, this.target)
      : assert(fadeInImageElement != null),
        assert(target != null);

  final ComponentElement fadeInImageElement;
  final FadeInImageElements placeholder;
  final FadeInImageElements target;

  State get state {
    StatefulElement animatedFadeOutFadeInElement;
    fadeInImageElement.visitChildren((Element child) {
      expect(animatedFadeOutFadeInElement, isNull);
      animatedFadeOutFadeInElement = child;
    });
    expect(animatedFadeOutFadeInElement, isNotNull);
    return animatedFadeOutFadeInElement.state;
  }

  Element get semanticsElement {
    Element result;
    fadeInImageElement.visitChildren((Element child) {
      if (child.widget is Semantics)
        result = child;
    });
    return result;
  }
}

class FadeInImageElements {
  const FadeInImageElements(this.rawImageElement, this.fadeTransitionElement);

  final Element rawImageElement;
  final Element fadeTransitionElement;

  RawImage get rawImage => rawImageElement.widget;
  FadeTransition get fadeTransition => fadeTransitionElement?.widget;
  double get opacity => fadeTransition == null ? 1 : fadeTransition.opacity.value;
}

class LoadTestImageProvider extends ImageProvider<dynamic> {
  LoadTestImageProvider(this.provider);

  final ImageProvider provider;

  ImageStreamCompleter testLoad(dynamic key, DecoderCallback decode) {
    return provider.load(key, decode);
  }

  @override
  Future<dynamic> obtainKey(ImageConfiguration configuration) {
    return null;
  }

  @override
  ImageStreamCompleter load(dynamic key, DecoderCallback decode) {
    return null;
  }
}

FadeInImageParts findFadeInImage(WidgetTester tester) {
  final List<FadeInImageElements> elements = <FadeInImageElements>[];
  final Iterable<Element> rawImageElements = tester.elementList(find.byType(RawImage));
  ComponentElement fadeInImageElement;
  for (Element rawImageElement in rawImageElements) {
    Element fadeTransitionElement;
    rawImageElement.visitAncestorElements((Element ancestor) {
      if (ancestor.widget is FadeTransition) {
        fadeTransitionElement = ancestor;
      } else if (ancestor.widget is FadeInImage) {
        if (fadeInImageElement == null) {
          fadeInImageElement = ancestor;
        } else {
          expect(fadeInImageElement, same(ancestor));
        }
        return false;
      }
      return true;
    });
    expect(fadeInImageElement, isNotNull);
    elements.add(FadeInImageElements(rawImageElement, fadeTransitionElement));
  }
  if (elements.length == 2) {
    return FadeInImageParts(fadeInImageElement, elements.last, elements.first);
  } else {
    expect(elements, hasLength(1));
    return FadeInImageParts(fadeInImageElement, null, elements.first);
  }
}

Future<void> main() async {
  // These must run outside test zone to complete
  final ui.Image targetImage = await createTestImage();
  final ui.Image placeholderImage = await createTestImage();
  final ui.Image replacementImage = await createTestImage();

  group('FadeInImage', () {
    testWidgets('animates an uncached image', (WidgetTester tester) async {
      final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
      final TestImageProvider imageProvider = TestImageProvider(targetImage);

      await tester.pumpWidget(FadeInImage(
        placeholder: placeholderProvider,
        image: imageProvider,
        fadeOutDuration: animationDuration,
        fadeInDuration: animationDuration,
        fadeOutCurve: Curves.linear,
        fadeInCurve: Curves.linear,
        excludeFromSemantics: true,
      ));

      expect(findFadeInImage(tester).placeholder.rawImage.image, null);
      expect(findFadeInImage(tester).target.rawImage.image, null);

      placeholderProvider.complete();
      await tester.pump();
      expect(findFadeInImage(tester).placeholder.rawImage.image, same(placeholderImage));
      expect(findFadeInImage(tester).target.rawImage.image, null);

      imageProvider.complete();
      await tester.pump();
      for (int i = 0; i < 5; i += 1) {
        final FadeInImageParts parts = findFadeInImage(tester);
        expect(parts.placeholder.rawImage.image, same(placeholderImage));
        expect(parts.target.rawImage.image, same(targetImage));
        expect(parts.placeholder.opacity, moreOrLessEquals(1 - i / 5));
        expect(parts.target.opacity, 0);
        await tester.pump(const Duration(milliseconds: 10));
      }

      for (int i = 0; i < 5; i += 1) {
        final FadeInImageParts parts = findFadeInImage(tester);
        expect(parts.placeholder.rawImage.image, same(placeholderImage));
        expect(parts.target.rawImage.image, same(targetImage));
        expect(parts.placeholder.opacity, 0);
        expect(parts.target.opacity, moreOrLessEquals(i / 5));
        await tester.pump(const Duration(milliseconds: 10));
      }

      await tester.pumpWidget(FadeInImage(
        placeholder: placeholderProvider,
        image: imageProvider,
      ));
      expect(findFadeInImage(tester).target.rawImage.image, same(targetImage));
      expect(findFadeInImage(tester).target.opacity, 1);
    });

    testWidgets('shows a cached image immediately when skipFadeOnSynchronousLoad=true', (WidgetTester tester) async {
      final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
      final TestImageProvider imageProvider = TestImageProvider(targetImage);
      imageProvider.resolve(FakeImageConfiguration());
      imageProvider.complete();

      await tester.pumpWidget(FadeInImage(
        placeholder: placeholderProvider,
        image: imageProvider,
      ));

      expect(findFadeInImage(tester).target.rawImage.image, same(targetImage));
      expect(findFadeInImage(tester).placeholder, isNull);
      expect(findFadeInImage(tester).target.opacity, 1);
    });

    testWidgets('handles updating the placeholder image', (WidgetTester tester) async {
      final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
      final TestImageProvider secondPlaceholderProvider = TestImageProvider(replacementImage);
      final TestImageProvider imageProvider = TestImageProvider(targetImage);

      await tester.pumpWidget(FadeInImage(
        placeholder: placeholderProvider,
        image: imageProvider,
        fadeOutDuration: animationDuration,
        fadeInDuration: animationDuration,
        excludeFromSemantics: true,
      ));

      final State state = findFadeInImage(tester).state;
      placeholderProvider.complete();
      await tester.pump();
      expect(findFadeInImage(tester).placeholder.rawImage.image, same(placeholderImage));

      await tester.pumpWidget(FadeInImage(
        placeholder: secondPlaceholderProvider,
        image: imageProvider,
        fadeOutDuration: animationDuration,
        fadeInDuration: animationDuration,
        excludeFromSemantics: true,
      ));

      secondPlaceholderProvider.complete();
      await tester.pump();
      expect(findFadeInImage(tester).placeholder.rawImage.image, same(replacementImage));
      expect(findFadeInImage(tester).state, same(state));
    });

    testWidgets('re-fades in the image when the target image is updated', (WidgetTester tester) async {
      final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
      final TestImageProvider imageProvider = TestImageProvider(targetImage);
      final TestImageProvider secondImageProvider = TestImageProvider(replacementImage);

      await tester.pumpWidget(FadeInImage(
        placeholder: placeholderProvider,
        image: imageProvider,
        fadeOutDuration: animationDuration,
        fadeInDuration: animationDuration,
        excludeFromSemantics: true,
      ));

      final State state = findFadeInImage(tester).state;
      placeholderProvider.complete();
      imageProvider.complete();
      await tester.pump();
      await tester.pump(animationDuration * 2);

      await tester.pumpWidget(FadeInImage(
        placeholder: placeholderProvider,
        image: secondImageProvider,
        fadeOutDuration: animationDuration,
        fadeInDuration: animationDuration,
        excludeFromSemantics: true,
      ));

      secondImageProvider.complete();
      await tester.pump();

      expect(findFadeInImage(tester).target.rawImage.image, same(replacementImage));
      expect(findFadeInImage(tester).state, same(state));
      expect(findFadeInImage(tester).placeholder.opacity, moreOrLessEquals(1));
      expect(findFadeInImage(tester).target.opacity, moreOrLessEquals(0));
      await tester.pump(animationDuration);
      expect(findFadeInImage(tester).placeholder.opacity, moreOrLessEquals(0));
      expect(findFadeInImage(tester).target.opacity, moreOrLessEquals(0));
      await tester.pump(animationDuration);
      expect(findFadeInImage(tester).placeholder.opacity, moreOrLessEquals(0));
      expect(findFadeInImage(tester).target.opacity, moreOrLessEquals(1));
    });

    testWidgets('doesn\'t interrupt in-progress animation when animation values are updated', (WidgetTester tester) async {
      final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
      final TestImageProvider imageProvider = TestImageProvider(targetImage);

      await tester.pumpWidget(FadeInImage(
        placeholder: placeholderProvider,
        image: imageProvider,
        fadeOutDuration: animationDuration,
        fadeInDuration: animationDuration,
        excludeFromSemantics: true,
      ));

      final State state = findFadeInImage(tester).state;
      placeholderProvider.complete();
      imageProvider.complete();
      await tester.pump();
      await tester.pump(animationDuration);

      await tester.pumpWidget(FadeInImage(
        placeholder: placeholderProvider,
        image: imageProvider,
        fadeOutDuration: animationDuration * 2,
        fadeInDuration: animationDuration * 2,
        excludeFromSemantics: true,
      ));

      expect(findFadeInImage(tester).state, same(state));
      expect(findFadeInImage(tester).placeholder.opacity, moreOrLessEquals(0));
      expect(findFadeInImage(tester).target.opacity, moreOrLessEquals(0));
      await tester.pump(animationDuration);
      expect(findFadeInImage(tester).placeholder.opacity, moreOrLessEquals(0));
      expect(findFadeInImage(tester).target.opacity, moreOrLessEquals(1));
    });

    group(ImageProvider, () {

      testWidgets('memory placeholder cacheWidth and cacheHeight is passed through', (WidgetTester tester) async {
        final Uint8List testBytes = Uint8List.fromList(kTransparentImage);
        final FadeInImage image = FadeInImage.memoryNetwork(
          placeholder: testBytes,
          image: 'test.com',
          placeholderCacheWidth: 20,
          placeholderCacheHeight: 30,
          imageCacheWidth: 40,
          imageCacheHeight: 50,
        );

        bool called = false;
        final DecoderCallback decode = (Uint8List bytes, {int cacheWidth, int cacheHeight}) {
          expect(cacheWidth, 20);
          expect(cacheHeight, 30);
          called = true;
          return PaintingBinding.instance.instantiateImageCodec(bytes, cacheWidth: cacheWidth, cacheHeight: cacheHeight);
        };
        final ImageProvider resizeImage = image.placeholder;
        expect(image.placeholder, isA<ResizeImage>());
        expect(called, false);
        final LoadTestImageProvider testProvider = LoadTestImageProvider(image.placeholder);
        testProvider.testLoad(await resizeImage.obtainKey(ImageConfiguration.empty), decode);
        expect(called, true);
      });

      testWidgets('do not resize when null cache dimensions', (WidgetTester tester) async {
        final Uint8List testBytes = Uint8List.fromList(kTransparentImage);
        final FadeInImage image = FadeInImage.memoryNetwork(
          placeholder: testBytes,
          image: 'test.com',
        );

        bool called = false;
        final DecoderCallback decode = (Uint8List bytes, {int cacheWidth, int cacheHeight}) {
          expect(cacheWidth, null);
          expect(cacheHeight, null);
          called = true;
          return PaintingBinding.instance.instantiateImageCodec(bytes, cacheWidth: cacheWidth, cacheHeight: cacheHeight);
        };
        // image.placeholder should be an instance of MemoryImage instead of ResizeImage
        final ImageProvider memoryImage = image.placeholder;
        expect(image.placeholder, isA<MemoryImage>());
        expect(called, false);
        final LoadTestImageProvider testProvider = LoadTestImageProvider(image.placeholder);
        testProvider.testLoad(await memoryImage.obtainKey(ImageConfiguration.empty), decode);
        expect(called, true);
      });
    });

    group('semantics', () {
      testWidgets('only one Semantics node appears within FadeInImage', (WidgetTester tester) async {
        final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
        final TestImageProvider imageProvider = TestImageProvider(targetImage);

        await tester.pumpWidget(FadeInImage(
          placeholder: placeholderProvider,
          image: imageProvider,
        ));

        expect(find.byType(Semantics), findsOneWidget);
      });

      testWidgets('is excluded if excludeFromSemantics is true', (WidgetTester tester) async {
        final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
        final TestImageProvider imageProvider = TestImageProvider(targetImage);

        await tester.pumpWidget(FadeInImage(
          placeholder: placeholderProvider,
          image: imageProvider,
          excludeFromSemantics: true,
        ));

        expect(find.byType(Semantics), findsNothing);
      });

      group('label', () {
        const String imageSemanticText = 'Test image semantic label';

        testWidgets('defaults to image label if placeholder label is unspecified', (WidgetTester tester) async {
          Semantics semanticsWidget() => tester.widget(find.byType(Semantics));

          final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
          final TestImageProvider imageProvider = TestImageProvider(targetImage);

          await tester.pumpWidget(Directionality(
            textDirection: TextDirection.ltr,
            child: FadeInImage(
              placeholder: placeholderProvider,
              image: imageProvider,
              fadeOutDuration: animationDuration,
              fadeInDuration: animationDuration,
              imageSemanticLabel: imageSemanticText,
            ),
          ));

          placeholderProvider.complete();
          await tester.pump();
          expect(semanticsWidget().properties.label, imageSemanticText);

          imageProvider.complete();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 51));
          expect(semanticsWidget().properties.label, imageSemanticText);
        });

        testWidgets('is empty without any specified semantics labels', (WidgetTester tester) async {
          Semantics semanticsWidget() => tester.widget(find.byType(Semantics));

          final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
          final TestImageProvider imageProvider = TestImageProvider(targetImage);

          await tester.pumpWidget(FadeInImage(
              placeholder: placeholderProvider,
              image: imageProvider,
              fadeOutDuration: animationDuration,
              fadeInDuration: animationDuration,
          ));

          placeholderProvider.complete();
          await tester.pump();
          expect(semanticsWidget().properties.label, isEmpty);

          imageProvider.complete();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 51));
          expect(semanticsWidget().properties.label, isEmpty);
        });
      });
    });
  });
}
