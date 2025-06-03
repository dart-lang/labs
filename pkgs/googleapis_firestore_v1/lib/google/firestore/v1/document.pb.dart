//
//  Generated code. Do not modify.
//  source: google/firestore/v1/document.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../protobuf/struct.pbenum.dart' as $8;
import '../../protobuf/timestamp.pb.dart' as $6;
import '../../type/latlng.pb.dart' as $7;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// A Firestore document.
///
/// Must not exceed 1 MiB - 4 bytes.
class Document extends $pb.GeneratedMessage {
  factory Document({
    $core.String? name,
    $core.Iterable<$core.MapEntry<$core.String, Value>>? fields,
    $6.Timestamp? createTime,
    $6.Timestamp? updateTime,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (fields != null) result.fields.addEntries(fields);
    if (createTime != null) result.createTime = createTime;
    if (updateTime != null) result.updateTime = updateTime;
    return result;
  }

  Document._();

  factory Document.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory Document.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Document', package: const $pb.PackageName(_omitMessageNames ? '' : 'google.firestore.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..m<$core.String, Value>(2, _omitFieldNames ? '' : 'fields', entryClassName: 'Document.FieldsEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: Value.create, valueDefaultOrMaker: Value.getDefault, packageName: const $pb.PackageName('google.firestore.v1'))
    ..aOM<$6.Timestamp>(3, _omitFieldNames ? '' : 'createTime', subBuilder: $6.Timestamp.create)
    ..aOM<$6.Timestamp>(4, _omitFieldNames ? '' : 'updateTime', subBuilder: $6.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Document clone() => Document()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Document copyWith(void Function(Document) updates) => super.copyWith((message) => updates(message as Document)) as Document;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Document create() => Document._();
  @$core.override
  Document createEmptyInstance() => create();
  static $pb.PbList<Document> createRepeated() => $pb.PbList<Document>();
  @$core.pragma('dart2js:noInline')
  static Document getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Document>(create);
  static Document? _defaultInstance;

  /// The resource name of the document, for example
  /// `projects/{project_id}/databases/{database_id}/documents/{document_path}`.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// The document's fields.
  ///
  /// The map keys represent field names.
  ///
  /// Field names matching the regular expression `__.*__` are reserved. Reserved
  /// field names are forbidden except in certain documented contexts. The field
  /// names, represented as UTF-8, must not exceed 1,500 bytes and cannot be
  /// empty.
  ///
  /// Field paths may be used in other contexts to refer to structured fields
  /// defined here. For `map_value`, the field path is represented by a
  /// dot-delimited (`.`) string of segments. Each segment is either a simple
  /// field name (defined below) or a quoted field name. For example, the
  /// structured field `"foo" : { map_value: { "x&y" : { string_value: "hello"
  /// }}}` would be represented by the field path `` foo.`x&y` ``.
  ///
  /// A simple field name contains only characters `a` to `z`, `A` to `Z`,
  /// `0` to `9`, or `_`, and must not start with `0` to `9`. For example,
  /// `foo_bar_17`.
  ///
  /// A quoted field name starts and ends with `` ` `` and
  /// may contain any character. Some characters, including `` ` ``, must be
  /// escaped using a `\`. For example, `` `x&y` `` represents `x&y` and
  /// `` `bak\`tik` `` represents `` bak`tik ``.
  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, Value> get fields => $_getMap(1);

  /// Output only. The time at which the document was created.
  ///
  /// This value increases monotonically when a document is deleted then
  /// recreated. It can also be compared to values from other documents and
  /// the `read_time` of a query.
  @$pb.TagNumber(3)
  $6.Timestamp get createTime => $_getN(2);
  @$pb.TagNumber(3)
  set createTime($6.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCreateTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreateTime() => $_clearField(3);
  @$pb.TagNumber(3)
  $6.Timestamp ensureCreateTime() => $_ensure(2);

  /// Output only. The time at which the document was last changed.
  ///
  /// This value is initially set to the `create_time` then increases
  /// monotonically with each change to the document. It can also be
  /// compared to values from other documents and the `read_time` of a query.
  @$pb.TagNumber(4)
  $6.Timestamp get updateTime => $_getN(3);
  @$pb.TagNumber(4)
  set updateTime($6.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasUpdateTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearUpdateTime() => $_clearField(4);
  @$pb.TagNumber(4)
  $6.Timestamp ensureUpdateTime() => $_ensure(3);
}

enum Value_ValueType {
  booleanValue, 
  integerValue, 
  doubleValue, 
  referenceValue, 
  mapValue, 
  geoPointValue, 
  arrayValue, 
  timestampValue, 
  nullValue, 
  stringValue, 
  bytesValue, 
  notSet
}

/// A message that can hold any of the supported value types.
class Value extends $pb.GeneratedMessage {
  factory Value({
    $core.bool? booleanValue,
    $fixnum.Int64? integerValue,
    $core.double? doubleValue,
    $core.String? referenceValue,
    MapValue? mapValue,
    $7.LatLng? geoPointValue,
    ArrayValue? arrayValue,
    $6.Timestamp? timestampValue,
    $8.NullValue? nullValue,
    $core.String? stringValue,
    $core.List<$core.int>? bytesValue,
  }) {
    final result = create();
    if (booleanValue != null) result.booleanValue = booleanValue;
    if (integerValue != null) result.integerValue = integerValue;
    if (doubleValue != null) result.doubleValue = doubleValue;
    if (referenceValue != null) result.referenceValue = referenceValue;
    if (mapValue != null) result.mapValue = mapValue;
    if (geoPointValue != null) result.geoPointValue = geoPointValue;
    if (arrayValue != null) result.arrayValue = arrayValue;
    if (timestampValue != null) result.timestampValue = timestampValue;
    if (nullValue != null) result.nullValue = nullValue;
    if (stringValue != null) result.stringValue = stringValue;
    if (bytesValue != null) result.bytesValue = bytesValue;
    return result;
  }

  Value._();

  factory Value.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory Value.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Value_ValueType> _Value_ValueTypeByTag = {
    1 : Value_ValueType.booleanValue,
    2 : Value_ValueType.integerValue,
    3 : Value_ValueType.doubleValue,
    5 : Value_ValueType.referenceValue,
    6 : Value_ValueType.mapValue,
    8 : Value_ValueType.geoPointValue,
    9 : Value_ValueType.arrayValue,
    10 : Value_ValueType.timestampValue,
    11 : Value_ValueType.nullValue,
    17 : Value_ValueType.stringValue,
    18 : Value_ValueType.bytesValue,
    0 : Value_ValueType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Value', package: const $pb.PackageName(_omitMessageNames ? '' : 'google.firestore.v1'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 5, 6, 8, 9, 10, 11, 17, 18])
    ..aOB(1, _omitFieldNames ? '' : 'booleanValue')
    ..aInt64(2, _omitFieldNames ? '' : 'integerValue')
    ..a<$core.double>(3, _omitFieldNames ? '' : 'doubleValue', $pb.PbFieldType.OD)
    ..aOS(5, _omitFieldNames ? '' : 'referenceValue')
    ..aOM<MapValue>(6, _omitFieldNames ? '' : 'mapValue', subBuilder: MapValue.create)
    ..aOM<$7.LatLng>(8, _omitFieldNames ? '' : 'geoPointValue', subBuilder: $7.LatLng.create)
    ..aOM<ArrayValue>(9, _omitFieldNames ? '' : 'arrayValue', subBuilder: ArrayValue.create)
    ..aOM<$6.Timestamp>(10, _omitFieldNames ? '' : 'timestampValue', subBuilder: $6.Timestamp.create)
    ..e<$8.NullValue>(11, _omitFieldNames ? '' : 'nullValue', $pb.PbFieldType.OE, defaultOrMaker: $8.NullValue.NULL_VALUE, valueOf: $8.NullValue.valueOf, enumValues: $8.NullValue.values)
    ..aOS(17, _omitFieldNames ? '' : 'stringValue')
    ..a<$core.List<$core.int>>(18, _omitFieldNames ? '' : 'bytesValue', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Value clone() => Value()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Value copyWith(void Function(Value) updates) => super.copyWith((message) => updates(message as Value)) as Value;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Value create() => Value._();
  @$core.override
  Value createEmptyInstance() => create();
  static $pb.PbList<Value> createRepeated() => $pb.PbList<Value>();
  @$core.pragma('dart2js:noInline')
  static Value getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Value>(create);
  static Value? _defaultInstance;

  Value_ValueType whichValueType() => _Value_ValueTypeByTag[$_whichOneof(0)]!;
  void clearValueType() => $_clearField($_whichOneof(0));

  /// A boolean value.
  @$pb.TagNumber(1)
  $core.bool get booleanValue => $_getBF(0);
  @$pb.TagNumber(1)
  set booleanValue($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBooleanValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearBooleanValue() => $_clearField(1);

  /// An integer value.
  @$pb.TagNumber(2)
  $fixnum.Int64 get integerValue => $_getI64(1);
  @$pb.TagNumber(2)
  set integerValue($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIntegerValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearIntegerValue() => $_clearField(2);

  /// A double value.
  @$pb.TagNumber(3)
  $core.double get doubleValue => $_getN(2);
  @$pb.TagNumber(3)
  set doubleValue($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDoubleValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearDoubleValue() => $_clearField(3);

  /// A reference to a document. For example:
  /// `projects/{project_id}/databases/{database_id}/documents/{document_path}`.
  @$pb.TagNumber(5)
  $core.String get referenceValue => $_getSZ(3);
  @$pb.TagNumber(5)
  set referenceValue($core.String value) => $_setString(3, value);
  @$pb.TagNumber(5)
  $core.bool hasReferenceValue() => $_has(3);
  @$pb.TagNumber(5)
  void clearReferenceValue() => $_clearField(5);

  /// A map value.
  @$pb.TagNumber(6)
  MapValue get mapValue => $_getN(4);
  @$pb.TagNumber(6)
  set mapValue(MapValue value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasMapValue() => $_has(4);
  @$pb.TagNumber(6)
  void clearMapValue() => $_clearField(6);
  @$pb.TagNumber(6)
  MapValue ensureMapValue() => $_ensure(4);

  /// A geo point value representing a point on the surface of Earth.
  @$pb.TagNumber(8)
  $7.LatLng get geoPointValue => $_getN(5);
  @$pb.TagNumber(8)
  set geoPointValue($7.LatLng value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasGeoPointValue() => $_has(5);
  @$pb.TagNumber(8)
  void clearGeoPointValue() => $_clearField(8);
  @$pb.TagNumber(8)
  $7.LatLng ensureGeoPointValue() => $_ensure(5);

  /// An array value.
  ///
  /// Cannot directly contain another array value, though can contain a
  /// map which contains another array.
  @$pb.TagNumber(9)
  ArrayValue get arrayValue => $_getN(6);
  @$pb.TagNumber(9)
  set arrayValue(ArrayValue value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasArrayValue() => $_has(6);
  @$pb.TagNumber(9)
  void clearArrayValue() => $_clearField(9);
  @$pb.TagNumber(9)
  ArrayValue ensureArrayValue() => $_ensure(6);

  /// A timestamp value.
  ///
  /// Precise only to microseconds. When stored, any additional precision is
  /// rounded down.
  @$pb.TagNumber(10)
  $6.Timestamp get timestampValue => $_getN(7);
  @$pb.TagNumber(10)
  set timestampValue($6.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasTimestampValue() => $_has(7);
  @$pb.TagNumber(10)
  void clearTimestampValue() => $_clearField(10);
  @$pb.TagNumber(10)
  $6.Timestamp ensureTimestampValue() => $_ensure(7);

  /// A null value.
  @$pb.TagNumber(11)
  $8.NullValue get nullValue => $_getN(8);
  @$pb.TagNumber(11)
  set nullValue($8.NullValue value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasNullValue() => $_has(8);
  @$pb.TagNumber(11)
  void clearNullValue() => $_clearField(11);

  /// A string value.
  ///
  /// The string, represented as UTF-8, must not exceed 1 MiB - 89 bytes.
  /// Only the first 1,500 bytes of the UTF-8 representation are considered by
  /// queries.
  @$pb.TagNumber(17)
  $core.String get stringValue => $_getSZ(9);
  @$pb.TagNumber(17)
  set stringValue($core.String value) => $_setString(9, value);
  @$pb.TagNumber(17)
  $core.bool hasStringValue() => $_has(9);
  @$pb.TagNumber(17)
  void clearStringValue() => $_clearField(17);

  /// A bytes value.
  ///
  /// Must not exceed 1 MiB - 89 bytes.
  /// Only the first 1,500 bytes are considered by queries.
  @$pb.TagNumber(18)
  $core.List<$core.int> get bytesValue => $_getN(10);
  @$pb.TagNumber(18)
  set bytesValue($core.List<$core.int> value) => $_setBytes(10, value);
  @$pb.TagNumber(18)
  $core.bool hasBytesValue() => $_has(10);
  @$pb.TagNumber(18)
  void clearBytesValue() => $_clearField(18);
}

/// An array value.
class ArrayValue extends $pb.GeneratedMessage {
  factory ArrayValue({
    $core.Iterable<Value>? values,
  }) {
    final result = create();
    if (values != null) result.values.addAll(values);
    return result;
  }

  ArrayValue._();

  factory ArrayValue.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory ArrayValue.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ArrayValue', package: const $pb.PackageName(_omitMessageNames ? '' : 'google.firestore.v1'), createEmptyInstance: create)
    ..pc<Value>(1, _omitFieldNames ? '' : 'values', $pb.PbFieldType.PM, subBuilder: Value.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArrayValue clone() => ArrayValue()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ArrayValue copyWith(void Function(ArrayValue) updates) => super.copyWith((message) => updates(message as ArrayValue)) as ArrayValue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArrayValue create() => ArrayValue._();
  @$core.override
  ArrayValue createEmptyInstance() => create();
  static $pb.PbList<ArrayValue> createRepeated() => $pb.PbList<ArrayValue>();
  @$core.pragma('dart2js:noInline')
  static ArrayValue getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ArrayValue>(create);
  static ArrayValue? _defaultInstance;

  /// Values in the array.
  @$pb.TagNumber(1)
  $pb.PbList<Value> get values => $_getList(0);
}

/// A map value.
class MapValue extends $pb.GeneratedMessage {
  factory MapValue({
    $core.Iterable<$core.MapEntry<$core.String, Value>>? fields,
  }) {
    final result = create();
    if (fields != null) result.fields.addEntries(fields);
    return result;
  }

  MapValue._();

  factory MapValue.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory MapValue.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MapValue', package: const $pb.PackageName(_omitMessageNames ? '' : 'google.firestore.v1'), createEmptyInstance: create)
    ..m<$core.String, Value>(1, _omitFieldNames ? '' : 'fields', entryClassName: 'MapValue.FieldsEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: Value.create, valueDefaultOrMaker: Value.getDefault, packageName: const $pb.PackageName('google.firestore.v1'))
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MapValue clone() => MapValue()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MapValue copyWith(void Function(MapValue) updates) => super.copyWith((message) => updates(message as MapValue)) as MapValue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MapValue create() => MapValue._();
  @$core.override
  MapValue createEmptyInstance() => create();
  static $pb.PbList<MapValue> createRepeated() => $pb.PbList<MapValue>();
  @$core.pragma('dart2js:noInline')
  static MapValue getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MapValue>(create);
  static MapValue? _defaultInstance;

  /// The map's fields.
  ///
  /// The map keys represent field names. Field names matching the regular
  /// expression `__.*__` are reserved. Reserved field names are forbidden except
  /// in certain documented contexts. The map keys, represented as UTF-8, must
  /// not exceed 1,500 bytes and cannot be empty.
  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, Value> get fields => $_getMap(0);
}


const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
