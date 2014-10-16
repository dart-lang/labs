// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

part of timezone;

class TimeZoneInitializationException implements Exception {
  final String msg;

  TimeZoneInitializationException(this.msg);

  String toString() => msg == null ? 'TimeZoneInitializationException' : msg;
}
