// Fuzzy text matcher for entity/ persn screening.
// Copyright (c) 2020, 2022, Yako.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

RegExp regExp(String pattern) => RegExp(pattern, unicode: true);

final _escapedDoubleQuate = regExp(r'""');
final _mlDetecter = regExp(r'^(("(""|[^"])*"|[^",]+|),)*"(""|[^"])*$');
final _csvParser = regExp(r'(?:"((?:""|[^"])*)"|([^",]+)|())(?:,|$)');
final _lineSpritter = RegExp(r'\r\n|\r|\n', unicode: true);

const utf8Bom = [0xEF, 0xBB, 0xBF];

List<List<String?>> readCsvLines(String file) {
  var lines =  file.split(_lineSpritter);
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
