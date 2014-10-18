# TimeZone

This package provides time zone database and time zone aware DateTime
object.

The time zone database is build from 
[http://www.iana.org/time-zones](the IANA Time Zone Database).

## Initialization

TimeZone objects require time zone data, so the first step is to load
the time zone database.

We are providing two different APIs for browsers and standalone
environments.

### Initialization for browser environment

Import `package:timezone/browser.dart` library and run async function
`initializeTimeZone([String url])`.

```dart
import 'package:timezone/browser.dart';

initializeTimeZone()
.then((_) {

  final detroit = getLocation('America/Detroit');
  final now = new TZDateTime.now(detroit);

});
```

### Initialization for standalone environment

Import `package:timezone/standalone.dart` library and run async function
`initializeTimeZone([String dataPath])`.

```dart
import 'package:timezone/standalone.dart';

initializeTimeZone()
.then((_) {

  final detroit = getLocation('America/Detroit');
  final now = new TZDateTime.now(detroit);

});
```

## API

### Location

Locations contain information about the history of local time zones.

#### Get location by Olson timezone ID

```dart
final detroit = getLocation('America/Detroit');
```

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
[http://www.iana.org/time-zones](the IANA Time Zone Database) and
compile into our native format.

```sh
$ pub run tool/get -s 2014h
```

Argument `-s` is for specifying source version.