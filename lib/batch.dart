// Copyright 2022, 2024 Yako
// This code is licensed under MIT license (see LICENSE for details)
import 'dart:async';
import 'dart:js_interop';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fmscreen/fmscreen.dart';
import 'package:http/http.dart' as http;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:web/web.dart' as web;
import 'main.dart';
import 'src/util.dart';

final batchDirNameProvider = StateProvider<String>((ref) => '');

final itemScrollController = ItemScrollController();
final itemPositionsListener = ItemPositionsListener.create();

class MessagesNotifier extends StateNotifier<List<String>> {
  MessagesNotifier() : super([]);

  Future<void> print(String message) async {
    var idx = state.length;
    state = [...state, message];
    if (idx > 0 && itemScrollController.isAttached) {
      await itemScrollController.scrollTo(
          index: idx, duration: const Duration(microseconds: 1));
    }
  }

  void clear() {
    state = [];
  }
}

final messagesNotifier = MessagesNotifier();
final messagesNotifierProveder =
    StateNotifierProvider<MessagesNotifier, List<String>>(
        (ref) => messagesNotifier);
Future<void> printMessage(String message, {bool log = false}) async {
  await messagesNotifier.print(message);

  if (log && logStream != null) {
    await logStream!.write('$message\n'.toJS).toDart;
  }
}

class IsRunningNotifier extends StateNotifier<bool> {
  IsRunningNotifier() : super(false);
  void run() => state = true;
  void end() => state = false;
}

final isRunningNotifier = IsRunningNotifier();
final isRunningProvider =
    StateNotifierProvider<IsRunningNotifier, bool>((ref) => isRunningNotifier);

web.FileSystemWritableFileStream? logStream;

late DateTime startTime;
late DateTime currentLap;
late DateTime lastLap;

var bulkSize = 100;
var cacheHitCount = 0;
var cacheHitCount2 = 0;
var whiteResultHitCount = 0;
var detectedItemCount = 0;

class BatchScreen extends ConsumerWidget {
  const BatchScreen({super.key});

  @override
  Widget build(BuildContext context, ref) {
    WidgetsBinding.instance.addPostFrameCallback((duration) async {
      if (itemScrollController.isAttached) {
        var idx = ref.read(messagesNotifierProveder).length - 1;
        if (idx >= 0) {
          await Future.delayed(const Duration(milliseconds: 100));
          unawaited(itemScrollController.scrollTo(
              index: idx, duration: const Duration(microseconds: 1)));
        }
      }
    });
    var isRunning = ref.watch(isRunningProvider);
    var batchDirName = ref.watch(batchDirNameProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: isRunning ? null : () => batchDirPick(ref),
                child: const Text('Select Batch Directory'),
              ),
              const SizedBox(width: 8.0),
              Expanded(child: Text(batchDirName)),
            ],
          ),
        ),
        const Expanded(
            child: Padding(
          padding: EdgeInsets.all(8.0),
          child: StateWidget(),
        )),
      ],
    );
  }
}

class StateWidget extends ConsumerWidget {
  const StateWidget({super.key});

  @override
  Widget build(BuildContext context, ref) {
    var messages = ref.watch(messagesNotifierProveder);
    return ScrollablePositionedList.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        var message = messages[index];
        return Text(message);
      },
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
    );
  }
}

class WhiteResultKey {
  WhiteResultKey(this.txid, this.name, this.code, this.matchedName)
      : hashCode = Object.hashAll([txid, name, code, matchedName]);
  final String txid;
  final String name;
  final String code;
  final String matchedName;
  @override
  final int hashCode;

  @override
  bool operator ==(Object other) =>
      other is WhiteResultKey &&
      txid == other.txid &&
      name == other.name &&
      code == other.code &&
      matchedName == other.matchedName;
}

class WhiteResultValue {
  WhiteResultValue(this.count, this.score, this.lastDetectedDateTime,
      this.lastDetectedDbVersion, this.firstDetectedDbVersion);
  int count;
  final int score;
  final DateTime lastDetectedDateTime;
  final String lastDetectedDbVersion;
  String firstDetectedDbVersion;
}

extension type WhiteResults(Map<WhiteResultKey, WhiteResultValue> _)
    implements Map<WhiteResultKey, WhiteResultValue> {}

extension on web.Window {
  external JSPromise<web.FileSystemDirectoryHandle> showDirectoryPicker(
      [Options? options]);
}

@JS()
extension type Options._(JSObject _) implements JSObject {
  external Options({String mode});
}

