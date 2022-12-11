import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fmscreen/fmscreen.dart';
import 'package:json2yaml/json2yaml.dart';

final resultProvider = StateProvider<ScreeningResult?>((ref) => null);
var httpClient = HttpClient();

Future<void> screen(String input, WidgetRef ref) async {
  var queryEncoded = Uri.encodeComponent(input);
  var path = '?c=1&v=1&q=$queryEncoded';
  var request = await httpClient.get('localhost', 8080, path);
  var response = await request.close();
  var jsonString = await response.transform(utf8.decoder).join();
  var jsonObject = json.decode(jsonString);
  var result = ScreeningResult.fromJson(jsonObject);
  ref.read(resultProvider.notifier).state = result;
}

class SingleScreen extends ConsumerWidget {
  const SingleScreen({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: const <Widget>[
          QueryInputWidget(),
          SizedBox(height: 8.0),
          Expanded(
            child: ScreeningResultWidget(),
          ),
        ],
      ),
    );
  }
}

class ScreeningResultWidget extends ConsumerWidget {
  const ScreeningResultWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    var result = ref.watch(resultProvider);
    if (result == null) {
      return Container();
    }
    return Column(children: [
      const QueryStatusWidget(),
      const SizedBox(height: 8.0),
      Expanded(
        child: Row(
          children: <Widget>[
            const Expanded(
              child: DetctedItemsWidget(),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: DetectedItemsDetailWidget(),
            ),
          ],
        ),
      ),
    ]);
  }
}

class QueryInputWidget extends ConsumerWidget {
  const QueryInputWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    return TextField(
      autofocus: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Name for screening',
      ),
      onSubmitted: (input) {
        unawaited(screen(input, ref));
      },
    );
  }
}

class QueryStatusWidget extends ConsumerWidget {
  const QueryStatusWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
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

class InputStringWidget extends ConsumerWidget {
  const InputStringWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    return Row(
      children: [
        const Text('Input String: '),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
              color: const Color.fromRGBO(251, 253, 255, 1.0),
            ),
            padding: const EdgeInsets.all(4),
            child: Text(ref.watch(resultProvider)!.queryStatus.inputString),
          ),
        ),
      ],
    );
  }
}

class NormalizedQueryWidget extends ConsumerWidget {
  const NormalizedQueryWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    return Row(
      children: [
        const Text('Normalized: '),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
              color: const Color.fromRGBO(251, 253, 255, 1.0),
            ),
            padding: const EdgeInsets.all(4),
            child: Text(ref.watch(resultProvider)!.queryStatus.rawQuery),
          ),
        ),
      ],
    );
  }
}

class PreprocessedQueryWidget extends ConsumerWidget {
  const PreprocessedQueryWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    var result = ref.watch(resultProvider)!;
    var terms = <Widget>[];
    for (var term in result.queryStatus.terms) {
      var back = result.queryStatus.letType == LetType.postfix &&
                  term == result.queryStatus.terms.last ||
              result.queryStatus.letType == LetType.prefix &&
                  term == result.queryStatus.terms.first
          ? const Color.fromRGBO(255, 247, 247, 1.0)
          : const Color.fromRGBO(239, 255, 255, 1.0);
      terms.add(Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromRGBO(207, 207, 207, 1.0)),
            color: back,
          ),
          child: Text(term.string),
        ),
      ));
    }
    return Row(
      children: [
        const Text('Preprocessed: '),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                border:
                    Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
                color: const Color.fromRGBO(251, 253, 255, 1.0)),
            child: Row(
              children: terms,
            ),
          ),
        ),
      ],
    );
  }
}

class QueryScoreWidget extends ConsumerWidget {
  const QueryScoreWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    var score = ref.watch(resultProvider)!.queryStatus.queryScore * 100;
    var scoreString = score.floor().toString();
    return Row(
      children: [
        const Text('Query Score: '),
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
            color: const Color.fromRGBO(251, 253, 255, 1.0),
          ),
          child: Text(scoreString),
        ),
      ],
    );
  }
}

class QueryStartTimeWidget extends ConsumerWidget {
  const QueryStartTimeWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    var start = ref.watch(resultProvider)!.queryStatus.start.toIso8601String();
    var startSort =
        '${start.substring(0, 4)}${start.substring(5, 7)}${start.substring(8, 10)}T'
        '${start.substring(11, 13)}${start.substring(14, 16)}${start.substring(17, 19)}Z';
    return Row(
      children: [
        const Text('Start: '),
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
            color: const Color.fromRGBO(251, 253, 255, 1.0),
          ),
          child: Text(startSort),
        ),
      ],
    );
  }
}

class QueryDurationWidget extends ConsumerWidget {
  const QueryDurationWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    var duration =
        ref.watch(resultProvider)!.queryStatus.durationInMilliseconds / 1000;
    return Row(
      children: [
        const Text('Duration: '),
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
            color: const Color.fromRGBO(251, 253, 255, 1.0),
          ),
          child: Text(duration.toStringAsFixed(3)),
        ),
      ],
    );
  }
}

class DbVersionWidget extends ConsumerWidget {
  const DbVersionWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    var a = ref.watch(resultProvider)!.queryStatus.databaseVersion;
    var dbver = a
        .replaceAll('T', '')
        .replaceAll('-', '')
        .replaceAll(':', '')
        .replaceAll('.000', '');
    return Row(
      children: [
        const Text('DB Ver.: '),
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
            color: const Color.fromRGBO(251, 253, 255, 1.0),
          ),
          child: Text(dbver),
        ),
      ],
    );
  }
}

