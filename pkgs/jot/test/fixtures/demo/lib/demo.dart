// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A sample library to exercise most Dart language features.

library;

import 'dart:io';
import 'dart:math';

// classes (https://dart.dev/language/classes)

const double xOrigin = 0;
const double yOrigin = 0;

class Point {
  static final Point zero = Point(0, 0);

  final double x, y;

  Point(this.x, this.y);

  // Named constructor
  Point.origin() : x = xOrigin, y = yOrigin;

  // factory constructor
  factory Point.fromJson(Map<String, Object> json) {
    return Point(json['x'] as double, json['y'] as double);
  }

  static double distanceBetween(Point a, Point b) {
    var dx = a.x - b.x;
    var dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }
}

class Vector2d {
  final double x;
  final double y;

  Vector2d(this.x, this.y);
}

// super parameters
class Vector3d extends Vector2d {
  final double z;

  // Forward the x and y parameters to the default super constructor like:
  // Vector3d(final double x, final double y, this.z) : super(x, y);
  Vector3d(super.x, super.y, this.z);
}

class Spacecraft {
  String name;
  DateTime? launchDate;

  // Read-only non-final property
  int? get launchYear => launchDate?.year;

  // Constructor, with syntactic sugar for assignment to members.
  Spacecraft(this.name, this.launchDate) {
    // Initialization code goes here.
  }

  // Named constructor that forwards to the default one.
  Spacecraft.unlaunched(String name) : this(name, null);

  // Method.
  void describe() {
    print('Spacecraft: $name');
    // Type promotion doesn't work on getters.
    var launchDate = this.launchDate;
    if (launchDate != null) {
      var years = DateTime.now().difference(launchDate).inDays ~/ 365;
      print('Launched: $launchYear ($years years ago)');
    } else {
      print('Unlaunched');
    }
  }
}

// mixins (https://dart.dev/language/mixins)

class Musician {
  // ...
}

mixin MusicalPerformer on Musician {
  // ...
}

class SingerDancer extends Musician with MusicalPerformer {
  // ...
}

// enums (https://dart.dev/language/enums)

enum Vehicle implements Comparable<Vehicle> {
  car(tires: 4, passengers: 5, carbonPerKilometer: 400),
  bus(tires: 6, passengers: 50, carbonPerKilometer: 800),
  bicycle(tires: 2, passengers: 1, carbonPerKilometer: 0);

  const Vehicle({
    required this.tires,
    required this.passengers,
    required this.carbonPerKilometer,
  });

  final int tires;
  final int passengers;
  final int carbonPerKilometer;

  int get carbonFootprint => (carbonPerKilometer / passengers).round();

  bool get isTwoWheeled => this == Vehicle.bicycle;

  @override
  int compareTo(Vehicle other) => carbonFootprint - other.carbonFootprint;
}

// extension methods (https://dart.dev/language/extension-methods)

extension NumberParsing on String {
  int parseInt() {
    return int.parse(this);
  }

  double parseDouble() {
    return double.parse(this);
  }
}

// functions (https://dart.dev/language/functions)

final List<int?> _nobleGases = [];

bool isNoble(int atomicNumber) {
  return _nobleGases[atomicNumber] != null;
}

// names parameters
void enableFlags({bool? bold, bool? hidden}) {}

// positional parameters
String say(String from, String msg, [String? device]) {
  var result = '$from says $msg';
  if (device != null) {
    result = '$result with a $device';
  }
  return result;
}

// returning multiple values
(String, int) foo() {
  return ('something', 42);
}

// generators
Iterable<int> naturalsTo(int n) sync* {
  var k = 0;
  while (k < n) {
    yield k++;
  }
}

Stream<int> asynchronousNaturalsTo(int n) async* {
  var k = 0;
  while (k < n) {
    yield k++;
  }
}

// records (https://dart.dev/language/records)

(String, String, {int a, bool b}) record = ('first', a: 2, b: true, 'last');

(int, int) swap((int, int) record) {
  var (a, b) = record;
  return (b, a);
}

(String, int) userInfo(Map<String, dynamic> json) {
  return (json['name'] as String, json['age'] as int);
}

// generics (https://dart.dev/language/generics)

abstract class Cache<T> {
  T getByKey(String key);
  void setByKey(String key, T value);
}

class Foo<T extends Object> {
  // Any type provided to Foo for T must be non-nullable.
}

