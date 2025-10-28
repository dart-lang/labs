// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:path/path.dart' as p;

import 'src/index.dart';
import 'src/markdown.dart';
import 'src/utils.dart';
import 'workspace.dart';

class Api {
  final List<Package> packages = [];
  final Resolver resolver = Resolver();
  final Map<Element, Item> elementItemMap = {};

  late final Index index;

  Api();

  LibraryItemContainer addLibrary(
    LibraryElement element,
    String packageName,
    String libraryPath,
  ) {
    var package = packages.firstWhere(
      (p) => p.name == packageName,
      orElse: () {
        var package = Package(packageName);
        packages.add(package);
        return package;
      },
    );

    var library = LibraryItemContainer(package, element, libraryPath);
    package.libraries.add(library);
    return library;
  }

  void finish() {
    // populate the element item map
    for (var package in packages) {
      for (var library in package.libraries) {
        _buildElementItemMap(library);
      }
    }

    // handle situations where elements are exported from multiple libraries
    _processDuplicates();

    // perform calculations; super, children, ...
    elementItemMap.values.forEach(_calculateFor);

    index = Index();

    for (var package in packages) {
      var packageIndex = index.add(package.name, 'package');

      for (var library in package.libraries) {
        var libraryIndex = packageIndex.add(
          library.name,
          'library',
          ref: resolve(library.element),
          docs: docSummary(library),
        );

        for (var child in library.allChildrenSorted) {
          if (child is Items) {
            var childIndex = libraryIndex.add(
              child.name,
              child.type.displayName,
              ref: resolve(child.element),
              docs: docSummary(child),
            );
            for (var c in child.allChildrenSorted) {
              childIndex.add(
                c.name,
                c.type.displayName,
                id: c.anchorId,
                docs: docSummary(c),
              );
            }
          } else {
            libraryIndex.add(
              child.name,
              child.type.displayName,
              id: child.anchorId,
              docs: docSummary(child),
            );
          }
        }
      }
    }
  }

  void _buildElementItemMap(Item item) {
    if (elementItemMap[item.element] == null) {
      elementItemMap[item.element] = item;
    }

    if (item is Items) {
      item.allChildren.forEach(_buildElementItemMap);
    }
  }

  /// Indicate that the given item is the cannonical location from which to
  /// reference its associated Element.
  void _makeCanonical(Item item) {
    elementItemMap[item.element] = item;
    if (item is Items) {
      item.allChildren.forEach(_makeCanonical);
    }
  }

  void _calculateFor(Item item) {
    if (item.element is InterfaceElement) {
      var element = item.element as InterfaceElement;

      var superItem = itemForElement(element.supertype?.element);
      superItem?._addRelationship(item, RelationshipKind.$subclasses);

      for (var $interface in element.interfaces) {
        var interfaceItem = itemForElement($interface.element);
        interfaceItem?._addRelationship(item, RelationshipKind.$implements);
      }

      for (var $mixin in element.mixins) {
        var interfaceItem = itemForElement($mixin.element);
        interfaceItem?._addRelationship(item, RelationshipKind.$mixes);
      }
    } else if (item.element is ExtensionElement) {
      var element = item.element as ExtensionElement;

      var extendedElement = element.extendedType.element;
      var extendedItem = itemForElement(extendedElement);
      extendedItem?._addRelationship(item, RelationshipKind.$extended);
    }
  }

  Item? itemForElement(Element? element) {
    return elementItemMap[element];
  }

  void addResolution(Item item, WorkspaceFile file) {
    resolver.addResolution(item, file);
  }

  String? resolve(Element? element, {WorkspaceFile? from}) {
    return resolver.resolve(element, from: from);
  }

  String hrefOrSpan(String text, Element element, {WorkspaceFile? from}) {
    return resolver.hrefOrSpan(text, element, from: from);
  }

