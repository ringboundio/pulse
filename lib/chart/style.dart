import 'dart:typed_data';
import 'dart:ui';

class ChartStyleKey {
  const ChartStyleKey(this.value);

  final String value;

  @override
  bool operator ==(Object other) {
    if (other is! ChartStyleKey) {
      return false;
    }
    return other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

class ChartPaintStyle {
  ChartPaintStyle({
    required this.strokeColor,
    required this.strokeWidth,
    required this.strokeCap,
    required this.strokeJoin,
    required Float64List dashPattern,
    required this.fillColor,
  }) : dashPattern = Float64List.fromList(dashPattern);

  final Color strokeColor;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final Float64List dashPattern;
  final Color fillColor;
}

class ChartStyleEntry {
  const ChartStyleEntry(this.key, this.style);

  final ChartStyleKey key;
  final ChartPaintStyle style;
}

class ChartStyleSheet {
  ChartStyleSheet(this.revision, List<ChartStyleEntry> entries)
    : entries = List<ChartStyleEntry>.unmodifiable(entries);

  final int revision;
  final List<ChartStyleEntry> entries;

  bool contains(ChartStyleKey key) {
    for (final ChartStyleEntry entry in entries) {
      if (entry.key == key) {
        return true;
      }
    }
    return false;
  }

  ChartPaintStyle resolve(ChartStyleKey key) {
    for (final ChartStyleEntry entry in entries) {
      if (entry.key == key) {
        return entry.style;
      }
    }
    throw StateError('Missing style for key ${key.value}');
  }

  ChartStyleSheet override({
    required ChartStyleKey key,
    required ChartPaintStyle style,
  }) {
    final List<ChartStyleEntry> updated = <ChartStyleEntry>[];
    bool replaced = false;
    for (final ChartStyleEntry entry in entries) {
      if (entry.key == key) {
        updated.add(ChartStyleEntry(key, style));
        replaced = true;
      } else {
        updated.add(entry);
      }
    }
    if (!replaced) {
      updated.add(ChartStyleEntry(key, style));
    }
    return ChartStyleSheet(revision + 1, updated);
  }
}
