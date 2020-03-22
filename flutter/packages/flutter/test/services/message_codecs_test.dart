// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This files contains message codec tests that are supported both on the Web
// and in the VM. For VM-only tests see message_codecs_vm_test.dart.

import 'dart:typed_data';

import 'package:flutter/services.dart';
import '../flutter_test_alternative.dart';
import 'message_codecs_testing.dart';

void main() {
  group('Binary codec', () {
    const MessageCodec<ByteData> binary = BinaryCodec();
    test('should encode and decode simple messages', () {
      checkEncodeDecode<ByteData>(binary, null);
      checkEncodeDecode<ByteData>(binary, ByteData(0));
      checkEncodeDecode<ByteData>(binary, ByteData(4)..setInt32(0, -7));
    });
  });
  group('String codec', () {
    const MessageCodec<String> string = StringCodec();
    test('should encode and decode simple messages', () {
      checkEncodeDecode<String>(string, null);
      checkEncodeDecode<String>(string, '');
      checkEncodeDecode<String>(string, 'hello');
      checkEncodeDecode<String>(string, 'special chars >\u263A\u{1F602}<');
    });
    test('ByteData with offset', () {
      const MessageCodec<String> string = StringCodec();
      final ByteData helloWorldByteData = string.encodeMessage('hello world');
      final ByteData helloByteData = string.encodeMessage('hello');

      final ByteData offsetByteData = ByteData.view(
          helloWorldByteData.buffer,
          helloByteData.lengthInBytes,
          helloWorldByteData.lengthInBytes - helloByteData.lengthInBytes,
      );

      expect(string.decodeMessage(offsetByteData), ' world');
    });
  });
  group('JSON message codec', () {
    const MessageCodec<dynamic> json = JSONMessageCodec();
    test('should encode and decode simple messages', () {
      checkEncodeDecode<dynamic>(json, null);
      checkEncodeDecode<dynamic>(json, true);
      checkEncodeDecode<dynamic>(json, false);
      checkEncodeDecode<dynamic>(json, 7);
      checkEncodeDecode<dynamic>(json, -7);
      checkEncodeDecode<dynamic>(json, 98742923489);
      checkEncodeDecode<dynamic>(json, -98742923489);
      checkEncodeDecode<dynamic>(json, 3.14);
      checkEncodeDecode<dynamic>(json, '');
      checkEncodeDecode<dynamic>(json, 'hello');
      checkEncodeDecode<dynamic>(json, 'special chars >\u263A\u{1F602}<');
    });
    test('should encode and decode composite message', () {
      final List<dynamic> message = <dynamic>[
        null,
        true,
        false,
        -707,
        -7000000007,
        -3.14,
        '',
        'hello',
        <dynamic>['nested', <dynamic>[]],
        <dynamic, dynamic>{'a': 'nested', 'b': <dynamic, dynamic>{}},
        'world',
      ];
      checkEncodeDecode<dynamic>(json, message);
    });
  });
  group('Standard message codec', () {
    const MessageCodec<dynamic> standard = StandardMessageCodec();
    test('should encode sizes correctly at boundary cases', () {
      checkEncoding<dynamic>(
        standard,
        Uint8List(253),
        <int>[8, 253, ...List<int>.filled(253, 0)],
      );
      checkEncoding<dynamic>(
        standard,
        Uint8List(254),
        <int>[8, 254, 254, 0, ...List<int>.filled(254, 0)],
      );
      checkEncoding<dynamic>(
        standard,
        Uint8List(0xffff),
        <int>[8, 254, 0xff, 0xff, ...List<int>.filled(0xffff, 0)],
      );
      checkEncoding<dynamic>(
        standard,
        Uint8List(0xffff + 1),
        <int>[8, 255, 0, 0, 1, 0, ...List<int>.filled(0xffff + 1, 0)],
      );
    });
    test('should encode and decode simple messages', () {
      checkEncodeDecode<dynamic>(standard, null);
      checkEncodeDecode<dynamic>(standard, true);
      checkEncodeDecode<dynamic>(standard, false);
      checkEncodeDecode<dynamic>(standard, 7);
      checkEncodeDecode<dynamic>(standard, -7);
      checkEncodeDecode<dynamic>(standard, 98742923489);
      checkEncodeDecode<dynamic>(standard, -98742923489);
      checkEncodeDecode<dynamic>(standard, 3.14);
      checkEncodeDecode<dynamic>(standard, double.infinity);
      checkEncodeDecode<dynamic>(standard, double.nan);
      checkEncodeDecode<dynamic>(standard, '');
      checkEncodeDecode<dynamic>(standard, 'hello');
      checkEncodeDecode<dynamic>(standard, 'special chars >\u263A\u{1F602}<');
    });
    test('should encode and decode composite message', () {
      final List<dynamic> message = <dynamic>[
        null,
        true,
        false,
        -707,
        -7000000007,
        -3.14,
        '',
        'hello',
        Uint8List.fromList(<int>[0xBA, 0x5E, 0xBA, 0x11]),
        Int32List.fromList(<int>[-0x7fffffff - 1, 0, 0x7fffffff]),
        null, // ensures the offset of the following list is unaligned.
        null, // ensures the offset of the following list is unaligned.
        Float64List.fromList(<double>[
          double.negativeInfinity,
          -double.maxFinite,
          -double.minPositive,
          -0.0,
          0.0,
          double.minPositive,
          double.maxFinite,
          double.infinity,
          double.nan,
        ]),
        <dynamic>['nested', <dynamic>[]],
        <dynamic, dynamic>{'a': 'nested', null: <dynamic, dynamic>{}},
        'world',
      ];
      checkEncodeDecode<dynamic>(standard, message);
    });
    test('should align doubles to 8 bytes', () {
      checkEncoding<dynamic>(
        standard,
        1.0,
        <int>[
          6, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0xf0, 0x3f,
        ],
      );
    });
  });
}
