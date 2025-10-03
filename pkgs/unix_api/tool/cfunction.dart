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

final _foo = {
  // mode_t shall be an integer type.
  'mode_t': 'long',
  // blksize_t, pid_t, and ssize_t shall be signed integer types.
  'blksize_t': 'long',
  'pid_t': 'long',
  'ssize_t': 'long',
  // size_t shall be an unsigned integer type.
  'size_t': 'unsigned long',
};

final x = '''
int64 as_mode_t(int64);

bool valid_mode_t(int64 a) {
  return (int64)((mode_t) a) == a;
}

int open(const char * a, int64 b) {
}
''';

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

  String _actualToDartType(String type) {
    for (final t in _foo.entries) {
      if (t.key.matchAsPrefix(type) != null) {
        return t.value;
      }
    }
    return type;
  }

  List<String> get dartArgumentTypes =>
      argumentTypes.map(_actualToDartType).toList();
  String get dartReturnType => _actualToDartType(returnType);

  bool acceptableType(String type) {
    return _ffigenTypes.any(
          (ffigenType) => ffigenType.matchAsPrefix(type) != null,
        ) ||
        _foo.keys.any((ffigenType) => ffigenType.matchAsPrefix(type) != null);
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

    final firstLine = '$dartReturnType $prefix$name($parameters) {';

    final params = [];
    final typeValidations = [];
    for (var i = 0; i < dartArgumentTypes.length; ++i) {
      final dartType = dartArgumentTypes[i];
      final argType = argumentTypes[i];

      if (dartType == argType) {
        params.add('arg$i');
      } else {
        params.add('($argType) arg$i');
        typeValidations.add('(($dartType)(($argType) arg$i) != arg$i)');
      }
    }
    final String typeValidation;
    if (typeValidations.isNotEmpty) {
      typeValidation =
          '''if ${typeValidations.join(' || ')} {
      errno = EDOM;
      return $unavailableReturn;
      }''';
    } else {
      typeValidation = '';
    }
    String callParameters = params.join(', ');

    final String trampolineCall;
    if (returnType == dartReturnType) {
      trampolineCall = "return $name($callParameters);";
    } else {
      if (unavailableReturn == null) {
        throw Exception('required for $name');
      }
      trampolineCall =
          '''$returnType r = $name($callParameters);
    if (($returnType)(($dartReturnType) r) != r) {
      errno = ERANGE;
      return $unavailableReturn;
    }
    return r;
    ''';
    }

    final implementationGuard = _platform_restriction_ifdef();

    if (implementationGuard.isEmpty) {
      return '''$firstLine
  $typeValidation
  $trampolineCall
}''';
    } else {
      return '''$firstLine
#if $implementationGuard
  errno = ENOSYS;
  ${unavailableReturn != null ? "return $unavailableReturn;" : ""}
#else
  $typeValidation
  $trampolineCall
#endif
}''';
    }
  }
}

const dart = '''
{{dart_type}} {{function_name}}({{dart_parameters}}) {
  
}
''';

const cDeclarationTemplate = '''
__attribute__((visibility("default"))) __attribute__((used))
{{ffi_return_type}} {{function_prefix}}{{function_name}}({{parameters}});
''';

const cBodyTemplate = '''
{{ffi_return_type}} {{function_prefix}}{{function_name}}({{parameters}}) {
{{#unsupported_guard}}
#ifdef {{unsupported_guard}}
  *err = ENOSYS;
  return {{error_return}};
#endif
{{/unsupported_guard}}
{{#parameter_domain_checks}}
  if ({{parameter_domain_checks}}) {
    *err = EDOM;
    return {{error_return}};
  }
{{/parameter_domain_checks}}
  errno = *err;
  {{unix_return_type}} r = {{function_name}}({{arguments}});
  *err = errno;
{{#parameter_range_check}}
  if ({{unix_return_type}}(({{ffi_return_type}}) r) != r) {
    errno = ERANGE;
    return {{error_return}}
  }  
{{/parameter_range_check}}
  return r;
}
''';
