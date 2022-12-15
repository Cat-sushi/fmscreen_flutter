import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BatchScreen extends ConsumerWidget {
  const BatchScreen({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return const Center(child: Text('TODO'));
  }
}
/*
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:html';
import 'package:fmscreen/fmscreen.dart';
import 'package:http/http.dart' as http;
import 'package:file_system_access_api/file_system_access_api.dart';
import 'src/util.dart';

final batchFileHandleProvider =
    StateProvider<FileSystemFileHandle?>((ref) => null);
final batchFileProvider = StateProvider<String?>((ref) => null);

final whiteFileHandleProvider =
    StateProvider<FileSystemFileHandle?>((ref) => null);
final whiteFileProvider = StateProvider<String?>((ref) => null);

final resultFileHandleProvider =
    StateProvider<FileSystemFileHandle?>((ref) => null);

final logFileHandleProvider =
    StateProvider<FileSystemFileHandle?>((ref) => null);

final messageProvider = StateProvider<List<String>>((ref) => []);

final isRunningProvider = StateProvider<bool>((ref) => false);

late DateTime startTime;
late DateTime currentLap;
late DateTime lastLap;

var bulkSize = 100;
var lc = 0;
var cacheHits = 0;
var cacheHits2 = 0;

class BatchScreen extends ConsumerWidget {
  const BatchScreen({super.key});

  @override
  Widget build(BuildContext context, ref) {
    var batchFileName = ref.watch(batchFileHandleProvider)?.name ?? '';
    var whiteFileName = ref.watch(whiteFileHandleProvider)?.name ?? '';
    var resultFileName = ref.watch(resultFileHandleProvider)?.name ?? '';
    var logFileName = ref.watch(logFileHandleProvider)?.name ?? '';
    var isRunning = ref.watch(isRunningProvider);
    var runIsActive = batchFileName != '' &&
        whiteFileName != '' &&
        resultFileName != '' &&
        logFileName != '' &&
        !isRunning;
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: () => unawaited(batchFilePick(ref)),
              child: const Text('Select Batch File'),
            ),
            Expanded(child: Text(batchFileName)),
          ],
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => unawaited(whiteFilePick(ref)),
              child: const Text('Select White Result File'),
            ),
            Expanded(child: Text(whiteFileName)),
          ],
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => unawaited(resultFilePick(ref)),
              child: const Text('Select Result File'),
            ),
            Expanded(child: Text(resultFileName)),
          ],
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => unawaited(logFilePick(ref)),
              child: const Text('Select Log File'),
            ),
            Expanded(child: Text(logFileName)),
          ],
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: runIsActive ? () => runBatch(ref) : null,
              child: const Text('Run'),
            ),
            Expanded(child: Container()),
          ],
        ),
        const Expanded(child: StateWidget()),
      ],
    );
  }
}

class StateWidget extends ConsumerWidget {
  const StateWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    var messages = ref.watch(messageProvider);
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        var message = messages[index];
        return Text(message);
      },
    );
  }
}

Future<void> batchFilePick(WidgetRef ref) async {
  List<FileSystemFileHandle> handles;
  try {
    handles = await window.showOpenFilePicker(
      multiple: false,
      // excludeAcceptAllOption: true,
      types: const [
        FilePickerAcceptType(description: "CSV", accept: {
          "text/csv": [".csv"]
        })
      ],
      // startIn: WellKnownDirectory.pictures),
    );
  } catch (e) {
    return;
  }
  FileSystemFileHandle? handle;
  if (handles.isEmpty) {
    return;
  }
  handle = handles[0];
  ref.read(batchFileHandleProvider.notifier).state = handle;
  var file = await handle.getFile();
  var fr = FileReader()..readAsText(file);
  fr.onLoadEnd.listen((event) {
    var result = fr.result as String;
    ref.read(batchFileProvider.notifier).state = result;
  });
}

Future<void> whiteFilePick(WidgetRef ref) async {
  List<FileSystemFileHandle> handles;
  try {
    handles = await window.showOpenFilePicker(
      multiple: false,
      excludeAcceptAllOption: true,
      types: const [
        FilePickerAcceptType(description: "CSV", accept: {
          "text/csv": [".csv"]
        })
      ],
    );
  } catch (e) {
    return;
  }
  FileSystemFileHandle? handle;
  if (handles.isEmpty) {
    return;
  }
  handle = handles[0];
  ref.read(whiteFileHandleProvider.notifier).state = handle;
  var file = await handle.getFile();
  var fr = FileReader()..readAsText(file);
  fr.onLoadEnd.listen((event) {
    var result = fr.result as String;
    ref.read(whiteFileProvider.notifier).state = result;
  });
}

Future<void> resultFilePick(WidgetRef ref) async {
  List<FileSystemFileHandle> handles;
  try {
    handles = await window.showOpenFilePicker(
      multiple: false,
      excludeAcceptAllOption: true,
      types: const [
        FilePickerAcceptType(description: "CSV", accept: {
          "text/csv": [".csv"]
        })
      ],
    );
  } catch (e) {
    return;
  }
  FileSystemFileHandle? handle;
  if (handles.isEmpty) {
    return;
  }
  handle = handles[0];
  ref.read(resultFileHandleProvider.notifier).state = handle;
}

Future<void> logFilePick(WidgetRef ref) async {
  List<FileSystemFileHandle> handles;
  try {
    handles = await window.showOpenFilePicker(
      multiple: false,
      // excludeAcceptAllOption: true,
      types: const [
        FilePickerAcceptType(description: "TXT", accept: {
          "text/plain": [".txt"]
        })
      ],
    );
  } catch (e) {
    return;
  }
  FileSystemFileHandle? handle;
  if (handles.isEmpty) {
    return;
  }
  handle = handles[0];
  ref.read(logFileHandleProvider.notifier).state = handle;
}

Future<void> runBatch(WidgetRef ref) async {
  var batchFile = ref.watch(batchFileProvider);
  if (batchFile == null) {
    return;
  }
  var batchStrings = readCsvLines(batchFile);

  var whiteFile = ref.watch(whiteFileProvider);
  if (whiteFile != null) {
    var whiteStrings = readCsvLines(whiteFile);
    // TODO
  }

  var resultHandle = ref.watch(resultFileHandleProvider);
  if (resultHandle == null) {
    return;
  }
  var resultStream = await resultHandle.createWritable();

  var logHandle = ref.watch(logFileHandleProvider);
  if (logHandle == null) {
    return;
  }
  var logStream = await logHandle.createWritable();

  ref.read(isRunningProvider.notifier).state = true;
  
  startTime = DateTime.now();
  lastLap = startTime;
  currentLap = lastLap;
  lc = 0;

  for (var idx = 0; idx < batchStrings.length; idx += bulkSize) {
    var sublist =
        batchStrings.sublist(idx, min(idx + bulkSize, batchStrings.length));
    var bulk = jsonEncode(sublist
        .where((e) => e.isNotEmpty && e[1] != null)
        .map(((e) => e[0]))
        .toList());

    var uri = Uri(
        scheme: 'http',
        host: 'localhost',
        port: 8080,
        path: '/',
        queryParameters: {'c': '1', 'v': '1'});
    http.Response response;
    try {
      response = await http.post(uri,
          headers: {'content-type': 'application/json; charset=utf-8'},
          body: bulk);
    } catch (e) {
      var m = ref.read(messageProvider);
      m.add('Server not responding.');
      ref.read(messageProvider.notifier).state = m;
      return;
    }
    var jsonString = response.body;
    var jsons = json.decode(jsonString) as List;
    var results = jsons
        .map<ScreeningResult>(
            (dynamic e) => ScreeningResult.fromJson(e as Map<String, dynamic>))
        .toList();
    addResults(ref, resultStream, logStream, results);
  }
  resultStream.close();
  logStream.close();
  ref.read(isRunningProvider.notifier).state = false;
}

void addResults(WidgetRef ref, FileSystemWritableFileStream resultStream,
    FileSystemWritableFileStream logStream, List<ScreeningResult> results) {
  for (var result in results) {
    ++lc;
    if (result.queryStatus.terms.isEmpty) {
      logStream.writeAsText(result.queryStatus.message);
      var m = ref.read(messageProvider);
      m.add(result.queryStatus.message);
      ref.read(messageProvider.notifier).state = m;
      continue;
    }
    if (result.queryStatus.message != '') {
      cacheHits++;
      cacheHits2++;
    }
    resultStream.writeAsText(formatOutput(lc, result));
    if ((lc % bulkSize) == 0) {
      currentLap = DateTime.now();
      var m = ref.read(messageProvider);
      m.add('$lc\t${currentLap.difference(startTime).inMilliseconds}'
          '\t${currentLap.difference(lastLap).inMilliseconds}'
          '\t\t$cacheHits2\t$cacheHits');
      ref.read(messageProvider.notifier).state = m;
      cacheHits2 = 0;
      lastLap = currentLap;
    }
  }
}

String formatOutput(int ix, ScreeningResult result) {
  var csvLine = StringBuffer();
  for (var e in result.detectedItems) {
    csvLine.write(ix);
    csvLine.write(r',');
    csvLine.write('false'); //checked
    csvLine.write(r',');
    if (result.queryStatus.queryScore == 0) {
      csvLine.write('0.00');
    } else {
      csvLine.write(
          (e.matchedNames[0].score / result.queryStatus.queryScore * 100)
              .floor()
              .toString());
    }
    csvLine.write(r',');
    csvLine.write('tx000'); // txid
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(e.listCode));
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(e.matchedNames[0].entry.string));
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(result.queryStatus.rawQuery));
    csvLine.write(r',');
    csvLine.write(
        quoteCsvCell(result.queryStatus.start.toUtc().toIso8601String()));
    csvLine.write(quoteCsvCell(result.queryStatus.databaseVersion));
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(
        result.queryStatus.start.toUtc().toIso8601String())); // last detect
    csvLine.write('\r\n');
  }
  return csvLine.toString();
}
*/
