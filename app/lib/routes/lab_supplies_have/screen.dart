import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class HaveLabSuppliesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Have Lab Supplies'),
      ),
      body: Center(
        child: RaisedButton(
          child: Text('Submit'),
          onPressed: () {
            // Navigate to the second screen when tapped.
          },
        ),
      ),
    );
  }
}