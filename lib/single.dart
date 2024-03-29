// Copyright 2022, 2024 Yako
// This code is licensed under MIT license (see LICENSE for details)

import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fmscreen/fmscreen.dart';
import 'package:http/http.dart' as http;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';

final resultProvider = StateProvider<ScreeningResult?>((ref) => null);
final selectedIndexProvider = StateProvider<int?>((ref) => null);

final itemScrollController1 = ItemScrollController();
final itemPositionsListener1 = ItemPositionsListener.create();
final itemScrollController2 = ItemScrollController();
final itemPositionsListener2 = ItemPositionsListener.create();

Future<void> screen(String input, WidgetRef ref) async {
  var uri = Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: '/s',
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
      child: const Column(
        children: <Widget>[
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
    super.key,
  });

  @override
  Widget build(BuildContext context, ref) {
    return TextField(
      autofocus: true,
      controller: TextEditingController(
          text:
              ref.read(resultProvider.notifier).state?.queryStatus.inputString),
      maxLines: 1,
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
    super.key,
  });

  @override
  Widget build(BuildContext context, ref) {
    var result = ref.watch(resultProvider);
    if (result == null) {
      return Container();
    }
    var index = ref.read(selectedIndexProvider);
    WidgetsBinding.instance.addPostFrameCallback((duration) async {
      if (index != null) {
        await Future.delayed(const Duration(milliseconds: 200));
        unawaited(itemScrollController1.scrollTo(
            index: index + 1,
            duration: const Duration(microseconds: 1),
            curve: Curves.easeInOutCubic));
        unawaited(itemScrollController2.scrollTo(
            index: index,
            duration: const Duration(microseconds: 1),
            curve: Curves.easeInOutCubic));
      }
    });
    return Column(children: [
      QueryStatusWidget(result),
      const SizedBox(height: 8.0),
      Expanded(
        child: Row(
          children: <Widget>[
            Flexible(
              child: DetctedItemsWidget(result),
            ),
            const SizedBox(width: 8.0),
            Flexible(
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
    super.key,
  });

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
          PreprocessedQueryWidget(result),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                QueryScoreWidget(result),
                QueryStartTimeWidget(result),
                QueryDurationWidget(result),
                DbVersionWidget(result),
                ServerIdWidget(result),
                if (result.queryStatus.message != '')
                  ServerMessageWidget(result),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PreprocessedQueryWidget extends ConsumerWidget {
  const PreprocessedQueryWidget(
    this.result, {
    super.key,
  });

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
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
            child: SelectableText.rich(
              textAlign: TextAlign.left,
              TextSpan(children: [
                ...spans(result.queryStatus.terms, result.queryStatus.letType)
              ]),
            ),
          ),
        ),
        if (result.queryStatus.perfectMatching) const SizedBox(width: 8.0),
        if (result.queryStatus.perfectMatching) PerfectMatchingWidget(result),
        if (result.queryStatus.queryFallenBack) const SizedBox(width: 8.0),
        if (result.queryStatus.queryFallenBack) QueryFallenBackWidget(result),
      ],
    );
  }
}

Iterable<TextSpan> spans(List<Term> terms, LetType letType) sync* {
  for (var term in terms) {
    var lineColor = letType == LetType.postfix && identical(term, terms.last) ||
            letType == LetType.prefix && identical(term, terms.first)
        ? const Color.fromRGBO(0, 191, 127, 1.0)
        : const Color.fromRGBO(127, 127, 127, 1.0);
    yield TextSpan(
      style: TextStyle(
        decorationStyle: TextDecorationStyle.solid,
        decoration: TextDecoration.combine([
          TextDecoration.underline,
          TextDecoration.overline,
        ]),
        decorationColor: lineColor,
        color: Colors.black,
      ),
      text: term.string,
    );
    if (!identical(term, terms.last)) {
      yield const TextSpan(text: ' ');
    }
  }
}

class PerfectMatchingWidget extends ConsumerWidget {
  const PerfectMatchingWidget(
    this.result, {
    super.key,
  });

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    return const Chip(label: Text('Exact'));
  }
}

