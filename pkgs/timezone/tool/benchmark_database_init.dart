// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Run from pkgs/timezone on the same Dart SDK and machine before/after
// changing the embedded database decoder:
//
//   dart run tool/benchmark_database_init.dart
//
// Report median initialization time and RSS; warm-up and process memory are
// not strict allocation measurements and should be corroborated with profiling.

import 'dart:io';
import 'package:timezone/data/latest_all.dart' as full_data;

void main() {
  const iterations = 9;
  final durations = <int>[];
  for (var i = 0; i < iterations; i++) {
    final timer = Stopwatch()..start();
    full_data.initializeTimeZones();
    timer.stop();
    durations.add(timer.elapsedMicroseconds);
    print(
      'run ${i + 1}: ${durations.last} us, '
      'RSS ${ProcessInfo.currentRss} bytes',
    );
  }
  // Ignore the first run while the Dart runtime warms up.
  final measured = durations.skip(1).toList()..sort();
  print('median (after warm-up): ${measured[measured.length ~/ 2]} us');
}
