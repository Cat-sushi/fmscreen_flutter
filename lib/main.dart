// Copyright 2022, 2023 Yako
// This code is licensed under MIT license (see LICENSE for details)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:window_location_href/window_location_href.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

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

  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JunoScreen',
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.blue,
        textTheme:
            GoogleFonts.getTextTheme('Noto Sans', Theme.of(context).textTheme),
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
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: SafeArea(
              child: AppBar(
                toolbarHeight: 32,
                title: const Text(
                    'JunoScreen ― Name Screener against Denial Lists with Fuzzy Matcing ―'),
                actionsIconTheme: const IconThemeData(color: Colors.white),
                actions: const [MoreMenueWidiget()],
                bottom: const TabBar(
                  tabs: <Widget>[
                    Tab(text: 'Interactictive Screening', height: 24),
                    Tab(text: 'Batch Screening', height: 24),
                  ],
                ),
              ),
            ),
          ),
          body: const TabBarView(children: [
            SingleScreen(),
            BatchScreen(),
          ]),
        ));
  }
}

class MoreMenueWidiget extends StatelessWidget {
  const MoreMenueWidiget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, size: 18),
      itemBuilder: (context) {
        return <PopupMenuEntry>[
          const PopupMenuItem(value: 'description', child: Text('Description')),
          const PopupMenuDivider(),
          const PopupMenuItem(
              value: 'general', child: Text('Usage - General -')),
          const PopupMenuItem(
              value: 'intaractive',
              child: Text('Usage - Interactive Screening -')),
          const PopupMenuItem(
              value: 'batch', child: Text('Usage - Batch Screening -')),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'lists', child: Text('Denial Lists')),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'license', child: Text('License and Repositories')),
        ];
      },
      onSelected: (value) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: MarkdownBody(
              data: helps[value]!,
              onTapLink: (text, href, title) => launchUrlString(href!),
              selectable: true,
            ),
          ),
        ),
      ),
    );
  }
}

