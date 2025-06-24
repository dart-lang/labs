// This is a generated file - do not edit.
//
// Generated from google/firestore/v1/write.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// A value that is calculated by the server.
class DocumentTransform_FieldTransform_ServerValue extends $pb.ProtobufEnum {
  /// Unspecified. This value must not be used.
  static const DocumentTransform_FieldTransform_ServerValue SERVER_VALUE_UNSPECIFIED = DocumentTransform_FieldTransform_ServerValue._(0, _omitEnumNames ? '' : 'SERVER_VALUE_UNSPECIFIED');
  /// The time at which the server processed the request, with millisecond
  /// precision. If used on multiple fields (same or different documents) in
  /// a transaction, all the fields will get the same server timestamp.
  static const DocumentTransform_FieldTransform_ServerValue REQUEST_TIME = DocumentTransform_FieldTransform_ServerValue._(1, _omitEnumNames ? '' : 'REQUEST_TIME');

  static const $core.List<DocumentTransform_FieldTransform_ServerValue> values = <DocumentTransform_FieldTransform_ServerValue> [
    SERVER_VALUE_UNSPECIFIED,
    REQUEST_TIME,
  ];

  static final $core.List<DocumentTransform_FieldTransform_ServerValue?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 1);
  static DocumentTransform_FieldTransform_ServerValue? valueOf($core.int value) =>  value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DocumentTransform_FieldTransform_ServerValue._(super.value, super.name);
}


const $core.bool _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
