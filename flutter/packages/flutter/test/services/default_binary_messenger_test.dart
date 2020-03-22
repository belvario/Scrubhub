// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ByteData _makeByteData(String str) {
    final List<int> list = utf8.encode(str);
    final ByteBuffer buffer =
        list is Uint8List ? list.buffer : Uint8List.fromList(list).buffer;
    return ByteData.view(buffer);
  }

  test('default binary messenger calls callback once', () async {
    int count = 0;
    const String channel = 'foo';
    ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        channel, _makeByteData('bar'), (ByteData message) async {
      count += 1;
      return null;
    });
    expect(count, equals(0));
    await ui.channelBuffers.drain(channel,
        (ByteData data, ui.PlatformMessageResponseCallback callback) {
      callback(null);
      return null;
    });
    expect(count, equals(1));
  });
}
