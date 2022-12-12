import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fmscreen/fmscreen.dart';
import 'package:http/http.dart' as http;
import 'package:json2yaml/json2yaml.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

final resultProvider = StateProvider<ScreeningResult?>((ref) => null);
final selectedIndexProvider = StateProvider<int?>((ref) => null);

final itemScrollController = ItemScrollController();
final itemPositionsListener = ItemPositionsListener.create();

Future<void> screen(String input, WidgetRef ref) async {
  var uri = Uri(
      scheme: 'http',
      host: 'localhost',
      port: 8080,
      path: '/',
      queryParameters: {'c': '1', 'v': '1', 'q': input});
  http.Response response;
  try {
    response = await http.get(uri);
  } catch (e) {
    ref.read(resultProvider.notifier).state =
        ScreeningResult.fromMessage('Server not responding.');
    return;
  }
  var jsonString = response.body;
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
        ref.read(resultProvider.notifier).state = null;
        ref.read(selectedIndexProvider.notifier).state = null;
        unawaited(screen(input, ref));
      },
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
      QueryStatusWidget(result),
      const SizedBox(height: 8.0),
      Expanded(
        child: Row(
          children: <Widget>[
            Expanded(
              child: DetctedItemsWidget(result),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: DetectedItemsDetailWidget(result),
            ),
          ],
        ),
      ),
    ]);
  }
}

class QueryStatusWidget extends ConsumerWidget {
  const QueryStatusWidget(
    this.result, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
          color: const Color.fromRGBO(239, 247, 247, 1.0)),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          InputStringWidget(result),
          const SizedBox(height: 4),
          NormalizedQueryWidget(result),
          const SizedBox(height: 4),
          PreprocessedQueryWidget(result),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              QueryScoreWidget(result),
              const SizedBox(width: 8),
              QueryStartTimeWidget(result),
              const SizedBox(width: 8),
              QueryDurationWidget(result),
              const SizedBox(width: 8),
              DbVersionWidget(result),
              const SizedBox(width: 8),
              ServerIdWidget(result),
              const SizedBox(width: 8),
              PerfectMatchingWidget(result),
              const SizedBox(width: 8),
              QueryFallenBackWidget(result),
            ],
          ),
          const SizedBox(height: 4),
          ServerMessageWidget(result),
        ],
      ),
    );
  }
}

class InputStringWidget extends ConsumerWidget {
  const InputStringWidget(
    this.result, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;

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
            child: SelectableText(result.queryStatus.inputString),
          ),
        ),
      ],
    );
  }
}

class NormalizedQueryWidget extends ConsumerWidget {
  const NormalizedQueryWidget(
    this.result, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;

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
            child: SelectableText(result.queryStatus.rawQuery),
          ),
        ),
      ],
    );
  }
}