  void _processDuplicates() {
    // todo: decide whether elements should be de-duped globally or just
    // de-duped per package

    // todo: instead of having one unique element definition location globally,
    // have a main one, but allow per-lib scopes to have an override

    // Note that we only care about de-duping for library members.

    // todo: we want to the container members to resolve to the same place as
    //       their parents

    final topLevelElementsToItems = <Element, List<Item>>{};

    // look for dups
    for (var package in packages) {
      for (var library in package.libraries) {
        for (var item in library.allChildren) {
          var element = item.element;
          topLevelElementsToItems.putIfAbsent(element, () => []).add(item);
        }
      }
    }

    // todo: create a relationship between an item and the library's its defined
    // in
    // todo: do we have multiple Item's for each unique Element?
    // todo: where are Item's created, and do we de-dupe wrt Elements?
    // var libraryElement = item.element.library;
    // if (item.element is! LibraryElement && libraryElement != null) {
    //   item._addRelationship(item, RelationshipKind.$definedIn);
    // }

    for (var entry in topLevelElementsToItems.entries.where(
      (entry) => entry.value.length > 1,
    )) {
      _updateForDuplicates(entry.key, entry.value);
    }

    resolver.initElementItemMap(elementItemMap);
  }

  void _updateForDuplicates(Element element, List<Item> items) {
    // Use cases:

    // definied in a public lib; exported from a 2nd public lib
    // dups for [promiseToFuture<T>(...)] defined in dart:js_util:
    //   promiseToFuture from dart:js_util
    //   promiseToFuture from dart:html

    // defined in a private lib, exported (independently) from two public libs
    // dups for [abstract class BytesBuilder] defined in dart:_internal:
    //   BytesBuilder from dart:io
    //   BytesBuilder from dart:typed_data

    // defined in a private library
    // exported from a public library
    // exported from other public libraries from the first public library
    // ex., flutter:widgets symbols (defined in private libs), exported as part
    //   of flutter:material

    // todo: we want to sort these dups via the length of their export chain
    //   0: defined in a public lib
    //   1: defined in a private lib, exported from a public one
    //   2: exported from a public lib
    //   3: ...

    // then, choose a 'best' Item

    // replace all the worst Items with forward refs to that bext one

    // have all Items equal to the best item add local package overrides to
    // their local ref

    var exports = items.map((item) {
      var parentLib = item.libraryParent;
      var len = parentLib!._calcElementExportLength(element);
      return _ElementExports(element, item, parentLib, len);
    }).toList()..sort();

    print(
      'dups for [$element] defined in '
      '${element.library?.librarySource.uri}:',
    );
    for (var export in exports) {
      print(
        '  ${export.element.name} from '
        '${export.libraryContainer.name}: ${export.exportLength}',
      );
    }

    // for non-canonical items:
    //   - convert to export
    //   - make sure the element map point to the cannonical versions
    var canonical = exports.first;
    _makeCanonical(canonical.item);

    print('[$element] => ${elementItemMap[element]!.debugPath}');

    for (var export in exports) {
      if (export.exportLength > canonical.exportLength) {
        export.item._convertToExport(
          exportedFrom: canonical.libraryContainer,
          cannonicalItem: canonical.item,
        );
      }
    }
  }
}

class _ElementExports implements Comparable<_ElementExports> {
  final Element element;
  final Item item;
  final LibraryItemContainer libraryContainer;
  final int exportLength;

  _ElementExports(
    this.element,
    this.item,
    this.libraryContainer,
    this.exportLength,
  );

  @override
  int compareTo(_ElementExports other) {
    var diff = exportLength - other.exportLength;
    if (diff != 0) return diff;

    return libraryContainer.name.compareTo(other.libraryContainer.name);
  }
}

class Package implements Comparable<Package> {
  final String name;
  final List<LibraryItemContainer> libraries = [];

  String? version;
  String? description;

  Package(this.name);

  bool get includeInUrls => name.contains(':');

  @override
  int compareTo(Package other) {
    return name.compareTo(other.name);
  }
}

