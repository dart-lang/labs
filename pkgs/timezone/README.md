# TimeZone

Library to convert dates between TimeZones.

The data for Time Zones are from [http://www.iana.org/time-zones](the
IANA Time Zone Database).

## Usage Example

```dart
import 'package:timezone/browser.dart' as tz;

tz.initializeTimeZone()
.then(() {

  final now = new DateTime.now().millisecondsSinceEpoch;
  final nowEastern = tz.translateTime(now, 'US/Eastern');

});
```

## Updating Time Zone database

```sh
$ pub run tool/get -s 2014h
```