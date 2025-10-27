# Library: modifiers_b.dart

## Members

- accessor `VehicleBase get myVehicle`
- accessor `set myVehicle=(VehicleBase _myVehicle)`
- accessor `VehicleInterface get myVehicle2`
- accessor `set myVehicle2=(VehicleInterface _myVehicle2)`

## Class: Car

```dart
class Car extends Vehicle { … }
```

- `int passengers`
- `void moveForward(int meters)`

## Class: CarBase

```dart
class CarBase extends VehicleBase { … }
```

- `int passengers`

## Class: MockVehicle

```dart
class MockVehicle implements Vehicle { … }
```

- `void moveForward(int meters)`

## Class: MockVehicleInterface

```dart
class MockVehicleInterface implements VehicleInterface { … }
```

- `void moveForward(int meters)`
