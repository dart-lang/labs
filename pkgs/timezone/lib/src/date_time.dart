part of timezone;

/// TimeZone aware DateTime
class TZDateTime implements Comparable<TZDateTime> {
  // Weekday constants that are returned by [weekday] method:
  static const int MONDAY = 1;
  static const int TUESDAY = 2;
  static const int WEDNESDAY = 3;
  static const int THURSDAY = 4;
  static const int FRIDAY = 5;
  static const int SATURDAY = 6;
  static const int SUNDAY = 7;
  static const int DAYS_PER_WEEK = 7;

  // Month constants that are returned by the [month] getter.
  static const int JANUARY = 1;
  static const int FEBRUARY = 2;
  static const int MARCH = 3;
  static const int APRIL = 4;
  static const int MAY = 5;
  static const int JUNE = 6;
  static const int JULY = 7;
  static const int AUGUST = 8;
  static const int SEPTEMBER = 9;
  static const int OCTOBER = 10;
  static const int NOVEMBER = 11;
  static const int DECEMBER = 12;
  static const int MONTHS_PER_YEAR = 12;

  Location _location;

  TimeZone _timeZone;

  /// Native [DateTime] is used as a Calendar object
  DateTime _localDateTime;

  int _millisecondsSinceEpoch = 0;

  /// The number of milliseconds since
  /// the "Unix epoch" 1970-01-01T00:00:00Z (UTC).
  ///
  /// This value is independent of the time zone.
  ///
  /// This value is at most
  /// 8,640,000,000,000,000ms (100,000,000 days) from the Unix epoch.
  /// In other words: [:millisecondsSinceEpoch.abs() <= 8640000000000000:].
  int get millisecondsSinceEpoch => millisecondsSinceEpoch;

  /// [Location]
  Location get location => _location;

  /// [TimeZone]
  TimeZone get timeZone => _location.timeZone(millisecondsSinceEpoch);

  /// True if this [TZDateTime] is set to UTC time.
  ///
  /// ```dart
  /// final dDay = new TZDateTime.utc(1944, 6, 6);
  /// assert(dDay.isUtc);
  /// ```
  ///
  bool get isUtc => identical(_location, UTC);

  /// Constructs a [TZDateTime] instance specified in the [location] time zone.
  ///
  /// For example,
  /// to create a new DateTime object representing April 29, 2014, 6:04am:
  ///
  /// ```dart
  /// final detroit = getLocation('America/Detroit');
  ///
  /// final annularEclipse = new TZDateTime(location,
  ///     2014, TZDateTime.APRIL, 29, 6, 4);
  /// ```
  TZDateTime(Location location, int year, [int month = 1, int day = 1, int hour
      = 0, int minute = 0, int second = 0, int millisecond = 0])
      : _location = location,
        _localDateTime = new DateTime.utc(
          year,
          month,
          day,
          hour,
          minute,
          second,
          millisecond) {

    if (isUtc) {
      _timeZone = const TimeZone(0, false, 'UTC');
      _millisecondsSinceEpoch = _localDateTime.millisecondsSinceEpoch;
    } else {
      _timeZone =
          _location.timeZoneFromLocal(_localDateTime.millisecondsSinceEpoch);
      _millisecondsSinceEpoch =
          _localDateTime.millisecondsSinceEpoch - _timeZone.offset;
    }
  }

  /// Constructs a [TZDateTime] instance specified in the UTC time zone.
  ///
  /// ```dart
  /// final dDay = new TZDateTime.utc(1944, TZDateTime.JUNE, 6);
  /// ```
  TZDateTime.utc(int year, [int month = 1, int day = 1, int hour = 0, int minute
      = 0, int second = 0, int millisecond = 0])
      : this(UTC, year, month, day, hour, minute, second, millisecond);

  /// Constructs a [TZDateTime] instance with current date and time in the
  /// [location] time zone.
  ///
  /// ```dart
  /// final detroit = getLocation('America/Detroit');
  ///
  /// final thisInstant = new TZDateTime.now(detroit);
  /// ```
  TZDateTime.now(Location location) : _location = location {
    final now = new DateTime.now();
    _millisecondsSinceEpoch = now.millisecondsSinceEpoch;
    if (isUtc) {
      _timeZone = const TimeZone(0, false, 'UTC');
    } else {
      _timeZone = _location.timeZone(_millisecondsSinceEpoch);
    }
    _localDateTime =
        new DateTime.fromMillisecondsSinceEpoch(_millisecondsSinceEpoch, isUtc: true);
  }

