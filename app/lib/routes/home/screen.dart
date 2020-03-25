import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('#MedSupplyDrive Home'),
      ),
      body: Center(
        child: RaisedButton(
          child: Text('I Have Supplies'),
          onPressed: () {
            Navigator.pushNamed(context, '/have_lab_supplies');
          },
        ),
      ),
    );
  }
}