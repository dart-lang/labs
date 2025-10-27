// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../api.dart';
import '../workspace.dart';
import 'markdown.dart';
import 'render.dart';
import 'utils.dart';

class LLMSummary {
  final Workspace workspace;
  final Directory outDir;
  final Logger logger;
  final Stats? stats;

  LLMSummary({
    required this.workspace,
    required this.outDir,
    required this.logger,
    this.stats,
  });

  void generate() {
    final api = workspace.api;
    final packages = api.packages;

    final wroteFiles = <String>{};

    if (packages.length == 1) {
      final wrote = _generatePackage(packages.first, outDir);
      wroteFiles.addAll(wrote.map((file) => file.absolute.path));
    } else {
      for (var package in packages) {
        final packageDir = Directory(p.join(outDir.path, package.name));
        final wrote = _generatePackage(packages.first, packageDir);
        wroteFiles.addAll(wrote.map((file) => file.absolute.path));
      }
    }
  }

  Set<File> _generatePackage(Package package, Directory dir) {
    final out = StringBuffer();
    out.writeln('# Package: ${package.name}');
    out.writeln();

    if (package.description != null) {
      out.writeln(package.description!.trimRight());
    }

    out.writeln();
    out.writeln('## Libraries');
    out.writeln();

    final wroteFiles = <File>{};

    // TODO: Disambiguate this from any 'index' library in the package.
    final indexFile = File(p.join(dir.path, 'index.md'));
    logger.stdout('  ${p.relative(indexFile.path)}');

    for (var library in package.libraries) {
      final filePath =
          '${p.withoutExtension(library.name).replaceAll(':', '_')}.md';
      final docs = library.hasDocs ? firstSentence(library.docs!) : null;
      out.writeln(_listWrapped('[${library.name}]($filePath)', docs));
      final file = File(p.join(dir.path, filePath));

      file.parent.createSync(recursive: true);

      final output = generateForLibrary(library);
      file.writeAsStringSync(output);
      wroteFiles.add(file);

      logger.stdout('  ${p.relative(file.path)}');
    }

    // Emit the index file.
    indexFile.writeAsStringSync(out.toString());
    wroteFiles.add(indexFile);

    return wroteFiles;
  }

  @visibleForTesting
  String generateForLibrary(LibraryItemContainer library) {
    final out = StringBuffer();
    out.writeln('# Library: ${library.name}');
    out.writeln();

    // TODO: we should do some escaping here
    if (library.docs != null) {
      out.writeln(library.docs);
      out.writeln();
    }

    out.writeln('## Members');
    out.writeln();

    final renderer = SignatureRenderer();

    // members
    final members = library.allChildren
        .where((item) => item is! Items)
        .toList();
    // normalize order
    members.sort(compareByNaturalOrdering);

    if (members.isNotEmpty) {
      for (var member in members) {
        final docs = member.hasDocs ? firstSentence(member.docs!) : null;
        out.writeln(
          _listWrapped(
            '${member.type.displayName} `${renderer.renderItem(member)}`',
            docs,
          ),
        );
      }
      out.writeln();
    }

    // classes
    final classes = library.allChildren.whereType<Items>().toList();
    final classesByGroup = Items.itemsByGroup(classes);
    final classGroups = classesByGroup.keys.toList()..sort();

    for (final groupType in classGroups) {
      for (var clazz
          in classesByGroup[groupType]!.cast<Items>().toList()
            ..sort(compareByName)) {
        out.writeln('## ${titleCase(groupType.displayName)}: ${clazz.name}');
        if (clazz.hasDocs) {
          out.writeln();
          out.writeln(firstSentence(clazz.docs!));
        }
        out.writeln();
        out.writeln(renderer.renderItem(clazz));
        out.writeln();

        // members
        final members = clazz.allChildren.toList();
        // normalize order
        members.sort(compareByNaturalOrdering);
        if (members.isNotEmpty) {
          for (var member in members) {
            final modifiers =
                member.isStatic && member.type != GroupType.enumValue
                ? 'static '
                : '';
            final docs = member.hasDocs ? firstSentence(member.docs!) : null;
            out.writeln(
              _listWrapped('$modifiers`${renderer.renderItem(member)}`', docs),
            );
          }
          out.writeln();
        }
      }
    }

    return '${out.toString().trimRight()}\n';
  }
}

class SignatureRenderer extends Renderer {
  final StringBuffer buf = StringBuffer();