/// A tuple of a relationship kind (subclass, implementor, ...) and a set of
/// items.
typedef RelationshipMap = Map<RelationshipKind, List<Item>>;

class Item {
  Items? parent;
  final Element element;
  late final GroupType type = GroupType.typeFor(element);
  final RelationshipMap relationships = SplayTreeMap();

  String? nameOverride;

  Scope? _scopeCache;

  Item(this.parent, this.element);

  String get name {
    if (nameOverride != null) return nameOverride!;

    var result = element.displayName;
    if (result.isEmpty) {
      // Assume this is a ctor.
      return element.enclosingElement!.name!;
    } else {
      return result;
    }
  }

  LibraryItemContainer? get libraryParent {
    Item? item = this;
    while (item != null) {
      if (item is LibraryItemContainer) return item;
      item = item.parent;
    }
    return null;
  }

  Scope get scope => _scopeCache ??= _calcScope(element)!;

  String get anchorId => stringToAnchorId(name);

  late String? docs = _calculateDocs();

  bool get hasDocs => docs != null;

  ClassElement get asClass => element as ClassElement;

  MixinElement get asMixin => element as MixinElement;

  ExtensionElement get asExtension => element as ExtensionElement;

  // ignore: experimental_member_use
  ExtensionTypeElement get asExtensionType => element as ExtensionTypeElement;

  EnumElement get asEnum => element as EnumElement;

  FieldElement get asField => element as FieldElement;

  TopLevelVariableElement get asTopLevelVariableElement =>
      element as TopLevelVariableElement;

  PropertyAccessorElement get asAccessor => element as PropertyAccessorElement;

  MethodElement get asMethod => element as MethodElement;

  FunctionElement get asFunction => element as FunctionElement;

  ConstructorElement get asConstructor => element as ConstructorElement;

  TypeAliasElement get asTypeAlias => element as TypeAliasElement;

  bool get isStatic {
    if (element is ClassMemberElement) {
      return (element as ClassMemberElement).isStatic;
    } else if (element is ExecutableElement) {
      return (element as ExecutableElement).isStatic;
    }
    throw StateError('element not a class member: $element');
  }

  String get debugPath => parent == null ? name : '${parent!.debugPath}/$name';

  void _addRelationship(Item item, RelationshipKind kind) {
    relationships.putIfAbsent(kind, () => []).add(item);
  }

  String? _calculateDocs() {
    var result = element.documentationComment;
    if (result == null) {
      var enclosing = element.enclosingElement;
      if (enclosing is InterfaceElement) {
        if (element.kind == ElementKind.METHOD) {
          result = _lookupMethodDocs(element as MethodElement);
        } else if (element.kind == ElementKind.GETTER) {
          result = _lookupGetterDocs(element as PropertyAccessorElement);
        } else if (element.kind == ElementKind.SETTER) {
          result = _lookupSetterDocs(element as PropertyAccessorElement);
        }
      }
    }

    return result == null ? null : stripDartdoc(result);
  }

  String? _lookupMethodDocs(MethodElement element) {
    var enclosing = element.enclosingElement as InterfaceElement;
    var superMethod = enclosing.thisType.lookUpMethod2(
      element.name,
      element.library,
      inherited: true,
    );
    return superMethod == null
        ? null
        : (superMethod.documentationComment ?? _lookupMethodDocs(superMethod));
  }

  String? _lookupGetterDocs(PropertyAccessorElement element) {
    var enclosing = element.enclosingElement as InterfaceElement;
    var accessor = enclosing.thisType.lookUpGetter2(
      element.name,
      element.library,
      inherited: true,
    );
    return accessor == null
        ? null
        : (accessor.documentationComment ?? _lookupGetterDocs(accessor));
  }

