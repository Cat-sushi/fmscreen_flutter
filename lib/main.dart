import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:window_location_href/window_location_href.dart';

import 'single.dart';
import 'batch.dart';

String scheme = 'http';
String host = 'localhost';
int port = 8080;

final urlRegExp = RegExp(r'(https?)://([\w\d.]+)(:(\d+))?/');

void main() {
  if (href != null) {
    var match = urlRegExp.firstMatch(href!);
    scheme = match!.group(1)!;
    host = match.group(2)!;
    if (match.group(4) != null) {
      port = int.tryParse(match.group(4)!) ?? (scheme == 'http' ? 80 : 443);
    } else {
      port = scheme == 'http' ? 80 : 443;
    }
  }

  setUrlStrategy(PathUrlStrategy());
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FMScreen',
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
                'FMScreen ― Name Screener against Denial Lists with Fuzzy Matcing ―'),
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
