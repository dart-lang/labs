# TimeZone

Library to convert date times between TimeZones.

The data for Time Zones are from [http://www.iana.org/time-zones](the
IANA Time Zone Database).

## Initialization

TimeZone objects require time zone data, so the first step is to load
the data.

We are providing two different APIs for browsers and standalone
environments.

### Initialization for browser environment

Import `package:timezone/browser.dart` library and run async function
`initializeTimeZone([String url])`.

This function has optional argument with the path to the data url.

```dart
import 'package:timezone/browser.dart';

tz.initializeTimeZone()
.then((_) {

  final detroit = getLocation('America/Detroit');
  final now = new TZDateTime.now(detroit);

});
```

### Initialization for standalone environment

Import `package:timezone/standalone.dart` library and run async function
`initializeTimeZone()`.

```dart
import 'package:timezone/standalone.dart';

tz.initializeTimeZone()
.then((_) {

  final detroit = getLocation('America/Detroit');
  final now = new TZDateTime.now(detroit);

});
```

## API

### Location

```dart
final detroit = getLocation('America/Detroit');
```

### TimeZone

TimeZone object represents time zone and contains offset and name in
abbreviated form.

### TimeZone aware DateTime

`TZDateTime` object implements standard `DateTime` interface and
contains information about the time zone.

```dart
final date = new TZDateTime(detroit, 2014, 11, 17);
```

## Generating Time Zone database subsets

```sh
$ pub run timezone:generate_data_subset --from "2010-1-1" --to "2020-1-1"
```

## Updating Time Zone database

```sh
$ pub run tool/get -s 2014h
```