class QueryFallenBackWidget extends ConsumerWidget {
  const QueryFallenBackWidget(
    this.result, {
    super.key,
  });

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    return const Chip(label: Text('Fallen Back'));
  }
}

class QueryScoreWidget extends ConsumerWidget {
  const QueryScoreWidget(
    this.result, {
    super.key,
  });

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    var score = result.queryStatus.queryScore * 100;
    var scoreString = score.floor().toString();
    return Row(
      mainAxisSize: MainAxisSize.min,
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
    super.key,
  });

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    var start = result.queryStatus.start.toIso8601String();
    var startShort = '${start.substring(0, 19)}Z';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Start: '),
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
            color: const Color.fromRGBO(251, 253, 255, 1.0),
          ),
          child: Text(startShort),
        ),
      ],
    );
  }
}

class QueryDurationWidget extends ConsumerWidget {
  const QueryDurationWidget(
    this.result, {
    super.key,
  });

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    var duration = result.queryStatus.durationInMilliseconds / 1000;
    return Row(
      mainAxisSize: MainAxisSize.min,
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
    super.key,
  });

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    var a = result.queryStatus.databaseVersion;
    var dbver = '${a.substring(0, 19)}Z';
    return Row(
      mainAxisSize: MainAxisSize.min,
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
    super.key,
  });

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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

class ServerMessageWidget extends ConsumerWidget {
  const ServerMessageWidget(
    this.result, {
    super.key,
  });

  final ScreeningResult result;

  @override
  Widget build(BuildContext context, ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Message: '),
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromRGBO(159, 159, 159, 1)),
            color: const Color.fromRGBO(251, 253, 255, 1.0),
          ),
          child: SelectableText(
            result.queryStatus.message,
            style: const TextStyle(color: Color.fromARGB(255, 122, 44, 2)),
          ),
        ),
      ],
    );
  }
}

class DetctedItemsWidget extends ConsumerWidget {
  const DetctedItemsWidget(
    this.result, {
    super.key,
  });

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
                ElevatedButton(
                    onPressed: () async {
                      var input =
                          ref.read(resultProvider)!.queryStatus.inputString;
                      var uri = Uri(
                          scheme: scheme,
                          host: host,
                          port: port,
                          path: '/s/pdf',
                          queryParameters: {'c': '1', 'v': '1', 'q': input});
                      unawaited(launchUrl(uri));
                    },
                    child: const Text('Get PDF')),
              ],
            ),
          ),
          Expanded(
            child: ScrollablePositionedList.builder(
              itemCount: itemCount + 1,
              itemBuilder: (context, index) =>
                  DetectedItemWidget(result, index),
              itemScrollController: itemScrollController1,
              itemPositionsListener: itemPositionsListener1,
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
    super.key,
  })  : _index = index - 1;

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
            child: SelectionArea(
              child: GestureDetector(
                onTap: () {
                  var index =
                      ref.read(selectedIndexProvider) == _index ? null : _index;
                  ref.read(selectedIndexProvider.notifier).state = index;
                  if (index != null) {
                    itemScrollController2.scrollTo(
                        index: _index,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic);
                  }
                },
                child: Container(
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.all(2),
                    child: Text(item.matchedNames[0].entry.string)),
              ),
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
    super.key,
  });

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
            itemScrollController: itemScrollController2,
            itemPositionsListener: itemPositionsListener2,
          )),
        ],
      ),
    );
  }
}

class DetectedItemDetailWidget extends ConsumerWidget {
  const DetectedItemDetailWidget(
    this.result,
    this._index, {
    super.key,
  });

  final ScreeningResult result;
  final int _index;

