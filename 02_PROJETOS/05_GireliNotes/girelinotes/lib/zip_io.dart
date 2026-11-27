import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Um arquivo dentro de um .zip.
class ZipEntry {
  ZipEntry(this.name, this.data);
  final String name; // com "/" separando pastas
  final Uint8List data;
}

final List<int> _crcTable = () {
  final t = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
    }
    t[n] = c;
  }
  return t;
}();

int crc32(Uint8List data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

/// Monta um .zip sem compressão (os .notas já são gzip e os PDFs já são
/// comprimidos). Nomes em UTF-8.
Uint8List writeZip(List<ZipEntry> entries, {DateTime? when}) {
  final t = when ?? DateTime.now();
  final dosTime = (t.hour << 11) | (t.minute << 5) | (t.second ~/ 2);
  final dosDate = ((t.year - 1980).clamp(0, 127) << 9) | (t.month << 5) | t.day;
  final out = BytesBuilder();
  final cd = BytesBuilder();

  void u16(BytesBuilder b, int v) => b.add([v & 0xFF, (v >> 8) & 0xFF]);
  void u32(BytesBuilder b, int v) =>
      b.add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);

  for (final e in entries) {
    final name = utf8.encode(e.name);
    final crc = crc32(e.data);
    final offset = out.length;
    u32(out, 0x04034b50);
    u16(out, 20); // versão
    u16(out, 0x0800); // nomes em UTF-8
    u16(out, 0); // sem compressão
    u16(out, dosTime);
    u16(out, dosDate);
    u32(out, crc);
    u32(out, e.data.length);
    u32(out, e.data.length);
    u16(out, name.length);
    u16(out, 0);
    out.add(name);
    out.add(e.data);

    u32(cd, 0x02014b50);
    u16(cd, 20);
    u16(cd, 20);
    u16(cd, 0x0800);
    u16(cd, 0);
    u16(cd, dosTime);
    u16(cd, dosDate);
    u32(cd, crc);
    u32(cd, e.data.length);
    u32(cd, e.data.length);
    u16(cd, name.length);
    u16(cd, 0);
    u16(cd, 0);
    u16(cd, 0);
    u16(cd, 0);
    u32(cd, 0);
    u32(cd, offset);
    cd.add(name);
  }
  final cdOffset = out.length;
  final cdBytes = cd.toBytes();
  out.add(cdBytes);
  u32(out, 0x06054b50);
  u16(out, 0);
  u16(out, 0);
  u16(out, entries.length);
  u16(out, entries.length);
  u32(out, cdBytes.length);
  u32(out, cdOffset);
  u16(out, 0);
  return out.toBytes();
}

/// Lê um .zip (sem compressão ou deflate). Lança [FormatException] se não for zip.
List<ZipEntry> readZip(Uint8List b) {
  final d = ByteData.sublistView(b);
  var e = b.length - 22;
  while (e >= 0 && d.getUint32(e, Endian.little) != 0x06054b50) {
    e--;
  }
  if (e < 0) throw const FormatException('Arquivo não é um .zip.');
  final count = d.getUint16(e + 10, Endian.little);
  var off = d.getUint32(e + 16, Endian.little);
  final out = <ZipEntry>[];
  for (var i = 0; i < count; i++) {
    if (off + 46 > b.length || d.getUint32(off, Endian.little) != 0x02014b50) {
      throw const FormatException('.zip danificado.');
    }
    final method = d.getUint16(off + 10, Endian.little);
    final csize = d.getUint32(off + 20, Endian.little);
    final nameLen = d.getUint16(off + 28, Endian.little);
    final extraLen = d.getUint16(off + 30, Endian.little);
    final commentLen = d.getUint16(off + 32, Endian.little);
    final local = d.getUint32(off + 42, Endian.little);
    final name = utf8.decode(b.sublist(off + 46, off + 46 + nameLen), allowMalformed: true);
    off += 46 + nameLen + extraLen + commentLen;

    final nl = d.getUint16(local + 26, Endian.little);
    final el = d.getUint16(local + 28, Endian.little);
    final start = local + 30 + nl + el;
    final raw = Uint8List.sublistView(b, start, start + csize);
    final Uint8List data;
    if (method == 0) {
      data = raw;
    } else if (method == 8) {
      data = Uint8List.fromList(ZLibCodec(raw: true).decode(raw));
    } else {
      continue; // compressão que não conhecemos: ignora este arquivo
    }
    if (!name.endsWith('/')) out.add(ZipEntry(name, data));
  }
  return out;
}