  @override
  String handleConstructor(Item item) {
    var element = item.asConstructor;
    _write(element.displayName);
    _writeFormalParameters(element.parameters, forElement: true);
    return _finish();
  }

  @override
  String handleEnumValue(Item item) {
    _write(item.name);
    return _finish();
  }

  @override
  String handleField(Item item) {
    final element = item.asField;
    _writeType(element.type);
    _write(' ');
    _write(element.displayName);
    return _finish();
  }

  @override
  String handleAccessor(Item item) {
    final element = item.asAccessor;
    if (element.isGetter) {
      _writeType(element.returnType);
      _write(' ');
    }
    _write(element.isGetter ? 'get ' : 'set ');
    _write(element.name);
    if (element.isSetter) {
      _writeFormalParameters(element.parameters, forElement: true);
    }
    return _finish();
  }

  @override
  String handleMethod(Item item) {
    var element = item.asMethod;
    _writeType(element.returnType);
    _write(' ');
    if (element.isOperator) {
      _write('operator');
    }
    _write(element.name);
    _writeTypeParameters(element.typeParameters);
    _writeFormalParameters(element.parameters, forElement: true);
    return _finish();
  }

  @override
  String handleTopLevelVariable(Item item) {
    final element = item.asTopLevelVariableElement;
    _writeType(element.type);
    _write(' ');
    _write(element.displayName);
    return _finish();
  }

  @override
  String handleFunction(Item item) {
    var element = item.asFunction;
    _writeType(element.returnType);
    _write(' ');
    _write(element.displayName);
    _writeTypeParameters(element.typeParameters);
    _writeFormalParameters(element.parameters, forElement: true);
    return _finish();
  }

  @override
  String handleFunctionTypeAlias(Item item) {
    var element = item.asTypeAlias;
    _write('typedef ');
    _write(element.displayName);
    _writeTypeParameters(element.typeParameters);
    _write(' = ');
    var aliasedElement = element.aliasedElement;
    if (aliasedElement != null) {
      _writeType(element.aliasedType);
    } else {
      _writeType(element.aliasedType);
    }
    return _finish();
  }

  @override
  String handleTypeAlias(Item item) {
    final element = item.asTypeAlias;
    _write('typedef ');
    _write(element.displayName);
    _writeTypeParameters(element.typeParameters);
    _write(' = ');
    var aliasedElement = element.aliasedElement;
    if (aliasedElement != null) {
      _writeType(element.aliasedType);
    } else {
      _writeType(element.aliasedType);
    }
    return _finish();
  }

  @override
  String handleMixin(Item item) {
    final element = item.asMixin;
    if (element.isBase) _write('base ');
    _write('mixin ');
    _write(element.displayName);
    _writeTypeParameters(element.typeParameters);
    _writeTypesIfNotEmpty('\non ', element.superclassConstraints);
    _writeTypesIfNotEmpty('\nimplements ', element.interfaces);
    _write(' { … }');
    return '```dart\n${_finish()}\n```';
  }

  @override
  String handleClass(Item item) {
    final element = item.asClass;
    if (element.isSealed) {
      _write('sealed ');
    } else if (element.isAbstract) {
      _write('abstract ');
    }
    if (element.isBase && element.isMixinClass) {
      _write('base ');
    } else if (element.isInterface) {
      _write('interface ');
    } else if (element.isFinal) {
      _write('final ');
    }
    if (element.isMixinClass) _write('mixin ');
    _write('class ');
    _write(element.displayName);
    _writeTypeParameters(element.typeParameters);
    _writeTypeIfNotObject('\nextends ', element.supertype);
    _writeTypesIfNotEmpty('\nwith ', element.mixins);
    _writeTypesIfNotEmpty('\nimplements ', element.interfaces);
    _write(' { … }');
    return '```dart\n${_finish()}\n```';
  }

  @override
  String handleEnum(Item item) {
    final element = item.asEnum;
    _write('enum ');
    _write(element.displayName);
    _writeTypeParameters(element.typeParameters);
    _writeTypesIfNotEmpty('\nwith ', element.mixins);
    _writeTypesIfNotEmpty('\nimplements ', element.interfaces);
    _write(' { … }');
    return '```dart\n${_finish()}\n```';
  }

  @override
  String handleExtension(Item item) {
    final element = item.asExtension;
    _write('extension ');
    _write(element.displayName);
    _writeTypeParameters(element.typeParameters);
    _write(' on ');
    _writeType(element.extendedType);
    _write(' { … }');
    return '```dart\n${_finish()}\n```';
  }

