// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

///
/// Zone Info.
///
/// Most of this code were taken from the go standard library
/// [http://golang.org/src/pkg/time/zoneinfo.go](time/zoneinfo.go)
/// and ported to Dart.
///
/// Zone Info binary format:
///
/// ```
/// Location {
///   Header {
///     u32 nameLength;
///     u32 abbrsLength;
///     u32 zonesLength;
///     u32 transitionsLength;
///   }
///   Data {
///     u8 name[];
///     u8 abbrs[];
///
///     TimeZone {
///       i32 offset; // in seconds
///       u8 isDst;
///       u8 abbrIndex;
///     } zones[];
///
///     f64 transitionAt[]; // in seconds
///     u8 transitionZone[];
///   }
/// }
/// ```
///
part of timezone;

/// Zone Info header size.
const int _zoneInfoHeaderSize = 16;

/// Maximum value for time instants.
const int _omega = 8640000000000000;

/// Minimum value for time instants.
const int _alpha = -_omega;

/// A [Location] maps time instants to the zone in use at that time.
/// Typically, the Location represents the collection of time offsets
/// in use in a geographical area, such as CEST and CET for central Europe.
class Location {
  /// [Location] name.
  final String name;

  /// Transition time, in milliseconds since 1970 UTC.
  final List<int> transitionAt;

  /// The index of the zone that goes into effect at that time.
  final List<int> transitionZone;

  /// [TimeZone]s at this [Location].
  final List<TimeZone> zones;

  /// [TimeZone] for the current time.
  TimeZone get currentTimeZone =>
      timeZone(new DateTime.now().millisecondsSinceEpoch);

  // Most lookups will be for the current time.
  // To avoid the binary search through tx, keep a
  // static one-element cache that gives the correct
  // zone for the time when the Location was created.
  // if cacheStart <= t <= cacheEnd,
  // lookup can return cacheZone.
  // The units for cacheStart and cacheEnd are milliseconds
  // since January 1, 1970 UTC, to match the argument
  // to lookup.
  static int _cacheNow = new DateTime.now().millisecondsSinceEpoch;
  int _cacheStart = 0;
  int _cacheEnd = 0;
  TimeZone _cacheZone;

  Location(this.name, this.transitionAt, this.transitionZone, this.zones) {
    // Fill in the cache with information about right now,
    // since that will be the most common lookup.
    for (var i = 0; i < transitionAt.length; i++) {
      final tAt = transitionAt[i];

      if ((tAt <= _cacheNow) &&
          ((i + 1 == transitionAt.length) || (_cacheNow < transitionAt[i + 1]))) {
        _cacheStart = tAt;
        _cacheEnd = _omega;
        if (i + 1 < transitionAt.length) {
          _cacheEnd = transitionAt[i + 1];
        }
        _cacheZone = zones[transitionZone[i]];
      }
    }
  }

  factory Location.fromBytes(List<int> rawData) {
    final data =
        rawData is Uint8List ? rawData : new Uint8List.fromList(rawData);

    final bdata =
        data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);

    // read header
    final nameLength = bdata.getUint32(0);
    final abbrsLength = bdata.getUint32(4);
    final zonesLength = bdata.getUint32(8);
    final transitionsLength = bdata.getUint32(12);

    // read name
    final name = ASCII.decode(data.buffer.asUint8List(data.offsetInBytes + 16, nameLength));

    // read abbreviations
    final abbrs = [];

    final abbrsStart = 16 + nameLength;
    final abbrsEnd = abbrsStart + abbrsLength;
    var start = abbrsStart;
    for (var i = abbrsStart; i < abbrsEnd; i++) {
      if (data[i] == 0) {
        final abbr =
            ASCII.decode(data.buffer.asUint8List(data.offsetInBytes + start, i - start));
        abbrs.add(abbr);
        start = i + 1;
      }
    }

    // read zones
    final zones = [];

    var offset = abbrsEnd;
    for (var i = 0; i < zonesLength; i++) {
      final zoneOffset = bdata.getInt32(offset) * 1000; // convert to ms
      final zoneIsDst = bdata.getUint8(offset + 4);
      final zoneAbbrIndex = bdata.getUint8(offset + 5);
      offset += 6;
      zones.add(new TimeZone(zoneOffset, zoneIsDst == 1, abbrs[zoneAbbrIndex]));
    }

