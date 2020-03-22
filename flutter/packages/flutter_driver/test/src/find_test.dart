// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/src/common/find.dart';

import '../common.dart';

void main() {
  test('Ancestor finder serialize', () {
    const SerializableFinder of = ByType('Text');
    final SerializableFinder matching = ByValueKey('hello');

    final Ancestor a = Ancestor(
      of: of,
      matching: matching,
      matchRoot: true,
      firstMatchOnly: true,
    );
    expect(a.serialize(), <String, String>{
      'finderType': 'Ancestor',
      'of': '{"finderType":"ByType","type":"Text"}',
      'matching': '{"finderType":"ByValueKey","keyValueString":"hello","keyValueType":"String"}',
      'matchRoot': 'true',
      'firstMatchOnly': 'true',
    });
  });

  test('Ancestor finder deserialize', () {
    final Map<String, String> serialized = <String, String>{
      'finderType': 'Ancestor',
      'of': '{"finderType":"ByType","type":"Text"}',
      'matching': '{"finderType":"ByValueKey","keyValueString":"hello","keyValueType":"String"}',
      'matchRoot': 'true',
      'firstMatchOnly': 'true',
    };

    final Ancestor a = Ancestor.deserialize(serialized);
    expect(a.of, isA<ByType>());
    expect(a.matching, isA<ByValueKey>());
    expect(a.matchRoot, isTrue);
    expect(a.firstMatchOnly, isTrue);
  });

  test('Descendant finder serialize', () {
    const SerializableFinder of = ByType('Text');
    final SerializableFinder matching = ByValueKey('hello');

    final Descendant a = Descendant(
      of: of,
      matching: matching,
      matchRoot: true,
      firstMatchOnly: true,
    );
    expect(a.serialize(), <String, String>{
      'finderType': 'Descendant',
      'of': '{"finderType":"ByType","type":"Text"}',
      'matching': '{"finderType":"ByValueKey","keyValueString":"hello","keyValueType":"String"}',
      'matchRoot': 'true',
      'firstMatchOnly': 'true',
    });
  });

  test('Descendant finder deserialize', () {
    final Map<String, String> serialized = <String, String>{
      'finderType': 'Descendant',
      'of': '{"finderType":"ByType","type":"Text"}',
      'matching': '{"finderType":"ByValueKey","keyValueString":"hello","keyValueType":"String"}',
      'matchRoot': 'true',
      'firstMatchOnly': 'true',
    };

    final Descendant a = Descendant.deserialize(serialized);
    expect(a.of, isA<ByType>());
    expect(a.matching, isA<ByValueKey>());
    expect(a.matchRoot, isTrue);
    expect(a.firstMatchOnly, isTrue);
  });
}
