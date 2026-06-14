// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

class AppEngineException implements Exception {
  final String message;

  const AppEngineException(this.message);

  @override
  String toString() => 'AppEngineException: $message';
}

class NetworkException extends AppEngineException implements IOException {
  NetworkException(super.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ProtocolException extends AppEngineException implements IOException {
  static const ProtocolException INVALID_RESPONSE =
      ProtocolException('Invalid response');

  const ProtocolException(super.message);

  @override
  String toString() => 'ProtocolException: $message';
}

class ServiceException extends AppEngineException {
  final String serviceName;

  ServiceException(super.message, {this.serviceName = 'ServiceException'});

  @override
  String toString() => '$serviceName: $message';
}

class ApplicationException extends AppEngineException {
  ApplicationException(super.message);

  @override
  String toString() => 'ApplicationException: $message';
}

@Deprecated('Use AppEngineException instead')
typedef AppEngineError = AppEngineException;

@Deprecated('Use NetworkException instead')
typedef NetworkError = NetworkException;

@Deprecated('Use ProtocolException instead')
typedef ProtocolError = ProtocolException;

@Deprecated('Use ServiceException instead')
typedef ServiceError = ServiceException;

@Deprecated('Use ApplicationException instead')
typedef ApplicationError = ApplicationException;