  @override
  Widget build(BuildContext context, ref) {
    var selected = ref.watch(selectedIndexProvider);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SelectionArea(
        child: GestureDetector(
          onTap: () {
            var index =
                ref.read(selectedIndexProvider) == _index ? null : _index;
            ref.read(selectedIndexProvider.notifier).state = index;
            if (index != null) {
              itemScrollController1.scrollTo(
                  index: _index + 1,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic);
            }
          },
          child: Container(
              decoration: BoxDecoration(
                border: Border.all(),
                color: _index == selected
                    ? const Color.fromRGBO(237, 223, 207, 1.0)
                    : const Color.fromRGBO(229, 237, 237, 1.0),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(child: MatchedNamesWidget(result, _index)),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(child: BodyWidget(result, _index)),
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
    super.key,
  });

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
    super.key,
  });

  final ScreeningResult result;
  final int index;

  @override
  Widget build(BuildContext context, ref) {
    var item = result.detectedItems[index];

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
              child: json2yamly(item.body!),
            ),
          ],
        ),
      ),
    ]);
  }
}

enum YamlyContext { top, map, list }

Column json2yamly(dynamic jsonObject) =>
    Column(children: [..._json2yamly(jsonObject, [], 0, YamlyContext.top)]);

const ls = LineSplitter();
const leaderStyle = TextStyle(color: Color.fromARGB(255, 122, 44, 2));

Iterable<Row> _json2yamly(
    dynamic jsonObject, List<String> leader, int indent, YamlyContext c) sync* {
  if (jsonObject is Map) {
    var first = true;
    if (c == YamlyContext.map) {
      yield Row(children: [Text(style: leaderStyle, leader.join())]);
      first = false;
    }
    for (var e in jsonObject.entries) {
      if (first) {
        first = false;
      } else {
        leader = ['  ' * indent];
      }
      leader.add('${e.key}: ');
      yield* _json2yamly(e.value, leader, indent + 1, YamlyContext.map);
    }
  } else if (jsonObject is List) {
    var first = true;
    if (c == YamlyContext.map) {
      yield Row(
          children: [Expanded(child: Text(style: leaderStyle, leader.join()))]);
      first = false;
    }
    for (var e in jsonObject) {
      if (first) {
        first = false;
      } else {
        leader = ['  ' * indent];
      }
      leader.add('- ');
      yield* _json2yamly(e, leader, indent + 1, YamlyContext.list);
    }
  } else if (jsonObject is String) {
    var lines = ls.convert(jsonObject);
    if (lines.length > 1) {
      var first = true;
      if (c == YamlyContext.map) {
        yield Row(children: [Text(style: leaderStyle, leader.join())]);
        first = false;
      }
      for (var l in lines) {
        if (first) {
          first = false;
        } else {
          leader = ['  ' * indent];
        }
        yield Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(style: leaderStyle, leader.join()),
            Expanded(
              child: Text.rich(
                style: const TextStyle(
                  backgroundColor: Color.fromRGBO(251, 253, 255, 1.0),
                ),
                TextSpan(children: [...clickable(l)]),
              ),
            ),
          ],
        );
      }
    } else {
      yield Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(style: leaderStyle, leader.join()),
          Expanded(
              child: Text.rich(TextSpan(children: [...clickable(jsonObject)]))),
        ],
      );
    }
  } else {
    yield Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(style: leaderStyle, leader.join()),
        Expanded(child: Text(jsonObject)),
      ],
    );
  }
}

final _urlRegExp =
    RegExp(r'(\bhttps?://)?(\bwww\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}'
        r'\b[-a-zA-Z0-9@:%_\+.~#?&/=]*(?<![.])');

final _mailRegExp = RegExp(r'^[\w\-.]+@(?:[\w\-]+\.)+[\w\-]{2,6}$');

final _httpRegExp = RegExp(r'https?://');

Iterable<InlineSpan> clickable(String text) sync* {
  var matches = _urlRegExp.allMatches(text);
  var s = 0;
  for (var m in matches) {
    if (m.start > s) {
      yield TextSpan(text: text.substring(s, m.start));
    }
    s = m.end;
    var url = m.group(0)!;
    if (!url.startsWith(_httpRegExp)) {
      if (url.contains(_mailRegExp)) {
        yield TextSpan(text: url);
        continue;
      }
      url = 'http://$url';
    }
    yield TextSpan(
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          var uri = Uri.parse(url);
          unawaited(launchUrl(uri));
        },
      style: const TextStyle(color: Colors.blue),
      text: m.group(0)!,
    );
  }
  if (s < text.length) {
    yield TextSpan(text: text.substring(s));
  }
}
