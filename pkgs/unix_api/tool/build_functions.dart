// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'cfunction.dart';
import 'package:mustache_template/mustache_template.dart';

const _cSourceTemplate = '''
// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_functions.dart`.

#include <assert.h>
#include <errno.h>

#include "functions.g.h"

''';

const _cHeaderTemplate = '''
// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_functions.dart`.

''';

const _dartTemplate = '''
// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_functions.dart`.

import 'dart:ffi' as ffi;

import 'function_bindings.g.dart';
import 'errno.dart';

''';

/// Parses a C function declaration like.
///
/// `"char * crypt(const char *, const char *)"`
/// =>
/// return = "char *"
/// name = "crypt"
/// args = ["const char *", "const char *"]
RegExp _cDeclaration = RegExp(
  r'^\s*(?<return>.+?)\s*'
  r'(?<name>\w+)'
  r'\((?<args>[^)]*)\)',
);

const dart = '''
/// {{function_description}}
/// 
/// See the [POSIX specification for `{{function_name}}`]({{function_reference_url}}).
{{dart_return_type}} {{function_name}}({{dart_parameters}}) =>
    {{function_prefix}}{{function_name}}({{dart_ffi_call_parameters}});
''';

const cDeclarationTemplate = '''
__attribute__((visibility("default"))) __attribute__((used))
{{ffi_return_type}} {{function_prefix}}{{function_name}}({{ffi_function_type_parameters}});
''';

const _cFunctionImplementationTemplate = '''
{{ffi_return_type}} {{function_prefix}}{{function_name}}({{ffi_function_named_parameters}}) {
{{#unsupported_guard}}
#if {{unsupported_guard}}
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
  {{unix_return_type}} r = {{function_name}}({{unix_call_arguments_with_casts}});
  *err = errno;
{{#parameter_range_check_required}}
  if (({{unix_return_type}})(({{ffi_return_type}}) r) != r) {
    errno = ERANGE;
    return {{error_return}};
  }  
{{/parameter_range_check_required}}
  return r;
}
''';

String renderTemplate(Template template, CFunction function) {
  return template.renderString({
    'function_name': function.name,
    'function_description': function.comment,
    'function_reference_url': function.url,
    'function_prefix': function.prefix,
    'ffi_function_type_parameters': function.ffiFunctionTypeParametersString,
    'ffi_function_named_parameters': function.ffiFunctionNamedParametersString,
    'unsupported_guard': function.unsupportedGuard,
    'parameter_domain_checks': function.parameterDomainChecks,
    'unix_return_type': function.unixReturnType,
    'ffi_return_type': function.ffiReturnType,
    'unix_call_arguments_with_casts': function.unixCallArgumentsWithCasts,
    'parameter_range_check_required': function.unixReturnRangeCheckRequired,
    'error_return': function.errorReturn,
    'dart_parameters': function.dartFunctionParametersString,
    'dart_ffi_call_parameters': function.dartFfiFunctionCallArguments,
    'dart_return_type': function.dartReturnType,
  });
}

String buildDeclaration(CFunction function) {
  return renderTemplate(Template(cDeclarationTemplate), function);
}

String buildFunction(CFunction function) {
  return renderTemplate(Template(_cFunctionImplementationTemplate), function);
}

String buildDartFunction(CFunction function) {
  return renderTemplate(Template(dart, htmlEscapeValues: false), function);
}

/// Generates Dart and C source from "functions.json"
///
/// Generates the following files based on "functions.json":
/// o src/functions.g.c
/// o src/functions.g.h
///
/// After `build_functions.dart` completes, run:
/// `dart run ffigen --config ffigen.yaml`
void main() {
  final headerToConstants =
      (json.decode(File('functions.json').readAsStringSync()) as Map)
          .cast<String, Object>();

  final cSourceBuffer = StringBuffer(_cSourceTemplate);
  final cHeaderBuffer = StringBuffer(_cHeaderTemplate);
  final dartBuffer = StringBuffer(_dartTemplate);

  final headers = headerToConstants.keys.toList()..sort();
  for (final header in headers) {
    cSourceBuffer.writeln('#include $header');
  }

  final cFunctions = <CFunction>[];
  final domainValidators = Set<DomainValidator>();
  for (final header in headers) {
    final functions = (headerToConstants[header]! as List).cast<Map>();
    for (final function in functions) {
      final match = _cDeclaration.firstMatch(function['prototype'])!;

      final returnType = match.namedGroup('return')!;
      final functionName = match.namedGroup('name')!;
      final args = match.namedGroup('args')!;
      final typeList = args.split(RegExp(r'\s*,\s*'));

      final cFunction = CFunction.fromDescription(
        prefix: 'libc_shim_',
        name: functionName,
        unixReturnType: returnType,
        unixArgumentTypes: typeList,
        description: function['comment'],
        documentationUrl: function['url'],
        availableAndroid: function['available_android'] ?? true,
        availableIOS: function['available_ios'] ?? true,
        errorReturn: function['error_value'],
      );
      domainValidators.addAll(cFunction.requiredDomainValidators);
      cFunctions.add(cFunction);
    }
  }

  for (final dv in domainValidators) {
    cHeaderBuffer.writeln(dv.cDeclaration);
    cHeaderBuffer.writeln();
    cSourceBuffer.writeln(dv.cImplementation);
    cSourceBuffer.writeln();
  }

  for (final function in cFunctions) {
    cHeaderBuffer.writeln(buildDeclaration(function));
    cHeaderBuffer.writeln();
    cSourceBuffer.writeln(buildFunction(function));
    cSourceBuffer.writeln();
    dartBuffer.writeln(buildDartFunction(function));
  }

  File('src/functions.g.c').writeAsStringSync(cSourceBuffer.toString());
  File('src/functions.g.h').writeAsStringSync(cHeaderBuffer.toString());
  File('lib/src/functions.g.dart').writeAsStringSync(dartBuffer.toString());
}
