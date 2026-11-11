import 'dart:typed_data';

/// A tiny TrueType/OpenType table reader for tests only (plan F-002 §2).
///
/// It reads the table directory, the `cmap` table (subtable formats 4 and 12),
/// default advance widths (`hhea` + `hmtx`) and the feature tags of the `GSUB`
/// table. That is enough to prove that a bundled font has a glyph for a code
/// point and has tabular figures (by default or through `tnum`).
class FontTables {
  new(Uint8List bytes)
    : _data = ByteData.sublistView(bytes),
      _tables = _readTableDirectory(ByteData.sublistView(bytes));

  final ByteData _data;
  final Map<String, int> _tables;

  static Map<String, int> _readTableDirectory(ByteData data) {
    final numTables = data.getUint16(4);
    return {
      for (var i = 0; i < numTables; i++)
        _tag(data, 12 + i * 16): data.getUint32(12 + i * 16 + 8),
    };
  }

  static String _tag(ByteData data, int offset) => String.fromCharCodes([
    for (var i = 0; i < 4; i++) data.getUint8(offset + i),
  ]);

  /// Table tags in the font, such as `cmap`, `GSUB`, `name`.
  Set<String> get tableTags => _tables.keys.toSet();

  /// Whether the `cmap` table maps [codePoint] to a real glyph (not glyph 0,
  /// the "missing" box).
  bool hasGlyph(int codePoint) => glyphId(codePoint) != 0;

  /// The glyph the `cmap` table maps [codePoint] to, or 0 if none.
  int glyphId(int codePoint) {
    final cmap = _tables['cmap'];
    if (cmap == null) return 0;
    final subtableCount = _data.getUint16(cmap + 2);
    for (var i = 0; i < subtableCount; i++) {
      final subtable = cmap + _data.getUint32(cmap + 4 + i * 8 + 4);
      final glyph = switch (_data.getUint16(subtable)) {
        4 => _format4Glyph(subtable, codePoint),
        12 => _format12Glyph(subtable, codePoint),
        _ => 0,
      };
      if (glyph != 0) return glyph;
    }
    return 0;
  }

  /// The default advance width (font units, from `hmtx`) of the glyph for
  /// [codePoint]. Equal widths for 0–9 mean the default digits are tabular.
  int advanceWidth(int codePoint) {
    final glyph = glyphId(codePoint);
    final metricCount = _data.getUint16(_tables['hhea']! + 34);
    final index = glyph < metricCount ? glyph : metricCount - 1;
    return _data.getUint16(_tables['hmtx']! + index * 4);
  }

  int _format4Glyph(int subtable, int codePoint) {
    if (codePoint > 0xFFFF) return 0;
    final segCount = _data.getUint16(subtable + 6) ~/ 2;
    final endCodes = subtable + 14;
    final startCodes = endCodes + segCount * 2 + 2;
    final idDeltas = startCodes + segCount * 2;
    final idRangeOffsets = idDeltas + segCount * 2;
    for (var s = 0; s < segCount; s++) {
      final end = _data.getUint16(endCodes + s * 2);
      if (codePoint > end) continue;
      final start = _data.getUint16(startCodes + s * 2);
      if (codePoint < start) return 0;
      final delta = _data.getUint16(idDeltas + s * 2);
      final rangeOffsetAt = idRangeOffsets + s * 2;
      final rangeOffset = _data.getUint16(rangeOffsetAt);
      if (rangeOffset == 0) return (codePoint + delta) & 0xFFFF;
      final glyph = _data.getUint16(
        rangeOffsetAt + rangeOffset + (codePoint - start) * 2,
      );
      return glyph == 0 ? 0 : (glyph + delta) & 0xFFFF;
    }
    return 0;
  }

  int _format12Glyph(int subtable, int codePoint) {
    final groupCount = _data.getUint32(subtable + 12);
    for (var g = 0; g < groupCount; g++) {
      final group = subtable + 16 + g * 12;
      final start = _data.getUint32(group);
      final end = _data.getUint32(group + 4);
      if (codePoint >= start && codePoint <= end) {
        return _data.getUint32(group + 8) + (codePoint - start);
      }
    }
    return 0;
  }

  /// Feature tags listed in the `GSUB` FeatureList, such as `tnum`, `liga`.
  Set<String> get gsubFeatures {
    final gsub = _tables['GSUB'];
    if (gsub == null) return const {};
    final featureList = gsub + _data.getUint16(gsub + 6);
    final count = _data.getUint16(featureList);
    return {
      for (var i = 0; i < count; i++) _tag(_data, featureList + 2 + i * 6),
    };
  }
}