  String? _lookupSetterDocs(PropertyAccessorElement element) {
    var enclosing = element.enclosingElement as InterfaceElement;
    var accessor = enclosing.thisType.lookUpSetter2(
      element.name,
      element.library,
      inherited: true,
    );
    return accessor == null
        ? null
        : (accessor.documentationComment ?? _lookupSetterDocs(accessor));
  }

  MarkdownLinkResolver markdownLinkResolver(Resolver resolver) {
    return (String ref) {
      var result = resolver.resolveDocReference(
        ref,
        context: this,
        fromFile: resolver.fileFor(element),
      );

      // todo: log this?
      // if (result == null) {
      //   print('    unresolved: [$ref] from ${element.displayName}');
      // }

      return result;
    };
  }

  List<ElementAnnotation> get annotations {
    return element.metadata.where((annotation) {
      var meta = annotation.element;
      if (meta == null) return false;

      // `meta` is a PropertyAccessorElement or a ConstructorElement.

      // Filter pragma annotations - these are directions to tools, not first
      // class properties of the source code.
      if (meta is PropertyAccessorElement) {
        if (meta.name == 'pragma') return false;
      } else if (meta is ConstructorElement) {
        if (meta.enclosingElement.name == 'pragma') return false;
      }

      return true;
    }).toList();
  }

  static Scope? _calcScope(Element element) {
    // todo: more of these scopes could be cached / looked up by Item

    if (element is CompilationUnitElement) {
      return _calcScope(element.enclosingElement);
    }

    if (element is LibraryElement) {
      return element.scope;
    } else if (element is ExtensionElement) {
      return ExtensionScope(_calcScope(element.enclosingElement)!, element);
    } else if (element is InterfaceElement) {
      return InterfaceScope(_calcScope(element.enclosingElement)!, element);
    } else if (element is MethodElement) {
      return FormalParameterScope(
        _calcScope(element.enclosingElement)!,
        element.parameters,
      );
    } else if (element is FunctionElement) {
      return FormalParameterScope(
        _calcScope(element.enclosingElement)!,
        element.parameters,
      );
    } else if (element is ConstructorElement) {
      return ConstructorInitializerScope(
        _calcScope(element.enclosingElement)!,
        element,
      );
    } else if (element is PropertyAccessorElement) {
      return LocalScope(_calcScope(element.enclosingElement)!)..add(element);
    } else if (element is FieldElement) {
      return LocalScope(_calcScope(element.enclosingElement)!)..add(element);
    } else if (element is TypeAliasElement) {
      return _calcScope(element.enclosingElement);
    } else {
      print('scope not found for ${element.runtimeType}');
      return null;
    }
  }

  /// Indicate that this Item should not be considered to be defined in the
  /// current library, but documented as an export.
  ///
  /// The item should be a direct child of a library.
  void _convertToExport({
    required LibraryItemContainer exportedFrom,
    required Item cannonicalItem,
  }) {
    var library = parent as LibraryItemContainer;

    // todo: there are more dangling references here to clean up

    // remove from children
    library.groups[type]!.items.remove(this);
    if (library.groups[type]!.items.isEmpty) {
      library.groups.remove(type);
    }

    // add to an exports list
    library.exports.add(ExportedItem(cannonicalItem, exportedFrom));
  }
}

class ExportedItem {
  final Item item;
  final LibraryItemContainer exportedFrom;

  ExportedItem(this.item, this.exportedFrom);
}

abstract class Items extends Item {
  final Map<GroupType, Group> groups = SplayTreeMap();

  Items(super.parent, super.element);

  T addChild<T extends Item>(T item) {
    var groupType = GroupType.typeFor(item.element);
    if (groupType != GroupType.skip) {
      groups.putIfAbsent(groupType, () => Group(groupType)).items.add(item);
    }
    return item;
  }

  Iterable<Item> get allChildren {
    return groups.entries.expand((entry) => entry.value.items);
  }

  List<Item> get allChildrenSorted {
    var items = allChildren.toList();
    items.sort((a, b) => adjustedLexicalCompare(a.name, b.name));
    return items;
  }

