// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

/// Locations database
part of timezone;

/// [LocationDatabase] provides interface to find [Location]s by their name.
///
/// ```dart
/// List<int> data = load(); // load database
///
/// LocationDatabase db = new LocationDatabase.fromBytes(data);
/// Location loc = db.get('US/Eastern');
/// ```
class LocationDatabase {
  /// Mapping between [Location] name and [Location].
  final Map<String, Location> _locations = new Map<String, Location>();

  Map<String, Location> get locations => _locations;

  LocationDatabase();

  factory LocationDatabase.fromBytes(List<int> rawData) {
    final data =
        rawData is Uint8List ? rawData : new Uint8List.fromList(rawData);

    final bdata =
        data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);

    final result = new LocationDatabase();

    var offset = 0;
    while (offset < data.length) {
      final length = bdata.getUint32(offset);
      final locationBytes =
          data.buffer.asUint8List(data.offsetInBytes + offset + 4, length);
      final location = new Location.fromBytes(locationBytes);
      offset += 4 + length;
      result.add(location);
    }

    return result;
  }

  /// Add [Location] to the database.
  void add(Location location) {
    _locations[location.name] = location;
  }

  /// Find [Location] by its name.
  Location get(String name) {
    final loc = _locations[name];
    if (loc == null) {
      throw new LocationNotFoundException('Location with the name "$name" doesn\'t exist');
    }
    return loc;
  }

  /// Serialize [LocationDatabase] in binary format.
  List<int> toBytes() {
    final locationsInBytes = [];
    var bufferLength = 0;

    for (final l in _locations.values) {
      final b = l.toBytes();
      locationsInBytes.add(b);
      bufferLength += 4 + b.length;
    }

    final r = new Uint8List(bufferLength);
    final rb = r.buffer.asByteData();

    var offset = 0;
    for (final b in locationsInBytes) {
      rb.setUint32(offset, b.length);
      r.setAll(offset + 4, b);

      offset += 4 + b.length;
    }

    return r;
  }
}
