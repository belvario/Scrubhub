import 'package:app/routes/lab_supplies_have/form.dart';
import 'package:flutter/material.dart';

class HaveLabSuppliesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('I Have Lab Supplies'),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: HaveLabSuppliesForm(),
      ),
    );
  }
}