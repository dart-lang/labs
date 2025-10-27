# Library: demo.dart

A sample library to exercise most Dart language features.

## Members

- accessor `double get antennaDiameter`
- accessor `set antennaDiameter=(double _antennaDiameter)`
- accessor `List<String> get flybyObjects`
- accessor `set flybyObjects=(List<String> _flybyObjects)`
- accessor `List<int> get il`
- accessor `set il=(List<int> _il)`
- accessor `Map<String, Object> get image`
- accessor `set image=(Map<String, Object> _image)`
- accessor `Map<String, List<String>> get m1`
- accessor `set m1=(Map<String, List<String>> _m1)`
- accessor `Map<String, List<String>> get m2`
- accessor `set m2=(Map<String, List<String>> _m2)`
- accessor `set myCar=(VehicleSealed _myCar)`
- accessor `VehicleSealed get myCar`
- accessor `String get name`
- accessor `set name=(String _name)`
- accessor `Duration get oneSecond`
- accessor `(String, String, {int a, bool b}) get record`
- accessor `set record=((String, String, {int a, bool b}) _record)`
- accessor `double get xOrigin`
- accessor `double get yOrigin`
- accessor `int get year`
- accessor `set year=(int _year)`
- function `Stream<int> asynchronousNaturalsTo(int n)`
- function `String checkList(List<Object>? list)`
- function `Future<void> createDescriptions(Iterable<String> objects)`
- function `void enableFlags({bool? bold, bool? hidden})`
- function `T first<T>(List<T> ts)`
- function `(String, int) foo()`
- function `String getVehicleSound(VehicleSealed vehicle)`
- function `bool isNoble(int atomicNumber)`
- function `Iterable<int> naturalsTo(int n)`
- function `Future<void> printWithDelay(String message)`
- function `String say(String from, String msg, [String? device])`
- function `(int, int) swap((int, int) record)`
- function `(String, int) userInfo(Map<String, dynamic> json)`
- type alias `typedef Compare<T> = int Function(T, T)`
- type alias `typedef IntList = List<int>`
- type alias `typedef JSAnyRepType = Object`
- type alias `typedef ListMapper<X> = Map<X, List<X>>`

## Enum: Vehicle

```dart
enum Vehicle implements Comparable<Vehicle> { … }
```

- `Vehicle({required int tires, required int passengers, required int carbonPerKilometer})`
- `bicycle`
- `bus`
- `car`
- `int carbonPerKilometer`
- `int passengers`
- `int tires`
- `int get carbonFootprint`
- `bool get isTwoWheeled`
- `int compareTo(Vehicle other)`: Compares this object to another object.

## Mixin: MusicalPerformer

```dart
mixin MusicalPerformer on Musician { … }
```

## Class: BicycleSealed

```dart
class BicycleSealed extends VehicleSealed { … }
```

## Class: Cache

```dart
abstract class Cache<T> { … }
```

- `T getByKey(String key)`
- `void setByKey(String key, T value)`

## Class: CarSealed

```dart
class CarSealed extends VehicleSealed { … }
```

## Class: Describable

```dart
abstract class Describable { … }
```

- `void describe()`
- `void describeWithEmphasis()`

## Class: Foo

```dart
class Foo<T extends Object> { … }
```

## Class: JSObjectRepType

```dart
abstract class JSObjectRepType { … }
```

## Class: MockSpaceship

```dart
class MockSpaceship implements Spacecraft { … }
```

- `DateTime? launchDate`
- `String name`
- `int? get launchYear`
- `void describe()`

## Class: Musician

```dart
class Musician { … }
```

## Class: Orbiter

```dart
class Orbiter extends Spacecraft { … }
```

- `Orbiter(String name, DateTime launchDate, double altitude)`
- `double altitude`

## Class: Point

```dart
class Point { … }
```

- `Point(double x, double y)`
- `Point.fromJson(Map<String, Object> json)`
- `Point.origin()`
- static `Point zero`
- static `double distanceBetween(Point a, Point b)`
- `double x`
- `double y`

## Class: SingerDancer

```dart
class SingerDancer extends Musician with MusicalPerformer { … }
```

## Class: Spacecraft

```dart
class Spacecraft { … }
```

- `Spacecraft(String name, DateTime? launchDate)`
- `Spacecraft.unlaunched(String name)`
- `DateTime? launchDate`
- `String name`
- `int? get launchYear`
- `void describe()`

## Class: TruckSealed

```dart
class TruckSealed implements VehicleSealed { … }
```

## Class: Vector2d

```dart
class Vector2d { … }
```

- `Vector2d(double x, double y)`
- `double x`
- `double y`

## Class: Vector3d

```dart
class Vector3d extends Vector2d { … }
```

- `Vector3d(double x, double y, double z)`
- `double z`

## Class: VehicleSealed

```dart
sealed class VehicleSealed { … }
```

## Extension: NumberParsing

```dart
extension NumberParsing on String { … }
```

- `double parseDouble()`
- `int parseInt()`

## Extension type: EventInit

EventInit

- `EventInit({bool bubbles, bool cancelable, bool composed})`
- `set bubbles=(bool value)`
- `bool get bubbles`
- `set cancelable=(bool value)`
- `bool get cancelable`
- `set composed=(bool value)`
- `bool get composed`

## Extension type: JSAny

JSAny

## Extension type: JSObject

JSObject

- `JSObject.fromInteropObject(Object interopObject)`

## Extension type: ProgressEventInit

ProgressEventInit

- `ProgressEventInit({bool lengthComputable, int loaded, int total})`
- `set lengthComputable=(bool value)`
- `bool get lengthComputable`
- `set loaded=(int value)`
- `int get loaded`
- `set total=(int value)`
- `int get total`
