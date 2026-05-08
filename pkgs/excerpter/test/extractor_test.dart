// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:excerpter/src/extract.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  group('ExcerptExtractor exceptional cases', () {
    final extractor = ExcerptExtractor();

    test('missing file throws ExtractException', () async {
      final nonexistentPath = path.join(d.sandbox, 'nonexistent.dart');
      expect(
        () => extractor.extractRegion(nonexistentPath, 'my-region'),
        throwsA(
          isA<ExtractException>().having(
            (e) => e.toString(),
            'toString()',
            contains('No file exists at'),
          ),
        ),
      );
    });

    test('missing region throws ExtractException', () async {
      await d.file('simple.dart', '''
// #docregion existing-region
void main() {}
// #enddocregion existing-region
''').create();

      final filePath = path.join(d.sandbox, 'simple.dart');
      expect(
        () => extractor.extractRegion(filePath, 'nonexistent-region'),
        throwsA(
          isA<ExtractException>().having(
            (e) => e.toString(),
            'toString()',
            contains('does not exist in the file at'),
          ),
        ),
      );
    });

    test(
      'empty region name throws ExtractException with rich span format',
      () async {
        await d.file('empty_region.dart', '''
// #docregion a,,b
void main() {}
// #enddocregion a,,b
''').create();

        final filePath = path.join(d.sandbox, 'empty_region.dart');
        expect(
          () => extractor.extractRegion(filePath, 'a'),
          throwsA(
            isA<ExtractException>()
                .having(
                  (e) => e.message,
                  'message',
                  'docregion comment tried to use an empty region name.',
                )
                .having((e) => e.span?.text, 'span.text', '// #docregion a,,b')
                .having((e) => e.span?.start.line, 'span.start.line', 0)
                .having((e) => e.span?.start.column, 'span.start.column', 0),
          ),
        );
      },
    );

    test('unopened enddocregion throws ExtractException', () async {
      await d.file('unopened.dart', '''
void main() {}
// #enddocregion my-region
''').create();

      final filePath = path.join(d.sandbox, 'unopened.dart');
      expect(
        () => extractor.extractRegion(filePath, 'my-region'),
        throwsA(
          isA<ExtractException>().having(
            (e) => e.toString(),
            'toString()',
            contains(
              "enddocregion tried to close the unopened 'my-region' region",
            ),
          ),
        ),
      );
    });

    test('unclosed docregion throws ExtractException', () async {
      await d.file('unclosed.dart', '''
// #docregion my-region
void main() {}
''').create();

      final filePath = path.join(d.sandbox, 'unclosed.dart');
      expect(
        () => extractor.extractRegion(filePath, 'my-region'),
        throwsA(
          isA<ExtractException>().having(
            (e) => e.toString(),
            'toString()',
            contains('Regions {my-region} were not closed'),
          ),
        ),
      );
    });
  });
}
