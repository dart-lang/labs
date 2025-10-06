// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart' as ffi;
import 'package:unix_api/unix_api.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('dirent', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('dirent');
    });

    tearDown(() {
      tmp.deleteSync(recursive: true);
    });

    test('test', () {
      File(p.join(tmp.path, 'test1')).createSync();
      Directory(p.join(tmp.path, 'dir1')).createSync();

      ffi.using((arena) {
        final dir = opendir(tmp.path.toNativeUtf8(allocator: arena).cast());
        expect(dir, isNot(nullptr));

        final paths = <String>[];
        for (
          var dirent = readdir(dir);
          dirent != nullptr;
          dirent = readdir(dir)
        ) {
          paths.add(dirent.d_name_ptr.cast<ffi.Utf8>().toDartString());
        }

        expect(paths, containsAll(['test1', 'dir1']));
        expect(closedir(dir), 0);
      });
    });
  });
}
