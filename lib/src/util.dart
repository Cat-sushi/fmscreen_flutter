// Copyright 2022, 2023 Yako
// This code is licensed under MIT license (see LICENSE for details)

RegExp regExp(String pattern) => RegExp(pattern, unicode: true);

final _escapedDoubleQuate = regExp(r'""');
final _mlDetecter = regExp(r'^(("(""|[^"])*"|[^",]+|),)*"(""|[^"])*$');
final _csvParser = regExp(r'(?:"((?:""|[^"])*)"|([^",]+)|())(?:,|$)');
final _lineSpritter = RegExp(r'\r\n|\r|\n', unicode: true);

const utf8Bom = [0xEF, 0xBB, 0xBF];

List<List<String?>> parseCsvLines(String file) {
  var lines = file.split(_lineSpritter);
  if(lines.last == '') {
    lines = lines.sublist(0, lines.length - 1);
  }
  var buff = <List<String?>>[];
  var row = '';
  for (var line in lines) {
    if (row != '') {
      row += '\n';
    }
    row += line;
    if (_mlDetecter.firstMatch(row) != null) {
      continue;
    }
    var ret = <String?>[];
    var start = 0;
    for (Match? m; true; start = m.end) {
      m = _csvParser.matchAsPrefix(row, start);
      if (m == null) {
        if (start != row.length) {
          // print('Illegal CSV line: $row');
        }
        break;
      }
      if (m.start == m.end) {
        break;
      }
      if (m.group(1) != null) {
        ret.add(m.group(1)!.replaceAll(_escapedDoubleQuate, r'"'));
        continue;
      }
      if (m.group(2) != null) {
        ret.add(m.group(2));
        continue;
      }
      if (m.group(3) != null) {
        ret.add(null);
        continue;
      }
    }
    buff.add(ret);
    row = '';
  }
  if (row != '') {
    // print('Illegal CSV line: $row');
  }
  return buff;
}

String quoteCsvCell(String cell) => r'"' + cell.replaceAll(r'"', r'""') + r'"';
