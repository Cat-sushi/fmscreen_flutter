import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
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
                Tab(text: 'Single Name Screening', height: 24),
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

class SingleScreen extends StatelessWidget {
  const SingleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          const QueryInputWidget(),
          const SizedBox(height: 8.0),
          const QueryStatusWidget(),
          const SizedBox(height: 8.0),
          Expanded(
            child: Row(
              children: const <Widget>[
                Expanded(
                  child: QueryResultsWidget(),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: QueryResultsDetailWidget(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QueryInputWidget extends StatelessWidget {
  const QueryInputWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const TextField(
      autofocus: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Name for screening',
      ),
      onSubmitted: null,
    );
  }
}

class QueryStatusWidget extends StatelessWidget {
  const QueryStatusWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(),
          color: const Color.fromRGBO(239, 247, 247, 1.0)),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const InputStringWidget(),
          const SizedBox(height: 4),
          const NormalizedQueryWidget(),
          const SizedBox(height: 4),
          const PreprocessedQueryWidget(),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const [
              QueryScoreWidget(),
              SizedBox(width: 8),
              QueryStartTimeWidget(),
              SizedBox(width: 8),
              QueryDurationWidget(),
              SizedBox(width: 8),
              DbVersionWidget(),
              SizedBox(width: 8),
              ServerIdWidget(),
              SizedBox(width: 8),
              PerfectMatchingWidget(),
              SizedBox(width: 8),
              QueryFallenBackWidget(),
            ],
          ),
          const SizedBox(height: 4),
          const ServerMessageWidget(),
        ],
      ),
    );
  }
}

class InputStringWidget extends StatelessWidget {
  const InputStringWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Input String: '),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(),
              color: const Color.fromRGBO(251, 253, 255, 1.0),
            ),
            padding: const EdgeInsets.all(4),
            child: const Text('"abc def co."'),
          ),
        ),
      ],
    );
  }
}

class NormalizedQueryWidget extends StatelessWidget {
  const NormalizedQueryWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Normalized: '),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(),
              color: const Color.fromRGBO(251, 253, 255, 1.0),
            ),
            padding: const EdgeInsets.all(4),
            child: const Text('ABC DEF CO.'),
          ),
        ),
      ],
    );
  }
}

class PreprocessedQueryWidget extends StatelessWidget {
  const PreprocessedQueryWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Preprocessed: '),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                border: Border.all(),
                color: const Color.fromRGBO(251, 253, 255, 1.0)),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color.fromRGBO(207, 207, 207, 1.0)),
                    color: const Color.fromRGBO(239, 255, 255, 1.0),
                  ),
                  child: const Text('ABC'),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color.fromRGBO(207, 207, 207, 1.0)),
                    color: const Color.fromRGBO(239, 255, 255, 1.0),
                  ),
                  child: const Text('DEF'),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color.fromRGBO(207, 207, 207, 1.0)),
                    color: const Color.fromRGBO(255, 247, 247, 1.0),
                  ),
                  child: const Text('CO'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class QueryScoreWidget extends StatelessWidget {
  const QueryScoreWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Query Score: '),
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            border: Border.all(),
            color: const Color.fromRGBO(251, 253, 255, 1.0),
          ),
          child: const Text('99'),
        ),
      ],
    );
  }
}

class QueryStartTimeWidget extends StatelessWidget {
  const QueryStartTimeWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Start: '),
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            border: Border.all(),
            color: const Color.fromRGBO(251, 253, 255, 1.0),
          ),
          child: const Text('00:00:00.000 '),
        ),
      ],
    );
  }
}

class QueryDurationWidget extends StatelessWidget {
  const QueryDurationWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Duration(ms): '),
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            border: Border.all(),
            color: const Color.fromRGBO(251, 253, 255, 1.0),
          ),
          child: const Text('125 '),
        ),
      ],
    );
  }
}

class DbVersionWidget extends StatelessWidget {
  const DbVersionWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('DB Ver.: '),
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            border: Border.all(),
            color: const Color.fromRGBO(251, 253, 255, 1.0),
          ),
          child: const Text('00:00:00.000 '),
        ),
      ],
    );
  }
}

class ServerIdWidget extends StatelessWidget {
  const ServerIdWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Server ID: '),
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            border: Border.all(),
            color: const Color.fromRGBO(251, 253, 255, 1.0),
          ),
          child: const Text('0'),
        ),
      ],
    );
  }
}

class PerfectMatchingWidget extends StatelessWidget {
  const PerfectMatchingWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Chip(label: Text('Perfect'), avatar: Icon(Icons.check_circle));
  }
}

class QueryFallenBackWidget extends StatelessWidget {
  const QueryFallenBackWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Chip(label: Text('Fallen Back'));
  }
}

class ServerMessageWidget extends StatelessWidget {
  const ServerMessageWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Message: '),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              border: Border.all(),
              color: const Color.fromRGBO(251, 253, 255, 1.0),
            ),
            child: const Text('Cached result'),
          ),
        ),
      ],
    );
  }
}