  void sort() {
    for (var entry in groups.entries) {
      // have enums retain their declaration order
      if (entry.key == GroupType.enumValue) continue;

      entry.value.sort();
    }
  }

  static Map<GroupType, List<Item>> itemsByGroup(List<Item> items) {
    var result = SplayTreeMap<GroupType, List<Item>>();
    for (var item in items) {
      result.putIfAbsent(item.type, () => []).add(item);
    }
    for (var entry in result.entries) {
      entry.value.sort((a, b) => adjustedLexicalCompare(a.name, b.name));
    }
    return result;
  }
}

class InterfaceElementItems extends Items {
  InterfaceElementItems(super.parent, InterfaceElement super.element);

  @override
  InterfaceElement get element => super.element as InterfaceElement;
}

class ExtensionElementItems extends Items {
  ExtensionElementItems(super.parent, super.element);

  @override
  ExtensionElement get element => super.element as ExtensionElement;
}

class LibraryItemContainer extends Items
    implements Comparable<LibraryItemContainer> {
  final Package? package;

  /// The list of items that are part of this library's public API, but that
  /// are considered exports (primarily defined elsewhere).
  final List<ExportedItem> exports = [];

  LibraryItemContainer(this.package, LibraryElement element, String name)
    : super(null, element) {
    nameOverride = name;

    var exportNamespace = element.exportNamespace;
    var elements = exportNamespace.definedNames.values
        .where((element) => element.isPublic)
        .toList();
    elements.sort((a, b) => adjustedLexicalCompare(a.name ?? '', b.name ?? ''));

    for (var e in elements) {
      if (e is InterfaceElement) {
        var interfaceElement = e;

        var interfaceElementChildren = addChild(
          InterfaceElementItems(this, interfaceElement),
        );

        for (var child in interfaceElement.children.where((c) => c.isPublic)) {
          if (child.isSynthetic) continue;

          interfaceElementChildren.addChild(
            Item(interfaceElementChildren, child),
          );
        }

        interfaceElementChildren.sort();
      } else if (e is ExtensionElement) {
        var extensionElement = e;

        var extensionElementChildren = addChild(
          ExtensionElementItems(this, extensionElement),
        );

        for (var child in extensionElement.children.where((c) => c.isPublic)) {
          if (child.isSynthetic) continue;

          extensionElementChildren.addChild(
            Item(extensionElementChildren, child),
          );
        }

        extensionElementChildren.sort();
      } else {
        addChild(Item(this, e));
      }
    }
  }

  String get urlName => package != null && package!.includeInUrls
      ? '${package!.name}/$name'
      : name;

  @override
  LibraryElement get element => super.element as LibraryElement;

  Map<LibraryItemContainer, List<Item>> get exportsByLibrary {
    var results = SplayTreeMap<LibraryItemContainer, List<Item>>();

    for (var export in exports) {
      results.putIfAbsent(export.exportedFrom, () => []).add(export.item);
    }

    return results;
  }

  /// For a given element defined in this library or exported from it, calculate
  /// how many library exports exist betwen this library and the library where
  /// the element is actually defined.
  ///
  /// For example, if the element is defined in this library, the export length
  /// would be 0.
  ///
  /// For an element defined in a private library exported from this library,
  /// the export length would be 1. Higer numbers indicate a longer export path.
  int _calcElementExportLength(Element e) {
    // todo: implement this using directive export info

    if (e.library == element) return 0;

    return 1;
  }

  @override
  int compareTo(LibraryItemContainer other) {
    return name.compareTo(other.name);
  }
}

class Group implements Comparable<Group> {
  final GroupType type;
  final List<Item> items = [];

  Group(this.type);

  String get name => type.title;

  String get anchorId => stringToAnchorId('_$name');

  bool get containerType => type.containerType;

  void sort() {
    items.sort((a, b) => adjustedLexicalCompare(a.name, b.name));
  }

