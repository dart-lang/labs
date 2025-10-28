// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'modifiers_a.dart';

// abstract

// Error: Cannot be constructed
// Vehicle myVehicle = Vehicle();

// Can be extended
class Car extends Vehicle {
  int passengers = 4;

  @override
  void moveForward(int meters) {
    // TODO: implement moveForward
  }
}

// Can be implemented
class MockVehicle implements Vehicle {
  @override
  void moveForward(int meters) {
    // ...
  }
}

// base

// Can be constructed
VehicleBase myVehicle = VehicleBase();

// Can be extended
base class CarBase extends VehicleBase {
  int passengers = 4;
  // ...
}

// ERROR: Cannot be implemented
// base class MockVehicleBase implements VehicleBase {
//   @override
//   void moveForward() {
//     // ...
//   }
// }

// interface

// Can be constructed
VehicleInterface myVehicle2 = VehicleInterface();

// ERROR: Cannot be inherited
// class Car extends Vehicle {
//   int passengers = 4;
//   // ...
// }

// Can be implemented
class MockVehicleInterface implements VehicleInterface {
  @override
  void moveForward(int meters) {
    // ...
  }
}
