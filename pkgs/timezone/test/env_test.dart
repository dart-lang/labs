@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

void main() {
  group('.UTC', () {
    test('with name Etc/UTC', () {
      expect(UTC.name, 'Etc/UTC');
    });

    test('same instance on every access', () {
      expect(identical(UTC, UTC), isTrue);
      final first = UTC;
      final second = UTC;
      expect(identical(first, second), isTrue);
    });
  });

  group('#getLocation', () {
    test('throws when database not initialized', () {
      expect(
        () => getLocation('America/New_York'),
        throwsA(
          const TypeMatcher<LocationNotFoundException>().having(
            (e) => e.msg,
            'msg',
            contains('database'),
          ),
        ),
      );
    });

    group('when database initialized', () {
      setUpAll(initializeTimeZones);

      test('retrieves for known name', () {
        final detroit = getLocation('America/Detroit');
        expect(detroit.name, 'America/Detroit');
      });

      test('same instance for same name', () {
        final a = getLocation('America/Los_Angeles');
        final b = getLocation('America/Los_Angeles');
        expect(identical(a, b), isTrue);
      });

      test('throws for unknown name', () {
        expect(
          () => getLocation('non-existent-location'),
          throwsA(const TypeMatcher<LocationNotFoundException>()),
        );
      });
    });
  });

  group('#setLocalLocation', () {
    setUpAll(initializeTimeZones);

    tearDown(() {
      setLocalLocation(UTC);
    });

    test('updates local to the given location', () {
      final detroit = getLocation('America/Detroit');
      setLocalLocation(detroit);
      expect(identical(local, detroit), isTrue);
    });

    test('subsequent local read returns last set location', () {
      final la = getLocation('America/Los_Angeles');
      final detroit = getLocation('America/Detroit');
      setLocalLocation(la);
      expect(identical(local, la), isTrue);
      setLocalLocation(detroit);
      expect(identical(local, detroit), isTrue);
    });
  });

  group('#initializeDatabase', () {
    test('local is Etc/UTC by default', () {
      initializeTimeZones();
      expect(identical(local, UTC), isTrue);
    });

    test('re-initialization resets local to UTC', () {
      initializeTimeZones();
      final detroit = getLocation('America/Detroit');
      setLocalLocation(detroit);
      expect(identical(local, detroit), isTrue);
      initializeTimeZones();
      expect(identical(local, UTC), isTrue);
    });

    test('populates database so getLocation resolves names', () {
      initializeTimeZones();
      final loc = getLocation('America/New_York');
      expect(loc.name, 'America/New_York');
    });
  });
}
