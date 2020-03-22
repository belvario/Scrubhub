// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'headings_constants.dart';
export 'headings_constants.dart';

/// A test page with an app bar and some body text for testing heading flags.
class HeadingsPage extends StatelessWidget {
  static const ValueKey<String> _appBarTitleKey = ValueKey<String>(appBarTitleKeyValue);
  static const ValueKey<String> _bodyTextKey = ValueKey<String>(bodyTextKeyValue);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(key: ValueKey<String>('back')),
        title: const Text('Heading', key: _appBarTitleKey),
      ),
      body: const Center(
        child: Text('Body text', key: _bodyTextKey),
      ),
    );
  }
}