  void _write(String str) => buf.write(str);

  String _finish() {
    var result = buf.toString();
    buf.clear();

    // handle newlines
    if (result.contains('\n')) {
      if (result.length <= 80) {
        result = result.replaceAll('\n', ' ');
      } else {
        result = result.replaceAll('\n', '\n    ');
      }
    }

    return result;
  }

  void _writeType(DartType type) {
    _write(type.getDisplayString(withNullability: true));
  }

  void _writeTypes(List<DartType> types) {
    for (var i = 0; i < types.length; i++) {
      if (i != 0) {
        _write(', ');
      }
      _writeType(types[i]);
    }
  }

  void _writeTypeIfNotObject(String prefix, DartType? type) {
    if (type != null && !type.isDartCoreObject) {
      _write(prefix);
      _writeType(type);
    }
  }

  void _writeTypesIfNotEmpty(String prefix, List<DartType> types) {
    if (types.isNotEmpty) {
      _write(prefix);
      _writeTypes(types);
    }
  }

  void writeTypeParameter(TypeParameterElement element) {
    _write(element.displayName);

    var bound = element.bound;
    if (bound != null) {
      _write(' extends ');
      _writeType(bound);
    }
  }

  void _writeTypeParameters(List<TypeParameterElement> elements) {
    if (elements.isEmpty) return;

    _write('<');
    for (var i = 0; i < elements.length; i++) {
      if (i != 0) _write(', ');
      writeTypeParameter(elements[i]);
    }
    _write('>');
  }

  void _writeFormalParameters(
    List<ParameterElement> parameters, {
    required bool forElement,
  }) {
    _write('(');

    _WriteFormalParameterKind? lastKind;
    var lastClose = '';

    void openGroup(_WriteFormalParameterKind kind, String open, String close) {
      if (lastKind != kind) {
        _write(lastClose);
        _write(open);
        lastKind = kind;
        lastClose = close;
      }
    }

    for (var i = 0; i < parameters.length; i++) {
      if (i != 0) _write(', ');

      var parameter = parameters[i];
      if (parameter.isRequiredPositional) {
        openGroup(_WriteFormalParameterKind.requiredPositional, '', '');
      } else if (parameter.isOptionalPositional) {
        openGroup(_WriteFormalParameterKind.optionalPositional, '[', ']');
      } else if (parameter.isNamed) {
        openGroup(_WriteFormalParameterKind.named, '{', '}');
      }
      _writeWithoutDelimiters(parameter, forElement: forElement);
    }

    _write(lastClose);
    _write(')');
  }

  void _writeWithoutDelimiters(
    ParameterElement element, {
    required bool forElement,
  }) {
    if (element.isRequiredNamed) {
      _write('required ');
    }
    _writeType(element.type);
    if (forElement || element.isNamed) {
      _write(' ');
      _write(element.displayName);
    }
  }
}

enum _WriteFormalParameterKind { requiredPositional, optionalPositional, named }

int compareByName(Item a, Item b) {
  return a.name.compareTo(b.name);
}

int compareByNaturalOrdering(Item a, Item b) {
  int compareCtor(Item a, Item b) {
    final valA = a.element is ConstructorElement ? true : false;
    final valB = b.element is ConstructorElement ? true : false;

    return valA == valB ? 0 : (valA ? -1 : 1);
  }

  int compareStatic(Item a, Item b) {
    final valA = a.element is ClassMemberElement
        ? (a.element as ClassMemberElement).isStatic
        : false;
    final valB = b.element is ClassMemberElement
        ? (b.element as ClassMemberElement).isStatic
        : false;

    return valA == valB ? 0 : (valA ? -1 : 1);
  }

  // ctors first
  var compare = compareCtor(a, b);
  if (compare != 0) return compare;

  // anything static
  compare = compareStatic(a, b);
  if (compare != 0) return compare;

  // types
  compare = a.type.compareTo(b.type);
  if (compare != 0) return compare;

  // lexially by name
  return a.name.compareTo(b.name);
}

/// Return a markdown list item, roughly wrapped at 80 cols.
String _listWrapped(String item, String? docs) {
  // Decide if we need to wrap, and when wrapping, make sure we indent
  // appropriately.
  var result = '- $item';
  if (docs != null) {
    final lines = docs.split('\n');
    final first = lines.first;
    if (first.length + item.length > 78) {
      result = '$result:\n  ';
    } else {
      result = '$result: ';
    }
    result = '$result${lines.join('\n  ')}';
  }
  return result;
}
