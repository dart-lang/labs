// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';

import '../api.dart';
import '../workspace.dart';
import 'display.dart';
import 'formatting.dart';
import 'utils.dart';

abstract class Renderer {
  String render(GroupType type, Item item) {
    switch (type) {
      case GroupType.constructor:
        return handleConstructor(item);
      case GroupType.enumValue:
        return handleEnumValue(item);
      case GroupType.field:
        return handleField(item);
      case GroupType.accessor:
        return handleAccessor(item);
      case GroupType.method:
        return handleMethod(item);

      case GroupType.topLevelVariable:
        return handleTopLevelVariable(item);
      case GroupType.function:
        return handleFunction(item);
      case GroupType.functionTypeAlias:
        return handleFunctionTypeAlias(item);
      case GroupType.typeAlias:
        return handleTypeAlias(item);
      case GroupType.$enum:
        return handleEnum(item);
      case GroupType.$mixin:
        return handleMixin(item);
      case GroupType.$class:
        return handleClass(item);
      case GroupType.$extension:
        return handleExtension(item);
      case GroupType.$extensionType:
        return handleExtensionType(item);

      // unexpected values
      case GroupType.skip:
      case GroupType.other:
        throw StateError('unexpected item: $item');
    }
  }

  String renderItem(Item item) => render(item.type, item);

  String handleConstructor(Item item) => handleDefault(item);
  String handleEnumValue(Item item) => handleDefault(item);
  String handleField(Item item) => handleDefault(item);
  String handleAccessor(Item item) => handleDefault(item);
  String handleMethod(Item item) => handleDefault(item);

  String handleTopLevelVariable(Item item) => handleDefault(item);
  String handleFunction(Item item) => handleDefault(item);
  String handleFunctionTypeAlias(Item item) => handleDefault(item);
  String handleTypeAlias(Item item) => handleDefault(item);
  String handleMixin(Item item) => handleDefault(item);
  String handleClass(Item item) => handleDefault(item);
  String handleEnum(Item item) => handleDefault(item);
  String handleExtension(Item item) => handleDefault(item);
  String handleExtensionType(Item item) => handleDefault(item);

  String handleDefault(Item item) => item.name;
}

class OutlineRenderer extends Renderer {
  @override
  String handleConstructor(Item item) {
    var element = item.asConstructor;
    var arity = element.parameters.isEmpty ? '' : '…';
    return '${element.displayName}($arity)';
  }

  @override
  String handleAccessor(Item item) {
    var prefix = (item.element as PropertyAccessorElement).isGetter
        ? 'get'
        : 'set';
    return '$prefix\u00A0${item.name}';
  }

  @override
  String handleMethod(Item item) {
    var element = item.asMethod;
    if (element.isOperator) {
      return item.name;
    } else {
      var arity = element.parameters.isEmpty ? '' : '…';
      return '${item.name}($arity)';
    }
  }

  @override
  String handleFunction(Item item) {
    var element = item.asFunction;
    var arity = element.parameters.isEmpty ? '' : '…';
    return '${item.name}($arity)';
  }
}

String writeAnnotations(Item item) {
  var annotations = item.annotations;
  if (annotations.isEmpty) return '';

  var buf = StringBuffer('<p class="annotations-container">\n');
  for (var annotation in annotations) {
    var text = annotation.toSource();
    buf.writeln(
      '<span class="badge badge--secondary">'
      '${htmlEscape(text)}</span>',
    );
  }

  buf.writeln('</p>');
  return buf.toString();
}

class LinkedCodeRenderer extends Renderer {
  final Resolver resolver;
  final WorkspaceFile fromFile;

  LinkedCodeRenderer(this.resolver, this.fromFile);

  @override
  String handleConstructor(Item item) {
    var element = item.asConstructor;

    var text = LinkedText(resolver, fromFile);
    var builder = ElementDisplayStringBuilder(text);
    builder.writeConstructorElement(element);
    return text.emitHtml(
      (text) => DartFormat.asConstructor(
        text,
        className: element.enclosingElement.name,
        isConst: !element.isFactory && element.isConst,
      ),
    );
  }

