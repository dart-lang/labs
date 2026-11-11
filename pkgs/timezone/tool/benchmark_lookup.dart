// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Benchmark the allocation-free zone lookup against the interval API.
//
// Run from pkgs/timezone:
//   dart run tool/benchmark_lookup.dart
//
// Run with the same Dart SDK and runtime mode before/after a change.
// Neither timing is a substitute for app-level startup and memory profiling.

import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz_data.initializeTimeZones();
  final location = tz.getLocation('Asia/Jerusalem');
  final now = DateTime.now().millisecondsSinceEpoch;

  // Mix the cached present-day interval with historical/future transitions.
  final inputs = List<int>.generate(4096, (index) {
    if (index.isEven) return now + (index % 3600) * 1000;
    return DateTime.utc(1940 + index % 100, 6).millisecondsSinceEpoch;
  });

  const repetitions = 300000;
  var checksum = 0;

  Duration measure(String label, tz.TimeZone Function(int) lookup) {
    for (var i = 0; i < 20000; i++) {
      checksum += lookup(inputs[i % inputs.length]).offset.inMinutes;
    }

    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < repetitions; i++) {
      checksum += lookup(inputs[i % inputs.length]).offset.inMinutes;
    }
    stopwatch.stop();
    print('$label: ${stopwatch.elapsedMicroseconds} us');
    return stopwatch.elapsed;
  }

  measure('timeZone (direct)', location.timeZone);
  measure('lookupTimeZone (interval)', (time) {
    return location.lookupTimeZone(time).timeZone;
  });
  // Prevent a hypothetical optimizing runtime from removing the work.
  print('checksum: $checksum');
}