Future<void> batchDirPick(WidgetRef ref) async {
  messagesNotifier.clear();

  web.FileSystemDirectoryHandle dirHandle;
  isRunningNotifier.run();
  try {
    dirHandle =
        await web.window.showDirectoryPicker(Options(mode: 'readwrite')).toDart;
    ref.read(batchDirNameProvider.notifier).state = dirHandle.name;

    try {
      await dirHandle.getFileHandle('lockfile').toDart;
      await printMessage(
          'Directory is Locked. If there is no batch running, remove "lockfile".');
      return;
    } catch (e) {
      // OK
    }
    Csv names;
    await dirHandle
        .getFileHandle('lockfile', web.FileSystemGetFileOptions(create: true))
        .toDart;
    try {
      try {
        var namesHandle = await dirHandle.getFileHandle('names.csv').toDart;
        var namesReader = web.FileReader()
          ..readAsText(await namesHandle.getFile().toDart);
        await namesReader.onLoadEnd.first;
        names = parseCsvLines(namesReader.result as String);
      } catch (e) {
        await printMessage("\"names.csv\" can't be read.");
        return;
      }
      WhiteResults whiteResults;
      try {
        var whiteHandle =
            await dirHandle.getFileHandle('white_results.csv').toDart;
        var whiteReader = web.FileReader()
          ..readAsText(await whiteHandle.getFile().toDart);
        await whiteReader.onLoadEnd.first;
        var csv = parseCsvLines(whiteReader.result as String);
        whiteResults = buildWhiteResults(csv);
      } catch (e) {
        whiteResults = WhiteResults({});
      }
      web.FileSystemFileHandle resultHandle;
      try {
        resultHandle = await dirHandle
            .getFileHandle(
                'results.csv', web.FileSystemGetFileOptions(create: true))
            .toDart;
      } catch (e) {
        await printMessage("\"result.csv\" can't be opened.");
        return;
      }
      var resultStream = await resultHandle.createWritable().toDart;
      try {
        await resultStream.write(Uint8List.fromList(utf8Bom).toJS).toDart;
        web.FileSystemFileHandle logHandle;
        try {
          logHandle = await dirHandle
              .getFileHandle(
                  'log.txt', web.FileSystemGetFileOptions(create: true))
              .toDart;
        } catch (e) {
          await printMessage("\"log.txt\" can't be opened.");
          return;
        }
        logStream = await logHandle.createWritable().toDart;
        try {
          await runBatch(ref, names, whiteResults, resultStream);
          await dumpUnrefferredWhiteResults(whiteResults, resultStream);
          await printMessage(
              'Batch completed at: ${DateTime.now().toUtc().toIso8601String()}',
              log: true);
        } finally {
          await logStream!.close().toDart;
        }
      } finally {
        await resultStream.close().toDart;
      }
    } finally {
      await dirHandle.removeEntry('lockfile').toDart;
    }
  } finally {
    isRunningNotifier.end();
  }
  return;
}

const resultCsvHeader =
    '"#","TxID","Name","Score","Code","Detected","Checked","Time","DB","Oldest DB"\r\n';

Future<void> runBatch(
  WidgetRef ref,
  List<List<String?>> names,
  Map<WhiteResultKey, WhiteResultValue> whiteResults,
  web.FileSystemWritableFileStream resultStream,
) async {
  startTime = DateTime.now();
  lastLap = startTime;
  currentLap = lastLap;
  cacheHitCount = 0;
  cacheHitCount2 = 0;
  detectedItemCount = 0;
  whiteResultHitCount = 0;

  await printMessage('Server: $scheme://$host:$port/', log: true);
  await printMessage('Start batch at: ${startTime.toUtc().toIso8601String()}',
      log: true);

  await resultStream.write(resultCsvHeader.toJS).toDart;
  int queryCount = 0;
  for (var idx = 0; idx < names.length; idx += bulkSize) {
    var sublist = names.sublist(idx, min(idx + bulkSize, names.length));
    queryCount += sublist.length;
    var nameBulk = <String>[];
    var txidBulk = <String>[];
    for (var i = 0; i < sublist.length; i++) {
      var row = sublist[i];
      String name;
      if (row.isNotEmpty && row[0] != null) {
        name = row[0]!;
      } else {
        name = '';
      }
      nameBulk.add(name);
      String txid;
      if (row.length > 1 && row[1] != null) {
        txid = row[1]!;
      } else {
        txid = '';
      }
      txidBulk.add(txid);
    }
    var bulk = jsonEncode(nameBulk);
    var uri = Uri(
        scheme: scheme,
        host: host,
        port: port,
        path: '/s',
        queryParameters: {'c': '1', 'v': '0'});
    http.Response response;
    try {
      response = await http.post(uri,
          headers: {'content-type': 'application/json; charset=utf-8'},
          body: bulk);
    } catch (e) {
      await printMessage('Server not responding.', log: true);
      return;
    }
    var jsonString = response.body;
    var jsons = json.decode(jsonString) as List;
    var results = jsons
        .map<ScreeningResult>(
            (dynamic e) => ScreeningResult.fromJson(e as Map<String, dynamic>))
        .toList();
    await outputResults(
        ref, resultStream, idx, txidBulk, results, whiteResults);
  }

  var endTime = DateTime.now();
  await printMessage('Dulation: ${endTime.difference(startTime).inSeconds}',
      log: true);
  await printMessage('Number of queries: $queryCount', log: true);
  await printMessage('Number of cache hits: $cacheHitCount', log: true);
  await printMessage('Number of detected items: $detectedItemCount', log: true);
  await printMessage(
      'Number of newly detected items: ${detectedItemCount - whiteResultHitCount}',
      log: true);
}