    // read transitions
    final transitionAt = [];
    final transitionZone = [];

    for (var i = 0; i < transitionsLength; i++) {
      transitionAt.add(bdata.getFloat64(offset).toInt() * 1000); // convert to ms
      offset += 8;
    }

    for (var i = 0; i < transitionsLength; i++) {
      transitionZone.add(bdata.getUint8(offset));
      offset += 1;
    }

    return new Location(name, transitionAt, transitionZone, zones);
  }

  /// translate instant in time expressed as milliseconds since
  /// January 1, 1970 00:00:00 UTC to this [Location].
  int translate(int millisecondsSinceEpoch) {
    return millisecondsSinceEpoch + timeZone(millisecondsSinceEpoch).offset;
  }

  /// translate instant in time expressed as milliseconds since
  /// January 1, 1970 00:00:00 to UTC.
  int translateToUtc(int millisecondsSinceEpoch) {
    final t = _lookupTimeZone(millisecondsSinceEpoch);
    final tz = t.i1;
    final start = t.i2;
    final end = t.i3;

    var utc = millisecondsSinceEpoch;

    if (tz.offset != 0) {
      utc -= tz.offset;

      if (utc < start) {
        utc = millisecondsSinceEpoch - _lookupTimeZone(start - 1).i1.offset;
      } else if (utc >= end) {
        utc = millisecondsSinceEpoch - _lookupTimeZone(end).i1.offset;
      }
    }

    return utc;
  }

  /// lookup for [TimeZone] and its boundaries for an instant in time expressed
  /// as milliseconds since January 1, 1970 00:00:00 UTC.
  PersistentTuple3<TimeZone, int, int> _lookupTimeZone(int millisecondsSinceEpoch) {
    if (zones.isEmpty) {
      return const PersistentTuple3(const TimeZone(0, false, 'UTC'), _alpha, _omega);
    }

    if (_cacheZone != null &&
        millisecondsSinceEpoch >= _cacheStart &&
        millisecondsSinceEpoch < _cacheEnd) {
      return new PersistentTuple3(_cacheZone, _cacheStart, _cacheEnd);
    }

    if (transitionAt.isEmpty || millisecondsSinceEpoch < transitionAt[0]) {
      final zone = _firstZone();
      final start = _alpha;
      final end = transitionAt.isEmpty ? _omega : transitionAt.first;
      return new PersistentTuple3(zone, start, end);
    }

    // Binary search for entry with largest millisecondsSinceEpoch <= sec.
    var lo = 0;
    var hi = transitionAt.length;
    var end = _omega;

    while (hi - lo > 1) {
      final m = lo + (hi - lo) ~/ 2;
      final at = transitionAt[m];

      if (millisecondsSinceEpoch < at) {
        end = at;
        hi = m;
      } else {
        lo = m;
      }
    }

    return new PersistentTuple3(zones[transitionZone[lo]], transitionAt[lo], end);
  }

  /// timeZone method returns [TimeZone] in use at an instant in time expressed
  /// as milliseconds since January 1, 1970 00:00:00 UTC.
  TimeZone timeZone(int millisecondsSinceEpoch) {
    return _lookupTimeZone(millisecondsSinceEpoch).i1;
  }

  /// timeZoneFromLocal method returns [TimeZone] in use at an instant in time
  /// expressed as milliseconds since January 1, 1970 00:00:00.
  TimeZone timeZoneFromLocal(int millisecondsSinceEpoch) {
    final t = _lookupTimeZone(millisecondsSinceEpoch);
    var tz = t.i1;
    final start = t.i2;
    final end = t.i3;

    if (tz.offset != 0) {
      final utc = millisecondsSinceEpoch - tz.offset;

      if (utc < start) {
        tz = _lookupTimeZone(start - 1).i1;
      } else if (utc >= end) {
        tz = _lookupTimeZone(end).i1;
      }
    }

    return tz;
  }

  /// This method returns the [TimeZone] to use for times before the first
  /// transition time, or when there are no transition times.
  ///
  /// The reference implementation in localtime.c from
  /// http://www.iana.org/time-zones/repository/releases/tzcode2013g.tar.gz
  /// implements the following algorithm for these cases:
  ///
  /// 1. If the first zone is unused by the transitions, use it.
  /// 2. Otherwise, if there are transition times, and the first
  ///    transition is to a zone in daylight time, find the first
  ///    non-daylight-time zone before and closest to the first transition
  ///    zone.
  /// 3. Otherwise, use the first zone that is not daylight time, if
  ///    there is one.
  /// 4. Otherwise, use the first zone.
  ///
  TimeZone _firstZone() {
    // case 1
    if (!_firstZoneIsUsed()) {
      return zones.first;
    }

    // case 2
    if (transitionZone.isNotEmpty && zones[transitionZone.first].isDst) {
      for (var zi = transitionZone.first - 1; zi >= 0; zi--) {
        final z = zones[zi];
        if (!z.isDst) {
          return z;
        }
      }
    }

    // case 3
    for (final zi in transitionZone) {
      final z = zones[zi];
      if (!z.isDst) {
        return z;
      }
    }

    // case 4
    return zones.first;
  }

  /// firstZoneUsed returns whether the first zone is used by some transition.
  bool _firstZoneIsUsed() {
    for (final i in transitionZone) {
      if (i == 0) {
        return true;
      }
    }

    return false;
  }

  /// Serialize [Location] in binary format.
  List<int> toBytes() {
    final abbrs = [];
    final abbrsIndex = new HashMap<String, int>();

    final zoneAbbrIndexes = [];

    // number of bytes of all abbrevs
    var abbrsLength = 0;

    for (final z in zones) {
      final ai = abbrsIndex.putIfAbsent(z.abbr, () {
        final ret = abbrs.length;
        abbrsLength += z.abbr.length + 1; // abbr + '\0'
        abbrs.add(z.abbr);
        return ret;
      });

      zoneAbbrIndexes.add(ai);
    }

    final encName = ASCII.encode(name);

    final bufferLength = (_zoneInfoHeaderSize +
        encName.length +
        abbrsLength +
        (zones.length * 6) +
        (transitionAt.length * 9));

    final result = new Uint8List(bufferLength);
    final buffer = new ByteData.view(result.buffer);

    // write header
    buffer.setUint32(0, encName.length);
    buffer.setUint32(4, abbrsLength);
    buffer.setUint32(8, zones.length);
    buffer.setUint32(12, transitionAt.length);

    var offset = 16;

    // write name
    for (final c in encName) {
      buffer.setUint8(offset++, c);
    }

    // write abbrevs
    for (final a in abbrs) {
      for (final c in a.codeUnits) {
        buffer.setUint8(offset++, c);
      }
      buffer.setUint8(offset++, 0);
    }

    // write zones
    for (var i = 0; i < zones.length; i++) {
      final zone = zones[i];
      buffer.setInt32(offset, zone.offset ~/ 1000); // convert to sec
      buffer.setUint8(offset + 4, zone.isDst ? 1 : 0);
      buffer.setUint8(offset + 5, zoneAbbrIndexes[i]);
      offset += 6;
    }

    // write transitions
    for (final tAt in transitionAt) {
      final t = tAt ~/ 1000;
      buffer.setFloat64(offset, t.toDouble()); // convert to sec
      offset += 8;
    }

    for (final tZone in transitionZone) {
      buffer.setUint8(offset, tZone);
      offset += 1;
    }

    return result;
  }

  String toString() => '$name';
}

/// A [TimeZone] represents a single time zone such as CEST or CET.
class TimeZone {
  /// Milliseconds east of UTC.
  final int offset;

  /// Is this [TimeZone] Daylight Savings Time?
  final bool isDst;

  /// Abbreviated name, "CET".
  final String abbr;

  const TimeZone(this.offset, this.isDst, this.abbr);

  bool operator ==(TimeZone other) {
    return (offset == other.offset &&
        isDst == other.isDst &&
        abbr == other.abbr);
  }

  int get hashCode {
    var result = 17;
    result = 37 * result + offset.hashCode;
    result = 37 * result + isDst.hashCode;
    result = 37 * result + abbr.hashCode;
    return result;
  }

  String toString() => '[$abbr offset=$offset dst=$isDst]';
}