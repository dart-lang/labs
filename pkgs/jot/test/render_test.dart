// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:jot/api.dart';
import 'package:jot/src/render.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('LinkedCodeRenderer', () {
    testWithSource(
      'handleConstructor',
      '''
class A {
  A();
}
''',
      (TestProject project) {
        final interfaceItem = project.classNamed('A');
        final item = interfaceItem.allChildren.firstWhere(
          (item) => item.element is ConstructorElement,
        );
        final renderer = project.rendererFor(item);
        final result = renderer.render(GroupType.typeFor(item.element), item);

        expect(result, '<pre class="declaration"><code>A()</code></pre>');
      },
    );

    testWithSource(
      'handleField',
      '''
class A {
  final String foo = 'bar';
}
''',
      (TestProject project) {
        final interfaceItem = project.classNamed('A');
        final item = interfaceItem.allChildren.firstWhere(
          (item) => item.element is FieldElement,
        );
        final renderer = project.rendererFor(item);
        final result = renderer.render(GroupType.typeFor(item.element), item);

        expect(
          result,
          '<pre class="declaration"><code>String foo</code></pre>',
        );
      },
    );

    testWithSource(
      'handleAccessor',
      '''
String get foo => 'bar';
''',
      (TestProject project) {
        final library = project.firstLibrary;
        final item = library.allChildren.firstWhere(
          (item) => item.element is PropertyAccessorElement,
        );
        final renderer = LinkedCodeRenderer(
          project.resolver,
          project.resolver.fileFor(library.element)!,
        );
        final result = renderer.render(GroupType.typeFor(item.element), item);

        expect(
          result,
          '<pre class="declaration"><code>String get foo</code></pre>',
        );
      },
    );

    testWithSource(
      'handleMethod',
      '''
class A {
  String foo() => 'bar';
}
''',
      (TestProject project) {
        final interfaceItem = project.classNamed('A');
        final item = interfaceItem.allChildren.firstWhere(
          (item) => item.element is MethodElement,
        );
        final renderer = project.rendererFor(item);
        final result = renderer.render(GroupType.typeFor(item.element), item);

        expect(
          result,
          '<pre class="declaration"><code>String foo()</code></pre>',
        );
      },
    );

    testWithSource(
      'handleFunction',
      r'''
String foo(Object param1) => 'bar: $param1';
''',
      (TestProject project) {
        final item = project.firstLibrary.allChildren.firstWhere(
          (item) => item.element is FunctionElement,
        );
        final renderer = project.rendererFor(item);
        final result = renderer.render(GroupType.typeFor(item.element), item);

        expect(
          result,
          '<pre class="declaration"><code>String foo(Object param1)</code></pre>',
        );
      },
    );

    testWithSource(
      'handleTypeAlias',
      r'''
typedef ListMapper<X> = Map<X, List<X>>;

typedef Compare<T> = int Function(T a, T b);
''',
      (TestProject project) {
        var item = project.itemNamed('ListMapper');
        final renderer = project.rendererFor(item);
        var result = renderer.render(GroupType.typeFor(item.element), item);

        expect(
          result,
          '<pre class="declaration">'
          '<code>typedef ListMapper&lt;X&gt; = Map&lt;X, List&lt;X&gt;&gt;</code>'
          '</pre>',
        );

        item = project.itemNamed('Compare');
        result = renderer.render(GroupType.typeFor(item.element), item);

        expect(
          result,
          '<pre class="declaration">'
          '<code>typedef Compare&lt;T&gt; = int Function(T, T)</code>'
          '</pre>',
        );
      },
    );

    testWithSource(
      'handleMixin',
      '''
class Musician { }

mixin MusicalPerformer on Musician { }
''',
      (TestProject project) {
        final interfaceItem = project.classNamed('MusicalPerformer');
        final renderer = project.rendererFor(interfaceItem);
        final result = renderer.render(
          GroupType.typeFor(interfaceItem.element),
          interfaceItem,
        );

        expect(
          result,
          '<pre class="declaration">'
          '<code>mixin MusicalPerformer on <a href="Musician.html">Musician</a> { … }</code>'
          '</pre>',
        );
      },
    );

    testWithSource(
      'handleClass',
      '''
class A extends B {
  final String foo = 'bar';
}
class B { }
''',
      (TestProject project) {
        final interfaceItem = project.classNamed('A');
        final renderer = project.rendererFor(interfaceItem);
        final result = renderer.render(
          GroupType.typeFor(interfaceItem.element),
          interfaceItem,
        );

        expect(
          result,
          '<pre class="declaration">'
          '<code>class A extends <a href="B.html">B</a> { … }</code>'
          '</pre>',
        );
      },
    );

    testWithSource(
      'handleEnum',
      '''
enum Animals  {
  cat,
  dog;
}
''',
      (TestProject project) {
        final item = project.firstInterfaceItem;

        final renderer = LinkedCodeRenderer(
          project.resolver,
          project.resolver.fileFor(item.element)!,
        );
        final result = renderer.render(GroupType.$enum, item);

        expect(
          result,
          '<pre class="declaration"><code>enum Animals { … }</code></pre>',
        );
      },
    );

    testWithSource(
      'handleExtension',
      '''
extension NumberParsing on String {
  int parseInt() => int.parse(this);
}
''',
      (TestProject project) {
        final item = project.firstItem as Items;
        final renderer = project.rendererFor(item);
        final result = renderer.render(GroupType.typeFor(item.element), item);

        expect(
          result,
          '<pre class="declaration">'
          '<code>extension NumberParsing on String { … }</code>'
          '</pre>',
        );
      },
    );

    testWithSource(
      'handleExtensionType',
      '''
abstract class JSObjectRepType {}

extension type JSAny._(Object _jsAny) implements Object {}

extension type JSObject._(JSObjectRepType _jsObject) implements JSAny {
  JSObject.fromInteropObject(Object interopObject)
      : _jsObject = interopObject as JSObjectRepType;
}
''',
      (TestProject project) {
        final extensionTypeNamedJSAny = project.extensionTypeNamed('JSAny');
        final renderer = project.rendererFor(extensionTypeNamedJSAny);
        var result = renderer.render(
          GroupType.$extensionType,
          extensionTypeNamedJSAny,
        );

        expect(
          result,
          '<pre class="declaration">'
          '<code>extension type JSAny._(Object _jsAny) implements Object { … }</code>'
          '</pre>',
        );

        final extensionTypeNamedJSObject = project.extensionTypeNamed(
          'JSObject',
        );
        result = renderer.render(
          GroupType.$extensionType,
          extensionTypeNamedJSObject,
        );

        expect(
          result,
          '<pre class="declaration">'
          '<code>extension type JSObject._(<a href="JSObjectRepType.html">JSObjectRepType</a> _jsObject) '
          'implements <a href="JSAny.html">JSAny</a> { … }</code>'
          '</pre>',
        );
      },
    );
  });
}
