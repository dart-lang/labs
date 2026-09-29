// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:gcloud/db.dart' as db;
import 'package:gcloud/storage.dart' as storage;

import '../appengine_context.dart';
import '../client_context.dart';
import '../logging.dart';
import '../logging_impl.dart';

abstract class LoggerFactory {
  LoggingImpl newRequestSpecificLogger(
      String method,
      String resource,
      String userAgent,
      String host,
      String ip,
      String? traceId,
      String referrer);
  Logging newBackgroundLogger();
}

/// Sanity check for traceId (must be 32 char hex)
final _traceIdFormat = RegExp(r'^[0-9a-f]{32}$');

class ContextRegistry {
  final LoggerFactory _loggingFactory;
  final db.DatastoreDB _db;
  final storage.Storage _storage;
  final AppEngineContext _appengineContext;

  final Map<HttpRequest, ClientContext> _request2context = {};

  ContextRegistry(
      this._loggingFactory, this._db, this._storage, this._appengineContext);

  bool get isDevelopmentEnvironment {
    return _appengineContext.isDevelopmentEnvironment;
  }

  ClientContext add(HttpRequest request) {
    String? traceId;
    // See https://docs.cloud.google.com/trace/docs/trace-context#legacy-http-header
    final traceHeader = _headerOrEmptyString(
      request.headers,
      'X-Cloud-Trace-Context',
    );
    if (traceHeader != '') {
      final traceIdFromHeader = traceHeader.split('/').first;
      if (_traceIdFormat.hasMatch(traceIdFromHeader)) {
        traceId = traceIdFromHeader;
      }
    }

    final services = _getServices(request, traceId);
    final context = _ClientContextImpl(services, _appengineContext, traceId);
    _request2context[request] = context;

    request.response.done.whenComplete(() {
      final int responseSize = request.response.headers.contentLength;
      (services.logging as LoggingImpl)
          .finish(request.response.statusCode, responseSize);
    });

    return context;
  }

  ClientContext? lookup(HttpRequest request) {
    return _request2context[request];
  }

  Future remove(HttpRequest request) {
    _request2context.remove(request);
    return Future.value();
  }

  Services newBackgroundServices() => _getServices(null, null);

  Services _getServices(HttpRequest? request, String? traceId) {
    Logging loggingService;
    if (request != null) {
      final uri = request.requestedUri;
      final resource = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
      final List<String>? forwardedFor = request.headers['x-forwarded-for'];

      String ip;
      if (forwardedFor != null && forwardedFor.isNotEmpty) {
        // Google Cloud Load Balancers append the connecting client IP and the
        // load balancer IP to any existing `X-Forwarded-For` values.
        // Client-supplied (possibly spoofed) IPs appear first, so we use
        // the second-to-last IP as the client IP that arrived at GCLB.
        // See: https://cloud.google.com/load-balancing/docs/https#x-forwarded-for_header
        final parts = forwardedFor
            .expand((header) => header.split(','))
            .map((ip) => ip.trim())
            .where((ip) => ip.isNotEmpty)
            .toList();
        ip = parts.length >= 2
            ? parts[parts.length - 2]
            : request.connectionInfo!.remoteAddress.host;
      } else {
        ip = request.connectionInfo!.remoteAddress.host;
      }

      loggingService = _loggingFactory.newRequestSpecificLogger(
        request.method,
        resource,
        _headerOrEmptyString(request.headers, HttpHeaders.userAgentHeader),
        uri.host,
        ip,
        traceId,
        _headerOrEmptyString(request.headers, HttpHeaders.refererHeader),
      );
    } else {
      loggingService = _loggingFactory.newBackgroundLogger();
    }

    return Services(_db, _storage, loggingService);
  }
}

class _ClientContextImpl implements ClientContext {
  _ClientContextImpl(this.services, this.applicationContext, this.traceId);

  @override
  final Services services;

  @override
  final AppEngineContext applicationContext;

  @override
  final String? traceId;

  @override
  bool get isDevelopmentEnvironment =>
      applicationContext.isDevelopmentEnvironment;

  @override
  bool get isProductionEnvironment => !isDevelopmentEnvironment;
}

String _headerOrEmptyString(HttpHeaders headers, String headerName) {
  final elements = headers[headerName];
  if (elements != null && elements.isNotEmpty) {
    return elements.first;
  }
  return '';
}