  @override
  int compareTo(Group other) {
    return type.index - other.type.index;
  }
}

enum GroupType implements Comparable<GroupType> {
  // TODO: why is there not an ElementKind.MIXIN?

  // class members
  constructor('Constructors', 'constructor', {ElementKind.CONSTRUCTOR}),
  enumValue('Values', 'enum value', {}),
  field('Fields', 'field', {ElementKind.FIELD}),
  accessor('Accessors', 'accessor', {ElementKind.GETTER, ElementKind.SETTER}),
  method('Methods', 'method', {ElementKind.METHOD}),

  // library members
  topLevelVariable('Top Level Variables', 'top level variable', {
    ElementKind.TOP_LEVEL_VARIABLE,
  }),
  function('Functions', 'function', {ElementKind.FUNCTION}),
  functionTypeAlias('Function Type Aliases', 'function type alias', {
    ElementKind.FUNCTION_TYPE_ALIAS,
  }),
  typeAlias('Type Aliases', 'type alias', {ElementKind.TYPE_ALIAS}),

  // container items
  $enum('Enums', 'enum', {ElementKind.ENUM}, containerType: true),
  $mixin('Mixins', 'mixin', {}, containerType: true),
  $class('Classes', 'class', {ElementKind.CLASS}, containerType: true),
  $extension('Extensions', 'extension', {
    ElementKind.EXTENSION,
  }, containerType: true),
  $extensionType('Extension Types', 'extension type', {
    ElementKind.EXTENSION_TYPE,
  }, containerType: true),
  // todo: implement
  // $record('Records', 'record', {ElementKind.RECORD}, containerType: true),

  // catch-all
  skip('Skip', 'skip', {
    ElementKind.DYNAMIC,
    ElementKind.NEVER,
    ElementKind.TYPE_PARAMETER,
  }),
  other('Other', 'other', {});

  final String title;
  final Set<Object> elementKinds;
  final bool containerType;
  final String displayName;

  const GroupType(
    this.title,
    this.displayName,
    this.elementKinds, {
    this.containerType = false,
  });

  @override
  int compareTo(GroupType other) {
    return index - other.index;
  }

  /// Return the [GroupType] for the given [element].
  static GroupType typeFor(Element element) {
    final kind = element.kind;
    if (element is FieldElement && element.isEnumConstant) {
      return GroupType.enumValue;
    }
    if (element is MixinElement) return GroupType.$mixin;
    for (var val in GroupType.values) {
      if (val.elementKinds.contains(kind)) {
        return val;
      }
    }
    print('*** ${element.kind} ***');
    return GroupType.other;
  }
}

// todo: remove files if we remove an Item
class Resolver {
  // libraries and classes to files

  final Map<Item, WorkspaceFile> itemToFileMap = {};
  late final Map<Element, Item> elementToItemMap;

  void addResolution(Item item, WorkspaceFile file) {
    itemToFileMap[item] = file;
  }

  void initElementItemMap(Map<Element, Item> elementItemMap) {
    elementToItemMap = elementItemMap;
  }

  String? resolve(Element? element, {WorkspaceFile? from}) {
    var item = elementToItemMap[element];
    var target = itemToFileMap[item];
    if (target == null) return null;

    if (from != null) {
      // Replaced for performance reasons.
      return target.path.pathRelative(fromDir: p.dirname(from.path));
      // return p.relative(target.path, from: p.dirname(from.path));
    } else {
      return target.path;
    }
  }

  // todo: html encode 'text'
  String hrefOrSpan(String text, Element element, {WorkspaceFile? from}) {
    var ref = resolve(element, from: from);

    if (ref != null) {
      return '<a href="$ref">$text</a>';
    } else {
      return '<span>$text</span>';
    }
  }

  /// Returns a Uri if the reference is resolved.
  String? resolveDocReference(
    String reference, {
    required Item context,
    WorkspaceFile? fromFile,
  }) {
    // TODO: handle dotted references (Foo.bar, ...)

    var scope = context.scope;
    var element = scope.lookup(reference).getter;
    return resolve(element, from: fromFile);
  }

