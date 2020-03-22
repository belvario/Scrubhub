// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains tests that are only supported by the Dart VM. For
// example, on the Web there's no way to express large integers.
@TestOn('!chrome')

import 'dart:typed_data';

import 'package:flutter/services.dart';
import '../flutter_test_alternative.dart';
import 'message_codecs_testing.dart';

void main() {
  group('JSON message codec', () {
    const MessageCodec<dynamic> json = JSONMessageCodec();
    test('should encode and decode big numbers', () {
      checkEncodeDecode<dynamic>(json, 9223372036854775807);
      checkEncodeDecode<dynamic>(json, -9223372036854775807);
    });
    test('should encode and decode list with a big number', () {
      final List<dynamic> message = <dynamic>[-7000000000000000007];
      checkEncodeDecode<dynamic>(json, message);
    });
  });
  group('Standard message codec', () {
    const MessageCodec<dynamic> standard = StandardMessageCodec();
    test('should encode integers correctly at boundary cases', () {
      checkEncoding<dynamic>(
        standard,
        -0x7fffffff - 1,
        <int>[3, 0x00, 0x00, 0x00, 0x80],
      );
      checkEncoding<dynamic>(
        standard,
        -0x7fffffff - 2,
        <int>[4, 0xff, 0xff, 0xff, 0x7f, 0xff, 0xff, 0xff, 0xff],
      );
      checkEncoding<dynamic>(
        standard,
        0x7fffffff,
        <int>[3, 0xff, 0xff, 0xff, 0x7f],
      );
      checkEncoding<dynamic>(
        standard,
        0x7fffffff + 1,
        <int>[4, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00],
      );
      checkEncoding<dynamic>(
        standard,
        -0x7fffffffffffffff - 1,
        <int>[4, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80],
      );
      checkEncoding<dynamic>(
        standard,
        -0x7fffffffffffffff - 2,
        <int>[4, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f],
      );
      checkEncoding<dynamic>(
        standard,
        0x7fffffffffffffff,
        <int>[4, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f],
      );
      checkEncoding<dynamic>(
        standard,
        0x7fffffffffffffff + 1,
        <int>[4, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80],
      );
    });
    test('should encode and decode big numbers', () {
      checkEncodeDecode<dynamic>(standard, 9223372036854775807);
      checkEncodeDecode<dynamic>(standard, -9223372036854775807);
    });
    test('should encode and decode a list containing big numbers', () {
      final List<dynamic> message = <dynamic>[
        -7000000000000000007,
        Int64List.fromList(
            <int>[-0x7fffffffffffffff - 1, 0, 0x7fffffffffffffff]),
      ];
      checkEncodeDecode<dynamic>(standard, message);
    });
  });
}