class PreprocessedQueryWidget extends ConsumerWidget {
  const PreprocessedQueryWidget(
    this.result, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    var terms = <TextSpan>[];
    for (var term in result.queryStatus.terms) {
      var front = result.queryStatus.letType == LetType.postfix &&
                  term == result.queryStatus.terms.last ||
              result.queryStatus.letType == LetType.prefix &&
                  term == result.queryStatus.terms.first
          ? const Color.fromRGBO(0, 127, 127, 1.0)
          : const Color.fromRGBO(0, 0, 0, 1.0);
      terms.add(TextSpan(
        style: TextStyle(
          decorationStyle: TextDecorationStyle.solid,
          decoration: TextDecoration.combine([
            TextDecoration.underline,
            TextDecoration.overline,
          ]),
          decorationColor: const Color(0xFF888888),
          color: front,
        ),
        text: term.string,
      ));
      if (term != result.queryStatus.terms.last) {
        terms.add(const TextSpan(text: ' '));
      }
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
            child: SelectionArea(
              child: SelectableText.rich(
                TextSpan(children: terms),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class QueryScoreWidget extends ConsumerWidget {
  const QueryScoreWidget(
    this.result, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    var score = result.queryStatus.queryScore * 100;
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
  const QueryStartTimeWidget(
    this.result, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    var start = result.queryStatus.start.toIso8601String();
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
  const QueryDurationWidget(
    this.result, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    var duration = result.queryStatus.durationInMilliseconds / 1000;
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
  const DbVersionWidget(
    this.result, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    var a = result.queryStatus.databaseVersion;
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
  const ServerIdWidget(
    this.result, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;

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
          child: Text(result.queryStatus.serverId.toString()),
        ),
      ],
    );
  }
}

class PerfectMatchingWidget extends ConsumerWidget {
  const PerfectMatchingWidget(
    this.result, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    var pf = result.queryStatus.perfectMatching;
    return Chip(
      label: Text('Perfect',
          style: TextStyle(
              color: pf ? null : const Color.fromRGBO(192, 192, 192, 1.0))),
      avatar: pf ? const Icon(Icons.check_circle) : null,
    );
  }
}

class QueryFallenBackWidget extends ConsumerWidget {
  const QueryFallenBackWidget(
    this.result, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    var fb = result.queryStatus.queryFallenBack;
    return Chip(
      label: Text('Fallen Back',
          style: TextStyle(
              color: fb ? null : const Color.fromRGBO(192, 192, 192, 1.0))),
      avatar: fb ? const Icon(Icons.check_circle) : null,
    );
  }
}

class ServerMessageWidget extends ConsumerWidget {
  const ServerMessageWidget(
    this.result, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;

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
            child: SelectableText(result.queryStatus.message),
          ),
        ),
      ],
    );
  }
}

class DetctedItemsWidget extends ConsumerWidget {
  const DetctedItemsWidget(
    this.result, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    var itemCount = result.detectedItems.length;
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
                Text('$itemCount item${itemCount > 1 ? 's' : ''} detected'),
                ElevatedButton(onPressed: () {}, child: const Text('PDF')),
              ],
            ),
          ),
          Expanded(
            child: SelectionArea(
              child: ListView.builder(
                itemCount: itemCount + 1,
                itemBuilder: ((context, index) {
                  return DetectedItemWidget(result, index);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetectedItemWidget extends ConsumerWidget {
  const DetectedItemWidget(
    this.result,
    index, {
    Key? key,
  })  : _index = index - 1,
        super(key: key);

  final ScreeningResult result;

  static const scoreWidth = 50.0;
  static const codeWidth = 50.0;
  final int _index;

  @override
  Widget build(BuildContext context, ref) {
    if (_index == -1) {
      return Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, top: 8),
            child: Container(
                width: scoreWidth,
                alignment: Alignment.centerRight,
                child: const Text('Score')),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4, top: 8),
            child: Container(
                width: codeWidth,
                alignment: Alignment.bottomCenter,
                child: const Text('Code')),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(bottom: 4, top: 8),
            child: Text('Best Matched Name of each item'),
          ),
        ],
      );
    }
    var item = result.detectedItems[_index];
    var score =
        (item.matchedNames[0].score / result.queryStatus.queryScore * 100)
            .floor();
    return Container(
      decoration: BoxDecoration(
        color: _index == ref.watch(selectedIndexProvider)
            ? const Color.fromRGBO(251, 239, 223, 1.0)
            : const Color.fromRGBO(251, 253, 255, 1.0),
        border: const Border(
            bottom: BorderSide(color: Color.fromRGBO(239, 239, 239, 1))),
      ),
      child: Row(
        children: [
          Container(
              width: scoreWidth,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.all(2),
              child: Text('$score')),
          const SizedBox(width: 8),
          Container(
              width: codeWidth,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.all(2),
              child: Text(item.listCode)),
          const SizedBox(width: 8),
          Flexible(
            fit: FlexFit.tight,
            child: GestureDetector(
              onTap: () {
                ref.read(selectedIndexProvider.notifier).state =
                    ref.read(selectedIndexProvider) == _index ? null : _index;
                itemScrollController.scrollTo(
                    index: _index,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic);
              },
              child: Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(2),
                  child: Text(item.matchedNames[0].entry.string)),
            ),
          ),
        ],
      ),
    );
  }
}

class DetectedItemsDetailWidget extends ConsumerWidget {
  const DetectedItemsDetailWidget(
    this.result, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    var items = result.detectedItems;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
        color: const Color.fromRGBO(239, 247, 247, 1.0),
      ),
      child: Column(
        children: [
          Expanded(
              child: ScrollablePositionedList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) =>
                DetectedItemDetailWidget(result, index),
            itemScrollController: itemScrollController,
            itemPositionsListener: itemPositionsListener,
          )),
        ],
      ),
    );
  }
}

class DetectedItemDetailWidget extends ConsumerWidget {
  const DetectedItemDetailWidget(
    this.result,
    this.index, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;
  final int index;

  @override
  Widget build(BuildContext context, ref) {
    var selected = ref.watch(selectedIndexProvider);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SelectionArea(
        child: GestureDetector(
          onTap: () {
            ref.read(selectedIndexProvider.notifier).state =
                ref.read(selectedIndexProvider) == index ? null : index;
          },
          child: Container(
              decoration: BoxDecoration(
                border: Border.all(),
                color: index == selected
                    ? const Color.fromRGBO(237, 223, 207, 1.0)
                    : const Color.fromRGBO(229, 237, 237, 1.0),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(child: MatchedNamesWidget(result, index)),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(child: BodyWidget(result, index)),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                ],
              )),
        ),
      ),
    );
  }
}

class MatchedNamesWidget extends ConsumerWidget {
  const MatchedNamesWidget(
    this.result,
    this.index, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;
  final int index;

  @override
  Widget build(BuildContext context, ref) {
    var item = result.detectedItems[index];
    var queryScore = result.queryStatus.queryScore;
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
              const TableCell(child: SizedBox(width: 8)),
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
        1: FixedColumnWidth(8),
        2: FlexColumnWidth(),
      },
      children: [
        TableRow(
          children: [
            const TableCell(
                child: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('Score'),
            )),
            const TableCell(child: SizedBox(width: 8)),
            TableCell(
                child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child:
                  Text('Matched Name${item.matchedNames.length > 1 ? 's' : ''}'
                      ' of this item'),
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
    this.result,
    this.index, {
    Key? key,
  }) : super(key: key);

  final ScreeningResult result;
  final int index;

  @override
  Widget build(BuildContext context, ref) {
    var item = result.detectedItems[index];
    var yamlString = json2yaml(item.body!).trimRight();

    return Column(children: [
      Container(
        padding: const EdgeInsets.only(bottom: 4),
        alignment: Alignment.bottomLeft,
        child: Text('Item Body (${item.listCode})'),
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