const helps = <String, String>{
  'description': '''
# Description

This is a system of name screening against denial lists such as US EAR Entity List.
See "Denaial Lists".

## Features

- Term fuzzy matching using Levenshtein distance.
- Divided query terms matching with single list term.
- Pertial terms matching.
- Disordered terms matching.
- Score based filtering respecting term similarity, term order, and term importance of IDF.
- Exact matching mode disabling fuzzy matchings for reducing false positives in some cases.
- Accepting Latin characters, Chinese characters, Katakana characters, and others.
- Canonicalaization of traditioanal and simplified Chinese characters, and others.
  This makes matching insensitive to character simplification.
- Canonicalaization of spelling variants of legal entity types such as "Limitd" and "Ltd.".
  This makes matching insensitive to spelling variants of legal entity types.
- White queries for avoiding screening your company itself and consequent false positives.
- Results cache for time performance.
- Interactive Screening.
- PDF download.
- Batch Screening.
- White Results for skiping check of false positives.
- And others.
''',
  'general': '''
# Usage ― General ―

## Recomended Input

- Official full name is recommended.
- Discriminating keyword is OK, but too short keyword might cause massive false positives.

## Exact Matching

**Note**: Do not use exact matching for names with orthographical variants.

Embrace whole input string with double-quates.
This disables,

- Term fuzzy matching
- Pertial terms matching
- Disordered terms matching

But, keeps enable,

- Normaliztion
  - Captalization
  - White space normalization
  - Unicode normalization
- Canonicalization of traditional/ simplified Chinese characters
- Canonicalization of variants of spelling of legal entity types

In other words, only items with score of 100 will be listed out.

## Item Identification

There are no permanent uniform identifiers of items, other than the normalized names.

Use exact matching with narmalized names to retreave the detected items.

''',
  'intaractive': '''
# Usage ― Intractive Screening ―

- "Preprocessed" is a set of extracted "words" from preprocess.
  Preprocess includes canonicalization of traditional/ simplified Chinese characters,
  canonicalization of variants of spelling of legal entyty types, and others.
- "Preprocessed" is marked "Exact" when the input string is embraced with double-quates.
- "Preprocessed" is marked "Fallen Back" when some termes of preprocessed are removed for some peformance reasons,
  in some very rare cases.
- "Query Score" means the discrimination of input strings.
  Input strings with low query score might cause massive false positives,
  while high query score does not necessarily mean a good input string.
- "Start" means Date/Time of starting the screening.
- "Duration" means the internal hold time in seconds in the server for screening.
- "DB Ver.", database version, means the Date/Time when the database from Denial Lists is created.
  The difference of database version donesn't necesarilly mean some of Denial Lists are modifined.
- "Server ID" is just for your information. This is the thread (Dart Isolate) ID in the server.
- "Message" is the message from the server. It's just for your information.
- The left pain contains the best matched normalized name of each detected item of Denial Lists,
  with matching score and the code of list.
- The right pain contains the details of each detected item.
- Click a detected item in the left pain to scroll the right pain to the details of the item,
  and vice-versa.
- Click [Get PDF] button to obtain detected items list in PDF format.
  The PDF file doesn't contain the details of the items.
''',
  'batch': '''
# Usage ― Batch Screening ―

## UI

- Make a name list for screening in CSV format with name of "names.csv".
- Click [Select Batch Directory] button.
- With opened file picker, select the directory containing the "names.csv".
- "results.csv" and "log.txt" will be placed in the same directory.

## Name List Format

"names.csv" is in CSV  format.

|Column|Description|
|---:|:---|
|1st|Every one line contains one name for screening.|
|2nd|You can optionally specify a transaction ID for each line. See "White Results" section.|

## Results Format

"results.csv" is in CSV format.

|Column|Description|
|---:|:---|
|1st|The number of the row in "names.csv"|
|2nd|The transaction ID. See the "White Results" section.|
|3rd|The name for screening. Normalized.|
|4th|The matching score.|
|5th|The code of list|
|6th|The best matched name of each detected item. Normalized.|
|7th|The flag of checked. See the "White Results" section.|
|8th|The Date/Time of screening.|
|9th|The version of the database made from the Denial Lists.|
|10th|The Date/Time of the first detection of the item with same name for screening, transaction ID, code of list, and best matched name of detected item. See the "White Results" section.|

## White Results

White Results are useful to skip redundant checks for false positives.

A file of results from previous batch screening can be used as White Reults with following steps,

- Rename "results.csv" to "white_results.csv"
- Turn the 7th (the flag of checked) column from "false" to "true"
- Place the "white_results.csv" at same directory of "names.csv"
- Kick the next batch screening.

Each detected item which is already listed in White Results with same name for screening, transaction ID,
code of list, and best matched name of the item will be marked "true" in 7th column,
and the 10th (the Date/Time of first detect) column will be copied from that of the item in the White Results.
''',
  'lists': '''
# Contained Denial Lists

|List Name|Code of Denial List|
|:---|:---:|
|Capta List (CAP) - Treasury Department|CAP|
|Denied Persons List (DPL) - Bureau of Industry and Security|DPL|
|Entity List (EL) - Bureau of Industry and Security|EL|
|Foreign Sanctions Evaders (FSE) - Treasury Department|FSE|
|ITAR Debarred (DTC) - State Department|DTC|
|Military End User (MEU) List - Bureau of Industry and Security|MEU|
|Non-SDN Chinese Military-Industrial Complex Companies List (CMIC) - Treasury Department|CMIC|
|Non-SDN Menu-Based Sanctions List (NS-MBS List) - Treasury Department|MBS|
|Nonproliferation Sanctions (ISN) - State Department|ISN|
|Sectoral Sanctions Identifications List (SSI) - Treasury Department|SSI|
|Specially Designated Nationals (SDN) - Treasury Department|SDN|
|Unverified List (UVL) - Bureau of Industry and Security|UVL|
|Foreigh End User List (EUL) - Ministry of Economy, Trade and Industry, Japan|EUL|

## Renewal

Denial Lists are downloaded every 6 hours, and if some of them are changed, the database will be renewed and
the result cache will be purged.

## Sources

- [Consolidated Screening List](https://www.trade.gov/consolidated-screening-list "Consolidated Screening List")
- [安全保障貿易管理**Export Control*関係法令：申請、相談に関する通達](https://www.meti.go.jp/policy/anpo/law05.html "安全保障貿易管理**Export Control*関係法令：申請、相談に関する通達")

''',
  'license': '''
# License and Repositories

## The Web Service

https://fms.catsushi.net/

## This Web Client

MITL

[fmscreen_flutter](https://github.com/Cat-sushi/fmscreen_flutter "fmscreen_flutter")

## The Server

AGPL3.0

Contact me if you need another different License.

[fmscreen](https://github.com/Cat-sushi/fmscreen "fmscreen")

## The Engine

AGPL3.0

Contact me if you need another different License.

[fmatch](https://github.com/Cat-sushi/fmatch "fmatch")

## Dependences

Libraries used by this system have their own OSS Licenses.

## Denial Lists

Public Domain
''',
};
