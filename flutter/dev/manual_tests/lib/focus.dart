// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() {
  if (!kIsWeb && Platform.isMacOS) {
    // TODO(gspencergoog): Update this when TargetPlatform includes macOS. https://github.com/flutter/flutter/issues/31366
    // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }

  runApp(const MaterialApp(
    title: 'Focus Demo',
    home: FocusDemo(),
  ));
}

class DemoButton extends StatefulWidget {
  const DemoButton({this.name, this.canRequestFocus = true, this.autofocus = false});

  final String name;
  final bool canRequestFocus;
  final bool autofocus;

  @override
  _DemoButtonState createState() => _DemoButtonState();
}

class _DemoButtonState extends State<DemoButton> {
  FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode(
      debugLabel: widget.name,
      canRequestFocus: widget.canRequestFocus,
    );
  }

  @override
  void dispose() {
    focusNode?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DemoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    focusNode.canRequestFocus = widget.canRequestFocus;
  }

  void _handleOnPressed() {
    focusNode.requestFocus();
    print('Button ${widget.name} pressed.');
    debugDumpFocusTree();
  }

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      focusNode: focusNode,
      autofocus: widget.autofocus,
      focusColor: Colors.red,
      hoverColor: Colors.blue,
      onPressed: () => _handleOnPressed(),
      child: Text(widget.name),
    );
  }
}

class FocusDemo extends StatefulWidget {
  const FocusDemo({Key key}) : super(key: key);

  @override
  _FocusDemoState createState() => _FocusDemoState();
}

class _FocusDemoState extends State<FocusDemo> {
  FocusNode outlineFocus;

  @override
  void initState() {
    super.initState();
    outlineFocus = FocusNode(debugLabel: 'Demo Focus Node');
  }

  @override
  void dispose() {
    outlineFocus.dispose();
    super.dispose();
  }

  bool _handleKeyPress(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      print('Scope got key event: ${event.logicalKey}, $node');
      print('Keys down: ${RawKeyboard.instance.keysPressed}');
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        debugDumpFocusTree();
        if (event.isShiftPressed) {
          print('Moving to previous.');
          node.previousFocus();
          return true;
        } else {
          print('Moving to next.');
          node.nextFocus();
          return true;
        }
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        node.focusInDirection(TraversalDirection.left);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        node.focusInDirection(TraversalDirection.right);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        node.focusInDirection(TraversalDirection.up);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        node.focusInDirection(TraversalDirection.down);
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DefaultFocusTraversal(
      policy: ReadingOrderTraversalPolicy(),
      child: FocusScope(
        debugLabel: 'Scope',
        onKey: _handleKeyPress,
        autofocus: true,
        child: DefaultTextStyle(
          style: textTheme.display1,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Focus Demo'),
            ),
            floatingActionButton: FloatingActionButton(
              child: const Text('+'),
              onPressed: () {},
            ),
            body: Center(
              child: Builder(builder: (BuildContext context) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
                        DemoButton(
                          name: 'One',
                          autofocus: true,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
                        DemoButton(name: 'Two'),
                        DemoButton(
                          name: 'Three',
                          canRequestFocus: false,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const <Widget>[
                        DemoButton(name: 'Four'),
                        DemoButton(name: 'Five'),
                        DemoButton(name: 'Six'),
                      ],
                    ),
                    OutlineButton(onPressed: () => print('pressed'), child: const Text('PRESS ME')),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(labelText: 'Enter Text', filled: true),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Enter Text',
                          filled: false,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