Future<void> outputResults(
  WidgetRef ref,
  web.FileSystemWritableFileStream resultStream,
  int idx,
  List<String> txids,
  List<ScreeningResult> results,
  Map<WhiteResultKey, WhiteResultValue> whiteResults,
) async {
  for (var i = 0; i < results.length; i++) {
    var result = results[i];
    if (result.queryStatus.terms.isEmpty) {
      await printMessage('${idx + i + 1}: ${result.queryStatus.message}',
          log: true);
      continue;
    }
    if (result.queryStatus.message != '') {
      cacheHitCount++;
      cacheHitCount2++;
    }
    await resultStream
        .write(formatOutput(idx + i, txids[i], result, whiteResults).toJS)
        .toDart;
    if (i == results.length - 1) {
      currentLap = DateTime.now();
      await printMessage(
          '${idx + i + 1} ${currentLap.difference(startTime).inMilliseconds}'
          ' ${currentLap.difference(lastLap).inMilliseconds}'
          '  $cacheHitCount2 $cacheHitCount');
      cacheHitCount2 = 0;
      lastLap = currentLap;
    }
  }
}

String formatOutput(
  int ix,
  String txid,
  ScreeningResult result,
  Map<WhiteResultKey, WhiteResultValue> whiteResults,
) {
  var csvLine = StringBuffer();
  for (var e in result.detectedItems) {
    var detectedDateTime = result.queryStatus.start.toUtc().toIso8601String();
    var firstDbVersion = result.queryStatus.databaseVersion;

    var key = WhiteResultKey(txid, result.queryStatus.rawQuery, e.listCode,
        e.matchedNames[0].entry.string);
    var value = whiteResults[key];
    var checked = false;
    detectedItemCount++;
    if (value != null) {
      firstDbVersion = value.firstDetectedDbVersion;
      if (value.count > 0) {
        value.count--;
        checked = true;
        whiteResultHitCount++;
      }
    }
    csvLine.write(ix + 1);
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(txid));
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(result.queryStatus.rawQuery));
    csvLine.write(r',');
    if (result.queryStatus.queryScore == 0) {
      csvLine.write('0');
    } else {
      csvLine.write(
          (e.matchedNames[0].score / result.queryStatus.queryScore * 100)
              .floor()
              .toString());
    }
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(e.listCode));
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(e.matchedNames[0].entry.string));
    csvLine.write(r',');
    csvLine.write(checked ? 'true' : 'false');
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(detectedDateTime));
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(result.queryStatus.databaseVersion));
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(firstDbVersion));
    csvLine.write('\r\n');
  }
  return csvLine.toString();
}

WhiteResults buildWhiteResults(
  List<List<String?>> csv,
) {
  var ret = WhiteResults({});
  if (csv.isNotEmpty && csv[0].isNotEmpty && csv[0][0] == '#') {
    csv.removeAt(0);
  }
  for (var row in csv) {
    if (row.length < 10) {
      continue;
    }
    if (row[6] == null || row[6]!.toUpperCase() != 'TRUE') {
      continue;
    }
    var txid = row[1] ?? '';
    var name = row[2] ?? '';
    var score = int.tryParse(row[3] ?? '0') ?? 0;
    var code = row[4] ?? '';
    var matchedName = row[5] ?? '';
    var key = WhiteResultKey(txid, name, code, matchedName);
    var value = ret[key];
    var lastDetectedDateTime = DateTime.tryParse(row[7] ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    var lastDbVersion = row[8] ?? '1970-01-01T00:00:00.000Z';
    var detectedDbVersion = row[9] ?? '';
    if (value == null) {
      ret[key] = WhiteResultValue(
          1, score, lastDetectedDateTime, lastDbVersion, detectedDbVersion);
    } else {
      value.count++;
      value.firstDetectedDbVersion =
          detectedDbVersion.compareTo(value.firstDetectedDbVersion) < 0
              ? detectedDbVersion
              : value.firstDetectedDbVersion;
    }
  }
  return ret;
}

Future<void> dumpUnrefferredWhiteResults(
  WhiteResults whiteResults,
  web.FileSystemWritableFileStream resultStream,
) async {
  for (var e in whiteResults.entries) {
    var csvLine = StringBuffer();
    csvLine.write(0);
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(e.key.txid));
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(e.key.name));
    csvLine.write(r',');
    csvLine.write(e.value.score.toString());
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(e.key.code));
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(e.key.matchedName));
    csvLine.write(r',');
    csvLine.write('true');
    csvLine.write(r',');
    csvLine.write(
        quoteCsvCell(e.value.lastDetectedDateTime.toUtc().toIso8601String()));
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(e.value.lastDetectedDbVersion));
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(e.value.firstDetectedDbVersion));
    csvLine.write('\r\n');
    for (var i = 0; i < e.value.count; i++) {
      await resultStream.write(csvLine.toString().toJS).toDart;
    }
  }
}
