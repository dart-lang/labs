// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Types understood natively by `dart:ffi`.
final _ffigenTypes = <Pattern>[
  'void',
  'int',
  'unsigned',
  'char *',
  'const char *',
  'long',
];

/// A representation of a C function.
///
/// Used to generate code that wraps an existing C function in a form that can
/// be consumed by `package:ffigen`.
class CFunction {
  final String name;
  final String returnType;
  final List<String> argumentTypes;
  final String? comment;
  final String? url;
  final bool availableIOS;
  final bool availableAndroid;
  final String? unavailableReturn;

  List<String> get dartArgumentTypes => argumentTypes;
  String get dartReturnType => returnType;

  bool acceptableType(String type) {
    return _ffigenTypes.any(
      (ffigenType) => ffigenType.matchAsPrefix(type) != null,
    );
  }

  CFunction(
    this.name,
    this.returnType,
    this.argumentTypes,
    this.comment,
    this.url, {
    this.availableIOS = true,
    this.availableAndroid = true,
    this.unavailableReturn,
  }) {
    if (!acceptableType(returnType)) {
      throw Exception('invalid return type $returnType for $name');
    }

    for (var type in argumentTypes) {
      if (!acceptableType(type)) {
        throw Exception('invalid argument type $type for $name');
      }
    }
  }

  /// Generate a declaration that can be consumed by `package:ffigen`.
  String dartDeclaration(String prefix) {
    final declaration =
        '''__attribute__((visibility("default"))) __attribute__((used))
$dartReturnType $prefix$name(${dartArgumentTypes.join(", ")});
''';

    if (comment != null) {
      return '''/// ${comment}
///
/// Read the [specification](${url}). 
$declaration''';
    }
    return declaration;
  }

  String _platform_restriction_ifdef() {
    return [
      if (!availableIOS) 'defined(TARGET_OS_IOS)',
      if (!availableAndroid) 'defined(__ANDROID__)',
    ].join(' || ');
  }

  /// Generate a call to the wrapped function.
  String trampoline(String prefix) {
    final parametersList = <String>[];

    if (dartArgumentTypes.length != 1 || dartArgumentTypes[0] != 'void') {
      for (var i = 0; i < dartArgumentTypes.length; ++i) {
        parametersList.add('${dartArgumentTypes[i]} arg$i');
      }
    }

    String parameters = parametersList.isEmpty
        ? 'void'
        : parametersList.join(", ");
    String callParameters = [
      for (var i = 0; i < parametersList.length; ++i) 'arg$i',
    ].join(', ');

    final firstLine = '$dartReturnType $prefix$name($parameters) {';
    final trampolineCall = 'return $name($callParameters);';
    final implementationGuard = _platform_restriction_ifdef();

    if (implementationGuard.isEmpty) {
      return '''$firstLine
  $trampolineCall
}''';
    } else {
      return '''$firstLine
#if $implementationGuard
  errno = ENOSYS;
  ${unavailableReturn != null ? "return $unavailableReturn;" : ""}
#else
  $trampolineCall
#endif
}''';
    }
  }
}
