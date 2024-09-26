// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract final class Sendable<T> {
  static Sendable<T> wrap<T, U>(T Function(U) make, U data) {
    return _SendableImpl._(make, data);
  }

  T materialize();
}

final class _SendableImpl<T, U> implements Sendable<T> {
  final U _data;
  final T Function(U v) _make;

  _SendableImpl._(this._make, this._data);

  @override
  T materialize() => _make(_data);
}