  @override
  String handleField(Item item) {
    var element = item.asField;

    var text = LinkedText(resolver, fromFile);
    var builder = ElementDisplayStringBuilder(text);
    builder.writeVariableElement(element);
    return text.emitHtml(DartFormat.asField);
  }

  @override
  String handleAccessor(Item item) {
    var element = item.asAccessor;

    var text = LinkedText(resolver, fromFile);
    var builder = ElementDisplayStringBuilder(text);
    builder.writeExecutableElement(element, element.displayName);
    return text.emitHtml(DartFormat.asMethod);
  }

  @override
  String handleMethod(Item item) {
    var element = item.asMethod;

    var text = LinkedText(resolver, fromFile);
    var builder = ElementDisplayStringBuilder(text);
    builder.writeExecutableElement(
      element,
      element.isOperator ? element.displayName : element.name,
    );
    return text.emitHtml(DartFormat.asMethod);
  }

  @override
  String handleFunction(Item item) {
    var element = item.asFunction;

    var text = LinkedText(resolver, fromFile);
    var builder = ElementDisplayStringBuilder(text);
    builder.writeExecutableElement(element, element.name);
    return text.emitHtml(DartFormat.asFunction);
  }

  @override
  String handleFunctionTypeAlias(Item item) {
    var element = item.asTypeAlias;

    var text = LinkedText(resolver, fromFile);
    var builder = ElementDisplayStringBuilder(text);
    builder.writeTypeAliasElement(element as TypeAliasElementImpl);
    return text.emitHtml(DartFormat.asTypeAlias);
  }

  @override
  String handleTypeAlias(Item item) {
    var element = item.asTypeAlias;

    var text = LinkedText(resolver, fromFile);
    var builder = ElementDisplayStringBuilder(text);
    builder.writeTypeAliasElement(element as TypeAliasElementImpl);
    return text.emitHtml(DartFormat.asTypeAlias);
  }

  @override
  String handleClass(Item item) {
    var element = item.asClass;

    var text = LinkedText(resolver, fromFile);

    var builder = ElementDisplayStringBuilder(text);

    builder.writeClassElement(element as ClassElementImpl);

    // // todo: replicate this but call out to LinkedText
    // //text.write(element.getDisplayString(withNullability: true));
    // // "class DocWorkspace extends DocContainer"
    // text.write('class ');
    // // todo: note that we don't need to link to ourself
    // text.writeElement(element.name, element);
    // var $super = element.supertype?.element;
    // if ($super != null) {
    //   text.write(' extends ');
    //   text.writeElement($super.name, $super);
    // }

    return text.emitHtml(DartFormat.asClass, ' { … }');
  }

  @override
  String handleMixin(Item item) {
    var element = item.asMixin;

    var text = LinkedText(resolver, fromFile);
    var builder = ElementDisplayStringBuilder(text);
    builder.writeMixinElement(element as MixinElementImpl);
    return text.emitHtml(DartFormat.asClass, ' { … }');
  }

  @override
  String handleEnum(Item item) {
    var element = item.asEnum;

    var text = LinkedText(resolver, fromFile);
    var builder = ElementDisplayStringBuilder(text);
    builder.writeEnumElement(element);
    return text.emitHtml(DartFormat.asEnum, ' { … }');
  }

  @override
  String handleExtension(Item item) {
    var element = item.asExtension;

    var text = LinkedText(resolver, fromFile);
    var builder = ElementDisplayStringBuilder(text);
    builder.writeExtensionElement(element);
    return text.emitHtml(DartFormat.asClass, ' { … }');
  }

  @override
  String handleExtensionType(Item item) {
    var element = item.asExtensionType;

    var text = LinkedText(resolver, fromFile);
    var builder = ElementDisplayStringBuilder(text);
    builder.writeExtensionTypeElement(element);
    return text.emitHtml(DartFormat.asClass, ' { … }');
  }

  @override
  String handleDefault(Item item) {
    throw StateError('${item.type} not yet handled from LinkedCodeRenderer');
  }
}
