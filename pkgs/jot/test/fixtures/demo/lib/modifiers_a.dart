// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// class modifiers (https://dart.dev/language/class-modifiers)
library;

// abstract

abstract class Vehicle {
  void moveForward(int meters);
}

// base

base class VehicleBase {
  void moveForward(int meters) {
    // ...
  }
}

// interface

interface class VehicleInterface {
  void moveForward(int meters) {
    // ...
  }
}

abstract interface class FruitInterface {
  void eat(int bites) {
    // ...
  }
}

final class AnimalInterface {
  void growl(int count) {
    // ...
  }
}
