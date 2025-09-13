final ffigenTypes = <Pattern>[
  'void',
  'int',
  'unsigned',
  'char *',
  'const char *',
  'long',
];

final parameterNames = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

class CFunction {
  final String name;
  final String returnType;
  final List<String> argumentTypes;
  final String? comment;
  final String? url;

  List<String> get dartArgumentTypes => argumentTypes;
  String get dartReturnType => returnType;

  bool acceptableType(String type) {
    return ffigenTypes.any(
      (ffigenType) => ffigenType.matchAsPrefix(type) != null,
    );
  }

  CFunction(
    this.name,
    this.returnType,
    this.argumentTypes,
    this.comment,
    this.url,
  ) {
    if (!acceptableType(returnType)) {
      throw Exception('invalid return type $returnType for $name');
    }

    for (var type in argumentTypes) {
      if (!acceptableType(type)) {
        throw Exception('invalid argument type $type for $name');
      }
    }
  }

  String dartDeclaration(String prefix) {
    final declaration =
        '''__attribute__((visibility("default"))) __attribute__((used))
$dartReturnType $prefix$name(${dartArgumentTypes.join(", ")});
''';

    if (comment != null) {
      return '''/// ${comment}
///
/// Read the [specification](${url}). 
/// $declaration''';
    }
    return declaration;
  }

  String trampoline(String prefix) {
    final parameters = <String>[];

    if (dartArgumentTypes.length != 1 || dartArgumentTypes[0] != 'void') {
      for (var i = 0; i < dartArgumentTypes.length; ++i) {
        parameters.add('${dartArgumentTypes[i]} ${parameterNames[i]}');
      }
    }

    String parameterList = parameters.isEmpty ? 'void' : parameters.join(", ");
    return '''$dartReturnType $prefix$name($parameterList) {
  return $name(${[for (var i = 0; i < parameters.length; ++i) parameterNames[i]].join(', ')});
}''';
  }
}
