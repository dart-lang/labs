# TimeZone

This package provides time zone database and time zone aware DateTime
object.

The time zone database is build from
[the IANA Time Zone Database](http://www.iana.org/time-zones).

## Initialization

TimeZone objects require time zone data, so the first step is to load
the time zone database.

We are providing two different APIs for browsers and standalone
environments.

### Initialization for browser environment

Import `package:timezone/browser.dart` library and run async function
`Future initializeTimeZone([String url])`.

```dart
import 'package:timezone/browser.dart';

initializeTimeZone().then((_) {
  final detroit = getLocation('America/Detroit');
  final now = new TZDateTime.now(detroit);
});
```

### Initialization for standalone environment

Import `package:timezone/standalone.dart` library and run async function
`Future initializeTimeZone([String dataPath])`.

```dart
import 'package:timezone/standalone.dart';

initializeTimeZone().then((_) {
  final detroit = getLocation('America/Detroit');
  final now = new TZDateTime.now(detroit);
});
```

### Local Location

After loading database, we are trying to detect local location.

To overwrite local location you can use `setLocalLocation(String
locationId)` function.

```dart
initializeTimeZone().then((_) {
  setLocalLocation('America/Detroit');
});
```

## API

### Location

> Each location in the database represents a national region where all
> clocks keeping local time have agreed since 1970. Locations are
> identified by continent or ocean and then by the name of the
> location, which is typically the largest city within the region. For
> example, America/New_York represents most of the US eastern time
> zone; America/Phoenix represents most of Arizona, which uses
> mountain time without daylight saving time (DST); America/Detroit
> represents most of Michigan, which uses eastern time but with
> different DST rules in 1975; and other entries represent smaller
> regions like Starke County, Indiana, which switched from central to
> eastern time in 1991 and switched back in 2006.
>
> [The tz database](http://www.twinsun.com/tz/tz-link.htm)

#### Get location by Olson timezone ID

```dart
final detroit = getLocation('America/Detroit');
```

We don't provide any functions to get locations by timezone
abbreviations because of the ambiguities.

> Alphabetic time zone abbreviations should not be used as unique
> identifiers for UTC offsets as they are ambiguous in practice. For
> example, "EST" denotes 5 hours behind UTC in English-speaking North
> America, but it denotes 10 or 11 hours ahead of UTC in Australia;
> and French-speaking North Americans prefer "HNE" to "EST".
>
> [The tz database](http://www.twinsun.com/tz/tz-link.htm)

### TimeZone

TimeZone object represents time zone and contains offset and name in
abbreviated form.

```dart
final timeInUtc = new DateTime.utc(1995, 1, 1);
final timeZone = detroit.timeZone(timeInUtc.millisecondsSinceEpoch);
```

### TimeZone aware DateTime

`TZDateTime` object implements standard `DateTime` interface and
contains information about location and time zone.

```dart
final date = new TZDateTime(detroit, 2014, 11, 17);
```

## Generating Time Zone database subsets

When there is no need to download the whole history of time zone
transitions, it is possible to generate database subset with the data
your application needs.

```sh
$ pub run timezone:generate_data_subset -f "2010-01-01 00:00:00z" -t "2020-01-01 00:00:00z" -o 2014h-2010-2020.tzf
```

Latest version of our database is ~370kb without compression and
~100kb with gzip.

## Time Zone database format

The database contains list of locations and each location contains
list of time zones with transition times to this time zones.

```
Location {
  u32 infoLength; // bytes count
  LocationInfo {
    Header {
      u32 nameLength;        // bytes count
      u32 abbrsLength;       // bytes count
      u32 zonesLength;       // zones count
      u32 transitionsLength; // transitions count
    }
    Data {
      u8 name[];  // name in ASCII
      u8 abbrs[]; // list of \0 terminated strings, abbreviations in ASCII
      TimeZone {
        i32 offset;   // offset in seconds
        u8 isDst;     // daylight savings time
        u8 abbrIndex; // position in abbrs[]
      }
      i64 transitionAt[];  // time when transition is occured
      u8 transitionZone[]; // transition time zone
    }
  }
} locations[];
```

## Updating Time Zone database

Script for updating Time Zone database, it will automatically download
[the IANA Time Zone Database](http://www.iana.org/time-zones) and
compile into our native format.

```sh
$ pub run tool/get -s 2014h
```

Argument `-s` is for specifying source version.