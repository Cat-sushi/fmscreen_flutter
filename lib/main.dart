import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'single.dart';
import 'batch.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FMScreen ― Denial List Screener with Fuzzy Muching ―',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyAppHome(key: key),
    );
  }
}

class MyAppHome extends StatelessWidget {
  const MyAppHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        initialIndex: 0,
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            // primary: true,
            toolbarHeight: 24,
            title: const Text(
                'FMScreen ― Name Screener against Denial Lists with Fuzzy Mutching ―'),
            bottom: const TabBar(
              tabs: <Widget>[
                Tab(text: 'Interactictive Screening', height: 24),
                Tab(text: 'Batch Screening', height: 24),
              ],
            ),
          ),
          body: const TabBarView(children: [
            SingleScreen(),
            BatchScreen(),
          ]),
        ));
  }
}
