import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:html';
import 'package:file_system_access_api/file_system_access_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fmscreen/fmscreen.dart';
import 'package:http/http.dart' as http;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
    await logStream!.writeAsText('$message\n');
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

FileSystemWritableFileStream? logStream;

late DateTime startTime;
late DateTime currentLap;
late DateTime lastLap;

var bulkSize = 100;
var cacheHits = 0;
var cacheHits2 = 0;

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
                onPressed:
                    isRunning ? null : () => unawaited(batchDirPick(ref)),
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
  const StateWidget({Key? key}) : super(key: key);

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

Future<void> batchDirPick(WidgetRef ref) async {
  messagesNotifier.clear();
  isRunningNotifier.run();

  FileSystemDirectoryHandle dirHandle;
  try {
    dirHandle =
        await window.showDirectoryPicker(mode: PermissionMode.readwrite);
    ref.read(batchDirNameProvider.notifier).state = dirHandle.name;

    try {
      await dirHandle.getFileHandle('lockfile');
      await printMessage(
          'Directory is Locked. If there is no batch running, remove "lockfile".');
      isRunningNotifier.end();
      return;
    } catch (e) {
      // OK
    }
    await dirHandle.getFileHandle('lockfile', create: true);
  } catch (e) {
    isRunningNotifier.end();
    return;
  }

  List<List<String?>> names;
  try {
    var namesHandle = (await dirHandle.getFileHandle('names.csv'));
    var namesReader = FileReader()..readAsText(await namesHandle.getFile());
    await namesReader.onLoadEnd.first;
    names = parseCsvLines(namesReader.result as String);
  } catch (e) {
    await printMessage("\"names.csv\" can't be read.");
    await dirHandle.removeEntry('lockfile');
    isRunningNotifier.end();
    return;
  }

  Map<WhiteResultKey, WhiteResultValue> whiteResults;
  try {
    var whiteHandle = (await dirHandle.getFileHandle('white_results.csv'));
    var whiteReader = FileReader()..readAsText(await whiteHandle.getFile());
    await whiteReader.onLoadEnd.first;
    var csv = parseCsvLines(whiteReader.result as String);
    whiteResults = buildWhiteResult(csv);
  } catch (e) {
    whiteResults = {};
  }

  FileSystemWritableFileStream resultStream;
  try {
    var resultHandle =
        (await dirHandle.getFileHandle('results.csv', create: true));
    resultStream = await resultHandle.createWritable();
  } catch (e) {
    await printMessage("\"result.csv\" can't be opened.");
    await dirHandle.removeEntry('lockfile');
    isRunningNotifier.end();
    return;
  }

  try {
    var logHandle = (await dirHandle.getFileHandle('log.txt', create: true));
    logStream = await logHandle.createWritable();
  } catch (e) {
    await printMessage("\"log.txt\" can't be opened.");
    await resultStream.close();
    await dirHandle.removeEntry('lockfile');
    isRunningNotifier.end();
    return;
  }

  try {
    await runBatch(ref, names, whiteResults, resultStream);
    await dumpUnrefferredWhiteResults(whiteResults, resultStream);
  } finally {
    await resultStream.close();
    await logStream!.close();
    await dirHandle.removeEntry('lockfile');
    isRunningNotifier.end();
    await printMessage('Batch completed.');
  }
}

Future<void> runBatch(
  WidgetRef ref,
  List<List<String?>> names,
  Map<WhiteResultKey, WhiteResultValue> whiteResults,
  FileSystemWritableFileStream resultStream,
) async {
  startTime = DateTime.now();
  lastLap = startTime;
  currentLap = lastLap;
  cacheHits = 0;
  cacheHits2 = 0;

  await printMessage('Server: $scheme://$host:$port/', log: true);
  await printMessage('Start batch at: ${startTime.toUtc().toIso8601String()}');

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
        path: '/',
        queryParameters: {'c': '1', 'v': '0'});
    http.Response response;
    try {
      response = await http.post(uri,
          headers: {'content-type': 'application/json; charset=utf-8'},
          body: bulk);
    } catch (e) {
      await printMessage('Server not responding.');
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
  await printMessage('Number of chache hits: $cacheHits', log: true);
}

Future<void> outputResults(
  WidgetRef ref,
  FileSystemWritableFileStream resultStream,
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
      cacheHits++;
      cacheHits2++;
    }
    await resultStream
        .writeAsText(formatOutput(idx + i, txids[i], result, whiteResults));
    if (i == results.length - 1) {
      currentLap = DateTime.now();
      await printMessage(
          '${idx + i + 1} ${currentLap.difference(startTime).inMilliseconds}'
          ' ${currentLap.difference(lastLap).inMilliseconds}'
          '  $cacheHits2 $cacheHits');
      cacheHits2 = 0;
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
    var firstDetectedDateTime = detectedDateTime;

    var key = WhiteResultKey(txid, result.queryStatus.rawQuery, e.listCode,
        e.matchedNames[0].entry.string);
    var value = whiteResults[key];
    var checked = false;
    if (value != null) {
      firstDetectedDateTime = value.detectedDateTime;
      if (value.count > 0) {
        value.count--;
        checked = true;
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
    csvLine.write(quoteCsvCell(firstDetectedDateTime));
    csvLine.write('\r\n');
  }
  return csvLine.toString();
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
  WhiteResultValue(this.count, this.detectedDateTime);
  int count;
  String detectedDateTime;
}

Map<WhiteResultKey, WhiteResultValue> buildWhiteResult(
  List<List<String?>> csv,
) {
  var ret = <WhiteResultKey, WhiteResultValue>{};
  for (var row in csv) {
    if (row.length < 10) {
      continue;
    }
    if (row[6] == null || row[6]!.toUpperCase() != 'TRUE') {
      continue;
    }
    var txid = row[1] ?? '';
    var name = row[2] ?? '';
    var code = row[4] ?? '';
    var matchedName = row[5] ?? '';
    var key = WhiteResultKey(txid, name, code, matchedName);
    var value = ret[key];
    var detectedDateTime = row[9] ?? '';
    if (value == null) {
      ret[key] = WhiteResultValue(1, detectedDateTime);
    } else {
      value.count++;
      value.detectedDateTime =
          detectedDateTime.compareTo(value.detectedDateTime) < 0
              ? detectedDateTime
              : value.detectedDateTime;
    }
  }
  return ret;
}

Future<void> dumpUnrefferredWhiteResults(
  Map<WhiteResultKey, WhiteResultValue> whiteResults,
  FileSystemWritableFileStream resultStream,
) async {
  for (var e in whiteResults.entries) {
    for (var i = 0; i < e.value.count; i++) {
      var csvLine = StringBuffer();
      csvLine.write(0);
      csvLine.write(r',');
      csvLine.write(quoteCsvCell(e.key.txid));
      csvLine.write(r',');
      csvLine.write(quoteCsvCell(e.key.name));
      csvLine.write(r',');
      csvLine.write('0');
      csvLine.write(r',');
      csvLine.write(quoteCsvCell(e.key.code));
      csvLine.write(r',');
      csvLine.write(quoteCsvCell(e.key.matchedName));
      csvLine.write(r',');
      csvLine.write('true');
      csvLine.write(r',');
      csvLine.write(quoteCsvCell(e.value.detectedDateTime));
      csvLine.write(r',');
      csvLine.write(quoteCsvCell('1970-01-01T00:00:00.000Z'));
      csvLine.write(r',');
      csvLine.write(quoteCsvCell(e.value.detectedDateTime));
      csvLine.write('\r\n');
      await resultStream.writeAsText(csvLine.toString());
    }
  }
}