  WorkspaceFile? fileFor(Element element) {
    // See if this element cooresponds directly to a file.
    var item = elementToItemMap[element];
    var file = itemToFileMap[item];
    if (file != null) return file;

    // Otherwise check its library or compilation element.
    if (element.enclosingElement is CompilationUnitElement) {
      var enclosingItem = elementToItemMap[element.library];
      file = itemToFileMap[enclosingItem];
    } else {
      var enclosingItem = elementToItemMap[element.enclosingElement];
      file = itemToFileMap[enclosingItem];
    }

    return file;
  }
}

enum RelationshipKind implements Comparable<RelationshipKind> {
  $subclasses('Subclassed by'),
  $implements('Implemented by'),
  $mixes('Mixed into'),
  $extended('Extended by');

  final String title;

  const RelationshipKind(this.title);

  @override
  int compareTo(RelationshipKind other) {
    return index - other.index;
  }
}

/// A StringBuffer like class that allows you to write out Element references,
/// dart format the written text, and emit the result as html with the element
/// references converted to html links.
class LinkedText {
  final Resolver resolver;
  final WorkspaceFile fromFile;

  final List<_ElementSpan> _elementSpans = [];

  final StringBuffer _buf = StringBuffer();
  int _charIndex = 0;

  LinkedText(this.resolver, this.fromFile);

  void write(String str) {
    for (var i = 0; i < str.length; i++) {
      if (str[i].trim().isNotEmpty) {
        _charIndex++;
      }
    }
    _buf.write(str);
  }

  void writeElement(String str, Element element) {
    _elementSpans.add(_ElementSpan(element, _charIndex, str));
    _charIndex += str.length;
    _buf.write(str);
  }

  String emitHtml(String Function(String) formatHelper, [String suffix = '']) {
    var fmt = formatHelper(_buf.toString());

    var chunks = _chunks(fmt, _elementSpans, _spanStarts(fmt)).toList();

    var html = chunks.map((chunk) {
      if (chunk is String) {
        return htmlEscape(chunk);
      } else {
        var span = chunk as _ElementSpan;

        var uri = resolver.resolve(span.element, from: fromFile);
        if (uri == null) {
          return htmlEscape(span.text);
        } else {
          return '<a href="$uri">${htmlEscape(span.text)}</a>';
        }
      }
    }).join();

    return '<pre class="declaration"><code>$html$suffix</code></pre>';
  }

  List<int> _spanStarts(String fmt) {
    var result = <int>[];

    var spans = _elementSpans.iterator;
    if (!spans.moveNext()) return result;

    var index = 0;
    int i;

    for (i = 0; i < fmt.length; i++) {
      if (fmt[i].trim().isEmpty) continue;

      if (index == spans.current.start) {
        result.add(i);
        if (!spans.moveNext()) return result;
      }

      index++;
    }

    return result;
  }

  // A List of Strings and _ElementSpans.
  Iterable<dynamic> _chunks(
    String fmt,
    List<_ElementSpan> spans,
    List<int> spanStarts,
  ) sync* {
    var fmtIndex = 0;

    for (var i = 0; i < spans.length; i++) {
      var span = spans[i];
      var spanStart = spanStarts[i];

      if (fmtIndex < spanStart) {
        yield fmt.substring(fmtIndex, spanStart);
        fmtIndex = spanStart;
      }

      yield span;
      fmtIndex = spanStart + span.text.length;
    }

    if (fmtIndex < fmt.length) {
      yield fmt.substring(fmtIndex);
    }
  }

  @override
  String toString() => _buf.toString();
}

class _ElementSpan {
  final Element element;
  final int start;
  final String text;

  _ElementSpan(this.element, this.start, this.text);

  @override
  String toString() => '[$text]';
}
