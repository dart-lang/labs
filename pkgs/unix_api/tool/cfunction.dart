// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Types understood natively by `dart:ffi`.
final _ffigenTypes = <Pattern>[
  'void',
  'const void *',
  'int',
  'unsigned',
  'char *',
  'const char *',
  'long',
];

final _posixToFfiTypes = {
  // mode_t shall be an integer type.
  'mode_t': 'long',
  // blksize_t, pid_t, and ssize_t shall be signed integer types.
  'blksize_t': 'long',
  'pid_t': 'long',
  'ssize_t': 'long',
  // size_t shall be an unsigned integer type.
  'size_t': 'unsigned long',
  // blkcnt_t and off_t shall be signed integer types.
  'blkcnt_t': 'long',
  'off_t': 'long',
};

final _ffiToDartTypes = {
  'void': 'void',
  'void *': 'ffi.Pointer<ffi.Void>',
  'const void *': 'ffi.Pointer<ffi.Void>',
  'int': 'int',
  'int *': 'ffi.Pointer<ffi.Int>',
  'unsigned': 'int',
  'unsigned long': 'int',
  'char *': 'ffi.Pointer<ffi.Char>',
  'const char *': 'ffi.Pointer<ffi.Char>',
  'long': 'int',
};

/// A C function that validates that a Unix type (e.g. `mode_t`) is
/// representable using the given equivalent type understood by `dart:ffi`
/// (e.g. `long`).
class DomainValidator {
  final String prefix;
  final String unixType;
  String get ffiType => _posixToFfiTypes[unixType]!;
  String get name => 'valid_$unixType';

  DomainValidator(this.prefix, this.unixType);

  String get cDeclaration => 'int $prefix$name($ffiType);';

  String get cImplementation =>
      '$int $prefix$name($ffiType a) { return ($ffiType)(($unixType) a) == a; }';

  @override
  bool operator ==(Object other) {
    return other is DomainValidator && other.unixType == unixType;
  }

  @override
  int get hashCode => unixType.hashCode;
}

/// A representation of a C function.
///
/// Used to generate code that wraps an existing C function in a form that can
/// be consumed by `package:ffigen`.
class CFunction {
  final String prefix;
  final String name;
  final String unixReturnType;
  final List<String> unixArgumentTypes;
  final String? comment;
  final String? url;
  final String? errorReturn;
  final String ffiFunctionTypeParametersString;
  final String ffiFunctionNamedParametersString;
  final String dartFunctionParametersString;
  final String unixCallArgumentsWithCasts;
  final String dartFfiFunctionCallArguments;
  final bool unixReturnRangeCheckRequired;
  final String? unsupportedGuard;
  final String? parameterDomainChecks;
  final Set<DomainValidator> requiredDomainValidators;

  String get ffiReturnType => _unixToFfiType(unixReturnType);
  String get dartReturnType => _ffiToDartType(ffiReturnType);

  static String _unixToFfiType(String type) {
    for (final t in _posixToFfiTypes.entries) {
      if (t.key.matchAsPrefix(type) != null) {
        return t.value;
      }
    }
    return type;
  }

  static String _ffiToDartType(String type) {
    final dartType = _ffiToDartTypes[type];
    if (dartType == null) {
      throw ArgumentError.value(type);
    }
    return dartType;
  }

  static bool acceptableType(String type) {
    return _ffigenTypes.any(
          (ffigenType) => ffigenType.matchAsPrefix(type) != null,
        ) ||
        _posixToFfiTypes.keys.any(
          (ffigenType) => ffigenType.matchAsPrefix(type) != null,
        );
  }

  CFunction._(
    this.prefix,
    this.name,
    this.unixReturnType,
    this.unixArgumentTypes,
    this.comment,
    this.url,
    this.ffiFunctionTypeParametersString,
    this.ffiFunctionNamedParametersString,
    this.dartFunctionParametersString,
    this.unixCallArgumentsWithCasts,
    this.dartFfiFunctionCallArguments,
    this.unixReturnRangeCheckRequired,
    this.unsupportedGuard,
    this.parameterDomainChecks,
    this.requiredDomainValidators,
    this.errorReturn,
  );

  factory CFunction.fromDescription({
    required String prefix,
    required String name,
    required String unixReturnType,
    required List<String> unixArgumentTypes,
    required String description,
    required String documentationUrl,
    bool availableIOS = true,
    bool availableAndroid = true,
    String? errorReturn = null,
  }) {
    if (!acceptableType(unixReturnType)) {
      throw Exception('invalid return type $unixReturnType for $name');
    }

    for (var type in unixArgumentTypes) {
      if (!acceptableType(type)) {
        throw Exception('invalid argument type $type for $name');
      }
    }

    final ffiNamedParameterList = <String>[];
    final dartParameterList = <String>[];
    final ffiParameterList = <String>[];
    final unixFunctionCallArgumentsWithCasts = <String>[];
    final dartFfiFunctionCallArguments = <String>[];
    final typeValidations = [];
    final requiredDomainValidators = Set<DomainValidator>();
    for (var i = 0; i < unixArgumentTypes.length; ++i) {
      final unixArgumentType = unixArgumentTypes[i];
      final ffiArgumentType = _unixToFfiType(unixArgumentType);
      final dartArgumentType = _ffiToDartType(ffiArgumentType);

      if (unixArgumentType == 'void') {
        assert(i == 0);
        continue;
      }
      ffiParameterList.add(ffiArgumentType);
      ffiNamedParameterList.add('$ffiArgumentType arg$i');
      dartParameterList.add('$dartArgumentType arg$i');
      dartFfiFunctionCallArguments.add('arg$i');

      if (unixArgumentType == ffiArgumentType) {
        unixFunctionCallArgumentsWithCasts.add('arg$i');
      } else {
        final domainValidator = DomainValidator(prefix, unixArgumentType);
        requiredDomainValidators.add(domainValidator);
        unixFunctionCallArgumentsWithCasts.add('($unixArgumentType) arg$i');
        typeValidations.add('!$prefix${domainValidator.name}(arg$i)');
      }
    }
    ffiParameterList.add('int *');
    ffiNamedParameterList.add('int * err');
    dartFfiFunctionCallArguments.add('errnoPtr');

    final ffiFunctionTypeParametersString = ffiParameterList.join(', ');
    final ffiFunctionNamedParametersString = ffiNamedParameterList.join(', ');
    final dartFunctionParametersString = dartParameterList.join(', ');

    final unixCallArgumentsWithCasts =
        unixFunctionCallArgumentsWithCasts.isEmpty
        ? ''
        : unixFunctionCallArgumentsWithCasts.join(', ');

    final unsupportedGuards = [
      if (!availableIOS) 'defined(TARGET_OS_IOS)',
      if (!availableAndroid) 'defined(__ANDROID__)',
    ].join(' || ');

    final typeValidation = typeValidations.join(' && ');
    return CFunction._(
      prefix,
      name,
      unixReturnType,
      unixArgumentTypes,
      description,
      documentationUrl,
      ffiFunctionTypeParametersString,
      ffiFunctionNamedParametersString,
      dartFunctionParametersString,
      unixCallArgumentsWithCasts,
      dartFfiFunctionCallArguments.join(', '),
      unixReturnType != _unixToFfiType(unixReturnType),
      unsupportedGuards.isEmpty ? null : unsupportedGuards,
      typeValidation.isEmpty ? null : typeValidation,
      requiredDomainValidators,
      errorReturn,
    );
  }
}