class QueryResultsWidget extends StatelessWidget {
  const QueryResultsWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
        color: const Color.fromRGBO(239, 247, 247, 1.0),
      ),
      child: Column(
        children: [
          AppBar(
              toolbarHeight: 40,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('10 items detected'),
                  ElevatedButton(onPressed: () {}, child: const Text('PDF')),
                ],
              )),
          Expanded(
            child: Row(
              children: const [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: QueryResultTableWidget(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QueryResultTableWidget extends StatelessWidget {
  const QueryResultTableWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: IntrinsicColumnWidth(),
      },
      children: [
        const TableRow(
          children: [
            TableCell(
                child: Padding(
              padding: EdgeInsets.only(right: 8, bottom: 4),
              child: Text('Score'),
            )),
            TableCell(
                child: Padding(
              padding: EdgeInsets.only(right: 8, bottom: 4),
              child: Text('Code'),
            )),
            TableCell(
                child: Padding(
              padding: EdgeInsets.only(right: 8, bottom: 4),
              child: Text('Name'),
            )),
          ],
        ),
        for (int i = 0; i < 50; i++)
          TableRow(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(251, 253, 255, 1.0),
                border: Border(
                    bottom:
                        BorderSide(color: Color.fromRGBO(239, 239, 239, 1))),
              ),
              children: [
                TableCell(
                    child: Container(
                        padding: const EdgeInsets.all(2), child: Text('$i'))),
                TableCell(
                    child: Container(
                        padding: const EdgeInsets.all(2),
                        child: const Text('EL'))),
                TableCell(
                    child: Container(
                        padding: const EdgeInsets.all(2),
                        child: const Text(
                            'Abcdefg hijklmn opqrstu vwxyz ZZZZZZ ZZZZ ZZZ ZZZZZZ ZZZZZZ ZZZZ ZZ ZZZZZZ ZZZZZZ ZZZZ ZZZZZ Z'))),
              ]),
      ],
    );
  }
}

class QueryResultsDetailWidget extends StatelessWidget {
  const QueryResultsDetailWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
        color: const Color.fromRGBO(239, 247, 247, 1.0),
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                  return const QueryResultDetailWidget();
                }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QueryResultDetailWidget extends StatelessWidget {
  const QueryResultDetailWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          decoration: BoxDecoration(
            border: Border.all(),
            color: const Color.fromRGBO(229, 237, 237, 1.0),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8.0),
              Row(
                children: const [
                  SizedBox(width: 8),
                  Expanded(child: MatchedNamesWidget()),
                  SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: const [
                  SizedBox(width: 8),
                  Expanded(child: BodyWidget()),
                  SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8.0),
            ],
          )),
    );
  }
}

class MatchedNamesWidget extends StatelessWidget {
  const MatchedNamesWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
      },
      children: [
        const TableRow(
          children: [
            TableCell(
                child: Padding(
              padding: EdgeInsets.only(right: 8, bottom: 4),
              child: Text('Score'),
            )),
            TableCell(
                child: Padding(
              padding: EdgeInsets.only(right: 8, bottom: 4),
              child: Text('Matched Names'),
            )),
          ],
        ),
        for (int i = 0; i < 2; i++)
          TableRow(
              decoration: const BoxDecoration(
                color: Color.fromRGBO(251, 253, 255, 1.0),
                border: Border(
                    bottom:
                        BorderSide(color: Color.fromRGBO(239, 239, 239, 1))),
              ),
              children: [
                TableCell(
                    child: Container(
                        padding: const EdgeInsets.all(2), child: Text('$i'))),
                TableCell(
                    child: Container(
                        padding: const EdgeInsets.all(2),
                        child: const Text(
                            'Abcdefg hijklmn opqrstu vwxyz ZZZZZZ ZZZZ ZZZ ZZZZZZ ZZZZZZ ZZZZ ZZ ZZZZZZ ZZZZZZ ZZZZ ZZZZZ Z'))),
              ]),
      ],
    );
  }
}

class BodyWidget extends StatelessWidget {
  const BodyWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 4),
          alignment: Alignment.bottomLeft,
          child: const Text('Item Body'),
        ),
        Container(
          color: const Color.fromRGBO(251, 253, 255, 1.0),
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.bottomLeft,
          child: const Flexible(
            fit: FlexFit.tight,
            child: Text('''
source: "Foreigh End User List (EUL) - Ministry of Economy, Trade and Industry, Japan"
No.: "321"
Country or Region: |-
  北朝鮮
  North Korea
Company or Organization: |-
  Korea Rungra-888 Trading Corporation
  (朝鮮綾羅888貿易会社)
Also Known As: |-
  ・Korea Rungra 888 Trading Co.
  ・Korea Rungra-888 Muyeg Hisa
  ・Rungra 888 General Trading Corp
  (綾羅888貿易総会社)
Type of WMD: |-
  生物、化学、ミサイル、核
  B,C,M,N'''),
          ),
        ),
      ],
    );
  }
}

class BatchScreen extends StatelessWidget {
  const BatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('TODO'));
  }
}
