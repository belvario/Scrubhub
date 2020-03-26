import 'package:app/routes/home/screen.dart';
import 'package:app/routes/lab_supplies_have/screen.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '#MedSupplyDrive',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/have_lab_supplies': (context) => HaveLabSuppliesScreen(),
      },
    );
  }
}