  /// Constructs a new [TZDateTime] instance with the given
  /// [millisecondsSinceEpoch].
  ///
  /// The constructed [TZDateTime] represents
  /// 1970-01-01T00:00:00Z + [millisecondsSinceEpoch] ms in the given
  /// time zone [location].
  TZDateTime.fromMillisecondeSinceEpoch(Location location,
      int millisecondsSinceEpoch)
      : _location = location,
        _millisecondsSinceEpoch = millisecondsSinceEpoch,
        _localDateTime = new DateTime.fromMillisecondsSinceEpoch(
          millisecondsSinceEpoch,
          isUtc: true) {

    if (isUtc) {
      _timeZone = const TimeZone(0, false, 'UTC');
    } else {
      _timeZone = _location.timeZone(millisecondsSinceEpoch);
    }
  }

  /// Returns true if [other] is a [DateTime] at the same moment and in the
  /// same [Location].
  ///
  /// ```dart
  /// final detroit   = getLocation('America/Detroit');
  /// final dDayUtc   = new TZDateTime.utc(1944, DateTime.JUNE, 6);
  /// final dDayLocal = new TZDateTime(detroit, 1944, DateTime.JUNE, 6);
  ///
  /// assert(dDayUtc.isAtSameMomentAs(dDayLocal) == false);
  /// ````
  ///
  /// See [isAtSameMomentAs] for a comparison that adjusts for time zone.
  bool operator ==(other) {
    if (!(other is TZDateTime)) {
      return false;
    }

    return (millisecondsSinceEpoch == other.millisecondsSinceEpoch &&
            identical(_location, other._location));
  }

  /// Returns true if [this] occurs before [other].
  ///
  /// The comparison is independent of whether the time is in UTC or in other
  /// time zone.
  ///
  /// ```dart
  /// final berlinWallFell = new TZDateTime(UTC, 1989, 11, 9);
  /// final moonLanding    = new TZDateTime(UTC, 1969, 7, 20);
  ///
  /// assert(berlinWallFell.isBefore(moonLanding) == false);
  /// ```
  bool isBefore(DateTime other) {
    return millisecondsSinceEpoch < other.millisecondsSinceEpoch;
  }

  /// Returns true if [this] occurs after [other].
  ///
  /// The comparison is independent of whether the time is in UTC or in other
  /// time zone.
  ///
  /// ```dart
  /// final berlinWallFell = new TZDateTime(UTC, 1989, 11, 9);
  /// final moonLanding    = new TZDateTime(UTC, 1969, 7, 20);
  ///
  /// assert(berlinWallFell.isAfter(moonLanding) == true);
  /// ```
  bool isAfter(DateTime other) {
    return millisecondsSinceEpoch > other.millisecondsSinceEpoch;
  }

  /// Returns true if [this] occurs at the same moment as [other].
  ///
  /// The comparison is independent of whether the time is in UTC or in other
  /// time zone.
  ///
  /// ```dart
  /// final berlinWallFell = new TZDateTime(UTC, 1989, 11, 9);
  /// final moonLanding    = new TZDateTime(UTC, 1969, 7, 20);
  ///
  /// assert(berlinWallFell.isAtSameMomentAs(moonLanding) == false);
  /// ```
  bool isAtSameMomentAs(TZDateTime other) {
    return millisecondsSinceEpoch == other.millisecondsSinceEpoch;
  }

  /// Compares this [TZDateTime] object to [other],
  /// returning zero if the values are equal.
  ///
  /// This function returns a negative integer
  /// if this [TZDateTime] is smaller (earlier) than [other],
  /// or a positive integer if it is greater (later).
  int compareTo(TZDateTime other)
      => millisecondsSinceEpoch.compareTo(other.millisecondsSinceEpoch);

  int get hashCode => millisecondsSinceEpoch;

  /// The abbreviated time zone name&mdash;for example,
  /// [:"CET":] or [:"CEST":].
  String get timeZoneName => _timeZone.abbr;

  /// The time zone offset, which is the difference between time at [location]
  /// and UTC.
  ///
  /// The offset is positive for time zones east of UTC.
  ///
  /// Note, that JavaScript, Python and C return the difference between UTC and
  /// local time. Java, C# and Ruby return the difference between local time and
  /// UTC.
  Duration get timeZoneOffset => new Duration(milliseconds: _timeZone.offset);

  /// The year.
  int get year => _localDateTime.year;

  /// The month [1..12].
  int get month => _localDateTime.month;

  /// The day of the month [1..31].
  int get day => _localDateTime.day;

  /// The hour of the day, expressed as in a 24-hour clock [0..23].
  int get hour => _localDateTime.hour;

  /// The minute [0...59].
  int get minute => _localDateTime.minute;

  /// The second [0...59].
  int get second => _localDateTime.second;

  /// The millisecond [0...999].
  int get millisecond => _localDateTime.millisecond;

  /// The day of the week [MONDAY]..[SUNDAY].
  ///
  /// In accordance with ISO 8601
  /// a week starts with Monday, which has the value 1.
  int get weekday => _localDateTime.weekday;
}