class ServerIdWidget extends ConsumerWidget {
  const ServerIdWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    return Row(
      children: [
        const Text('Server ID: '),
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
            color: const Color.fromRGBO(251, 253, 255, 1.0),
          ),
          child:
              Text(ref.watch(resultProvider)!.queryStatus.serverId.toString()),
        ),
      ],
    );
  }
}

class PerfectMatchingWidget extends ConsumerWidget {
  const PerfectMatchingWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    return Chip(
      label: const Text('Perfect'), // TODO
      avatar: ref.watch(resultProvider)!.queryStatus.perfectMatching
          ? const Icon(Icons.check_circle)
          : null,
    );
  }
}

class QueryFallenBackWidget extends ConsumerWidget {
  const QueryFallenBackWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    return Chip(
      label: const Text('Fallen Back'), // TODO
      avatar: ref.watch(resultProvider)!.queryStatus.queryFallenBack
          ? const Icon(Icons.check_circle)
          : null,
    );
  }
}

class ServerMessageWidget extends ConsumerWidget {
  const ServerMessageWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    return Row(
      children: [
        const Text('Message: '),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
              color: const Color.fromRGBO(251, 253, 255, 1.0),
            ),
            child: Text(ref.watch(resultProvider)!.queryStatus.message),
          ),
        ),
      ],
    );
  }
}

class DetctedItemsWidget extends ConsumerWidget {
  const DetctedItemsWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    var itemCount = ref.watch(resultProvider)!.detectedItems.length;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
        color: const Color.fromRGBO(239, 247, 247, 1.0),
      ),
      child: Column(
        children: [
          AppBar(
              toolbarHeight: 40,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$itemCount item(s) detected'),
                  ElevatedButton(onPressed: () {}, child: const Text('PDF')),
                ],
              )),
          const Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: DetectedItemsTableWidget(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetectedItemsTableWidget extends ConsumerWidget {
  const DetectedItemsTableWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    var detectedIetms = ref.watch(resultProvider)!.detectedItems;
    var queryScore = ref.watch(resultProvider)!.queryStatus.queryScore;
    var rows = <TableRow>[];
    for (var item in detectedIetms) {
      var score = (item.matchedNames[0].score / queryScore * 100).floor();
      rows.add(TableRow(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(251, 253, 255, 1.0),
          border: Border(
              bottom: BorderSide(color: Color.fromRGBO(239, 239, 239, 1))),
        ),
        children: [
          TableCell(
              child: Container(
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.all(2),
                  child: Text('$score'))),
          TableCell(
              child: Container(
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.all(2),
                  child: Text(item.listCode))),
          TableCell(
              child: Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(2),
                  child: Text(item.matchedNames[0].entry.string))),
        ],
      ));
    }

    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: FlexColumnWidth(),
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
              child: Text('Best Matched Name of each item'),
            )),
          ],
        ),
        ...rows,
      ],
    );
  }
}

class DetectedItemsDetailWidget extends ConsumerWidget {
  DetectedItemsDetailWidget({
    Key? key,
  }) : super(key: key);

  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context, ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
        color: const Color.fromRGBO(239, 247, 247, 1.0),
      ),
      child: Column(
        children: [
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount:
                          ref.watch(resultProvider)!.detectedItems.length,
                      (context, index) {
                        return QueryResultDetailWidget(index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QueryResultDetailWidget extends ConsumerWidget {
  const QueryResultDetailWidget(
    this.index, {
    Key? key,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context, ref) {
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
                children: [
                  const SizedBox(width: 8),
                  Expanded(child: MatchedNamesWidget(index)),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(child: BodyWidget(index)),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8.0),
            ],
          )),
    );
  }
}

class MatchedNamesWidget extends ConsumerWidget {
  const MatchedNamesWidget(
    this.index, {
    Key? key,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context, ref) {
    var item = ref.watch(resultProvider)!.detectedItems[index];
    var queryScore = ref.watch(resultProvider)!.queryStatus.queryScore;
    var rows = <TableRow>[];
    for (var name in item.matchedNames) {
      var score = (name.score / queryScore * 100).floor();
      rows.add(
        TableRow(
            decoration: const BoxDecoration(
              color: Color.fromRGBO(251, 253, 255, 1.0),
              border: Border(
                  bottom: BorderSide(color: Color.fromRGBO(239, 239, 239, 1))),
            ),
            children: [
              TableCell(
                  child: Container(
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.all(2),
                      child: Text('$score'))),
              TableCell(
                  child: Container(
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.all(2),
                      child: Text(name.entry.string))),
            ]),
      );
    }
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
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
              child: Text('Matched Names in this item'),
            )),
          ],
        ),
        ...rows,
      ],
    );
  }
}

class BodyWidget extends ConsumerWidget {
  const BodyWidget(
    this.index, {
    Key? key,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context, ref) {
    var body = ref.watch(resultProvider)!.detectedItems[index].body!;
    var yamlString = json2yaml(body).trimRight();
    return Column(children: [
      Container(
        padding: const EdgeInsets.only(bottom: 4),
        alignment: Alignment.bottomLeft,
        child: const Text('Item Body'),
      ),
      Container(
        color: const Color.fromRGBO(251, 253, 255, 1.0),
        padding: const EdgeInsets.all(8.0),
        alignment: Alignment.bottomLeft,
        child: Row(
          children: [
            Expanded(
              child: Text(yamlString),
            ),
          ],
        ),
      ),
    ]);
  }
}
