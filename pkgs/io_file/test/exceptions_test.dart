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
        'IOFileException: cannot open file, path1="/foo/bar"',
      );
    });

    test('with path2', () {
      expect(
        const IOFileException('cannot open file', path2: '/foo/bar').toString(),
        'IOFileException: cannot open file, path2="/foo/bar"',
      );
    });

    test('with path1 and path2', () {
      expect(
        const IOFileException(
          'cannot rename file',
          path1: '/foo/baz',
          path2: '/foo/bar',
        ).toString(),
        'IOFileException: cannot rename file, '
        'path1="/foo/baz", path2="/foo/bar"',
      );
    });

    test('system call', () {
      expect(
        const IOFileException(
          'cannot open file',
          systemCall: SystemCallError('open', 13, 'permission denied'),
        ).toString(),
        'IOFileException: cannot open file '
        '(open: permission denied, errorCode=13)',
      );
    });

    test('all arguments', () {
      expect(
        const IOFileException(
          'cannot rename file',
          path1: '/foo/baz',
          path2: '/foo/bar',
          systemCall: SystemCallError('open', 13, 'permission denied'),
        ).toString(),
        'IOFileException: cannot rename file, '
        'path1="/foo/baz", path2="/foo/bar" '
        '(rename: permission denied, errorCode=13)',
      );
    });
  });
}
