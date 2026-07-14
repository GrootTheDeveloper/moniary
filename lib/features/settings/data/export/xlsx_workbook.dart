import 'dart:convert';
import 'dart:typed_data';

class XlsxWorkbook {
  XlsxWorkbook({required this.sheetName, required this.rows});

  final String sheetName;
  final List<List<Object?>> rows;

  Uint8List build() {
    final files = <String, List<int>>{
      '[Content_Types].xml': utf8.encode(_contentTypes),
      '_rels/.rels': utf8.encode(_rootRels),
      'xl/workbook.xml': utf8.encode(_workbookXml),
      'xl/_rels/workbook.xml.rels': utf8.encode(_workbookRels),
      'xl/styles.xml': utf8.encode(_stylesXml),
      'xl/worksheets/sheet1.xml': utf8.encode(_sheetXml),
    };

    return _ZipStore(files).build();
  }

  String get _sheetXml {
    final buffer = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write(
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
      )
      ..write(
        '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>',
      )
      ..write('<cols>')
      ..write('<col min="1" max="1" width="13" customWidth="1"/>')
      ..write('<col min="2" max="2" width="36" customWidth="1"/>')
      ..write('<col min="3" max="3" width="20" customWidth="1"/>')
      ..write('<col min="4" max="4" width="13" customWidth="1"/>')
      ..write('<col min="5" max="5" width="15" customWidth="1"/>')
      ..write('<col min="6" max="6" width="20" customWidth="1"/>')
      ..write('<col min="7" max="7" width="20" customWidth="1"/>')
      ..write('<col min="8" max="8" width="26" customWidth="1"/>')
      ..write('<col min="9" max="9" width="22" customWidth="1"/>')
      ..write('<col min="10" max="10" width="30" customWidth="1"/>')
      ..write('<col min="11" max="11" width="22" customWidth="1"/>')
      ..write('<col min="12" max="12" width="16" customWidth="1"/>')
      ..write('<col min="13" max="13" width="13" customWidth="1"/>')
      ..write('<col min="14" max="14" width="13" customWidth="1"/>')
      ..write('</cols>')
      ..write('<sheetData>');

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final rowNumber = rowIndex + 1;
      buffer.write('<row r="$rowNumber">');
      final row = rows[rowIndex];
      for (var columnIndex = 0; columnIndex < row.length; columnIndex++) {
        final value = row[columnIndex];
        final cellRef = '${_columnName(columnIndex)}$rowNumber';
        final style = rowIndex == 0 ? ' s="1"' : '';
        if (value is num) {
          buffer.write('<c r="$cellRef"$style><v>$value</v></c>');
        } else {
          buffer.write(
            '<c r="$cellRef" t="inlineStr"$style><is><t>${_xml(value ?? '')}</t></is></c>',
          );
        }
      }
      buffer.write('</row>');
    }

    buffer
      ..write('</sheetData>')
      ..write('</worksheet>');
    return buffer.toString();
  }

  String get _workbookXml =>
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheets><sheet name="${_xml(sheetName)}" sheetId="1" r:id="rId1"/></sheets>'
      '</workbook>';

  static const _contentTypes =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '</Types>';

  static const _rootRels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>';

  static const _workbookRels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>';

  static const _stylesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<fonts count="2">'
        '<font><sz val="11"/><name val="Calibri"/></font>'
        '<font><b/><sz val="11"/><name val="Calibri"/></font>'
      '</fonts>'
      '<fills count="3">'
        '<fill><patternFill patternType="none"/></fill>'
        '<fill><patternFill patternType="gray125"/></fill>'
        '<fill>'
          '<patternFill patternType="solid">'
            '<fgColor rgb="FFF4EEE4"/>'
            '<bgColor indexed="64"/>'
          '</patternFill>'
        '</fill>'
      '</fills>'
      '<borders count="2">'
        '<border><left/><right/><top/><bottom/><diagonal/></border>'
        '<border>'
          '<left/>'
          '<right/>'
          '<top/>'
          '<bottom style="thin">'
            '<color rgb="FFD8CDBB"/>'
          '</bottom>'
          '<diagonal/>'
        '</border>'
      '</borders>'
      '<cellStyleXfs count="1">'
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>'
      '</cellStyleXfs>'
      '<cellXfs count="2">'
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>'
        '<xf numFmtId="0" fontId="1" fillId="2" borderId="1" applyFont="1" applyFill="1" applyBorder="1"/>'
      '</cellXfs>'
      '</styleSheet>';

  static String _columnName(int index) {
    var value = index + 1;
    final chars = <String>[];
    while (value > 0) {
      final remainder = (value - 1) % 26;
      chars.insert(0, String.fromCharCode(65 + remainder));
      value = (value - remainder - 1) ~/ 26;
    }
    return chars.join();
  }

  static String _xml(Object value) {
    return value
        .toString()
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

class _ZipStore {
  _ZipStore(this.files);

  final Map<String, List<int>> files;

  Uint8List build() {
    final output = BytesBuilder();
    final centralDirectory = BytesBuilder();
    var offset = 0;

    for (final entry in files.entries) {
      final nameBytes = utf8.encode(entry.key);
      final data = entry.value;
      final crc = _crc32(data);

      final localHeader = BytesBuilder()
        ..add(_u32(0x04034b50))
        ..add(_u16(20))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u32(crc))
        ..add(_u32(data.length))
        ..add(_u32(data.length))
        ..add(_u16(nameBytes.length))
        ..add(_u16(0))
        ..add(nameBytes);

      output
        ..add(localHeader.takeBytes())
        ..add(data);

      centralDirectory
        ..add(_u32(0x02014b50))
        ..add(_u16(20))
        ..add(_u16(20))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u32(crc))
        ..add(_u32(data.length))
        ..add(_u32(data.length))
        ..add(_u16(nameBytes.length))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u32(0))
        ..add(_u32(offset))
        ..add(nameBytes);

      offset += localHeader.length + data.length;
    }

    final centralBytes = centralDirectory.takeBytes();
    output
      ..add(centralBytes)
      ..add(_u32(0x06054b50))
      ..add(_u16(0))
      ..add(_u16(0))
      ..add(_u16(files.length))
      ..add(_u16(files.length))
      ..add(_u32(centralBytes.length))
      ..add(_u32(offset))
      ..add(_u16(0));

    return output.takeBytes();
  }

  static int _crc32(List<int> data) {
    var crc = 0xffffffff;
    for (final byte in data) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
      }
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }

  static Uint8List _u16(int value) {
    return Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.little);
  }

  static Uint8List _u32(int value) {
    return Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.little);
  }
}
