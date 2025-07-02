// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:io_file/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('exceptions', () {
    test('basic', () {
      expect(
        const IOFileException('cannot open file').toString(),
        'IOFileException: cannot open file',
      );
    });

    test('with path1', () {
      expect(
        const IOFileException('cannot open file', path1: '/foo/bar').toString(),
        'IOFileException: cannot open file: "/foo/bar"',
      );
    });

    test('with path2', () {
      expect(
        const IOFileException('cannot open file', path2: '/foo/bar').toString(),
        'IOFileException: cannot open file -> "/foo/bar"',
      );
    });

    test('with path1 and path2', () {
      expect(
        const IOFileException(
          'cannot rename file',
          path1: '/foo/baz',
          path2: '/foo/bar',
        ).toString(),
        'IOFileException: cannot rename file: '
        '"/foo/baz" -> "/foo/bar"',
      );
    });

    test('systemCall', () {
      expect(
        const IOFileException(
          'cannot open file',
          systemCall: 'open',
        ).toString(),
        'IOFileException: cannot open file '
        '[open failed]',
      );
    });

    test('errorCode', () {
      expect(
        const IOFileException('cannot open file', errorCode: 2).toString(),
        'IOFileException: cannot open file '
        '[errorCode: 2]',
      );
    });

    test('all arguments', () {
      expect(
        const IOFileException(
          'cannot rename file',
          path1: '/foo/baz',
          path2: '/foo/bar',
          systemCall: 'renameat',
          errorCode: 13,
        ).toString(),
        'IOFileException: cannot rename file: '
        '"/foo/baz" -> "/foo/bar" '
        '[renameat failed with errorCode: 13]',
      );
    });
  });
}