T first<T>(List<T> ts) {
  // Do some initial work or error checking, then...
  var tmp = ts[0];
  // Do some additional checking or processing...
  return tmp;
}

// typedefs / type aliases (https://dart.dev/language/typedefs)

typedef IntList = List<int>;
IntList il = [1, 2, 3];

typedef ListMapper<X> = Map<X, List<X>>;
Map<String, List<String>> m1 = {}; // Verbose.
ListMapper<String> m2 = {}; // Same thing but shorter and clearer.

// function typedef
typedef Compare<T> = int Function(T a, T b);

// interfaces and abstract classes (https://dart.dev/language#interfaces-and-abstract-classes)

class MockSpaceship implements Spacecraft {
  @override
  DateTime? launchDate;

  @override
  String name = 'mock';

  @override
  void describe() => throw UnimplementedError();

  @override
  int? get launchYear => throw UnimplementedError();
}

abstract class Describable {
  void describe();

  void describeWithEmphasis() {
    print('=========');
    describe();
    print('=========');
  }
}

// inheritance (https://dart.dev/language#inheritance)

class Orbiter extends Spacecraft {
  double altitude;

  Orbiter(super.name, DateTime super.launchDate, this.altitude);
}

// async (https://dart.dev/language#async)

const oneSecond = Duration(seconds: 1);
// ···
Future<void> printWithDelay(String message) async {
  await Future<void>.delayed(oneSecond);
  print(message);
}

Future<void> createDescriptions(Iterable<String> objects) async {
  for (final object in objects) {
    try {
      var file = File('$object.txt');
      if (await file.exists()) {
        var modified = await file.lastModified();
        print('File for $object already exists. It was modified on $modified.');
        continue;
      }
      await file.create();
      await file.writeAsString('Start describing $object in this file.');
    } on IOException catch (e) {
      print('Cannot create description for $object: $e');
    }
  }
}

// variables (https://dart.dev/language#variables)

// ignore: type_annotate_public_apis
var name = 'Voyager I';
// ignore: type_annotate_public_apis
var year = 1977;
// ignore: type_annotate_public_apis
var antennaDiameter = 3.7;
// ignore: type_annotate_public_apis
var flybyObjects = ['Jupiter', 'Saturn', 'Uranus', 'Neptune'];
// ignore: type_annotate_public_apis
var image = {
  'tags': ['saturn'],
  'url': '//path/to/saturn.jpg',
};

// null safety (https://dart.dev/null-safety/understanding-null-safety)

String checkList(List<Object>? list) {
  if (list == null) return 'No list';
  if (list.isEmpty) {
    return 'Empty list';
  }
  return 'Got something';
}

// class modifiers (https://dart.dev/language/class-modifiers)

sealed class VehicleSealed {}

class CarSealed extends VehicleSealed {}

class TruckSealed implements VehicleSealed {}

class BicycleSealed extends VehicleSealed {}

// ERROR: Cannot be instantiated
// Vehicle myVehicle = Vehicle();

// Subclasses can be instantiated
VehicleSealed myCar = CarSealed();

String getVehicleSound(VehicleSealed vehicle) {
  // ERROR: The switch is missing the Bicycle subtype or a default case.
  return switch (vehicle) {
    CarSealed() => 'vroom',
    TruckSealed() => 'VROOOOMM',
    BicycleSealed() => throw UnimplementedError(),
  };
}

// extension types (https://dart.dev/language/extension-types)

abstract class JSObjectRepType {}

typedef JSAnyRepType = Object;

extension type JSAny._(JSAnyRepType _jsAny) implements Object {}

extension type JSObject._(JSObjectRepType _jsObject) implements JSAny {
  JSObject.fromInteropObject(Object interopObject)
    : _jsObject = interopObject as JSObjectRepType;

  // /// Creates a new JavaScript object.
  // JSObject() : _jsObject = _createObjectLiteral();
}

extension type EventInit._(JSObject _) implements JSObject {
  external factory EventInit({bool bubbles, bool cancelable, bool composed});

  external set bubbles(bool value);
  external bool get bubbles;
  external set cancelable(bool value);
  external bool get cancelable;
  external set composed(bool value);
  external bool get composed;
}

extension type ProgressEventInit._(JSObject _) implements EventInit, JSObject {
  external factory ProgressEventInit({
    bool lengthComputable,
    int loaded,
    int total,
  });

  external set lengthComputable(bool value);
  external bool get lengthComputable;
  external set loaded(int value);
  external int get loaded;
  external set total(int value);
  external int get total;
}
