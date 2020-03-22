// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(yjbanov): enable Web when https://github.com/flutter/engine/pull/12747 rolls into the framework.
@TestOn('!chrome')

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class TestChannelBuffersFlutterBinding extends BindingBase with ServicesBinding {
}

void main() {
  ByteData _makeByteData(String str) {
    final List<int> list = utf8.encode(str);
    final ByteBuffer buffer = list is Uint8List ? list.buffer : Uint8List.fromList(list).buffer;
    return ByteData.view(buffer);
  }

  String _getString(ByteData data) {
    final ByteBuffer buffer = data.buffer;
    final List<int> list = buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    return utf8.decode(list);
  }

  test('does drain channel buffers', () async {
    const String channel = 'foo';
    final TestChannelBuffersFlutterBinding binding = TestChannelBuffersFlutterBinding();
    expect(binding.defaultBinaryMessenger, isNotNull);
    bool didCallCallback = false;
    final ui.PlatformMessageResponseCallback callback = (ByteData responseData) {
      didCallCallback = true;
    };
    const String payload = 'bar';
    final ByteData data = _makeByteData(payload);
    ui.channelBuffers.push(channel, data, callback);
    bool didDrainData = false;
    binding.defaultBinaryMessenger.setMessageHandler(channel, (ByteData message) async {
      expect(_getString(message), payload);
      didDrainData = true;
      return null;
    });
    // Flush the event queue.
    await Future<void>((){});
    expect(didDrainData, isTrue);
    expect(didCallCallback, isTrue);
  });
}
