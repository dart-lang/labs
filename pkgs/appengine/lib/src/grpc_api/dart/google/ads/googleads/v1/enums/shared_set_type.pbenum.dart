///
//  Generated code. Do not modify.
//  source: google/ads/googleads/v1/enums/shared_set_type.proto
///
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME,UNUSED_SHOWN_NAME
import 'dart:core' as $core show int, dynamic, String, List, Map;
import 'package:protobuf/protobuf.dart' as $pb;

class SharedSetTypeEnum_SharedSetType extends $pb.ProtobufEnum {
  static const SharedSetTypeEnum_SharedSetType UNSPECIFIED =
      SharedSetTypeEnum_SharedSetType._(0, 'UNSPECIFIED');
  static const SharedSetTypeEnum_SharedSetType UNKNOWN =
      SharedSetTypeEnum_SharedSetType._(1, 'UNKNOWN');
  static const SharedSetTypeEnum_SharedSetType NEGATIVE_KEYWORDS =
      SharedSetTypeEnum_SharedSetType._(2, 'NEGATIVE_KEYWORDS');
  static const SharedSetTypeEnum_SharedSetType NEGATIVE_PLACEMENTS =
      SharedSetTypeEnum_SharedSetType._(3, 'NEGATIVE_PLACEMENTS');

  static const $core.List<SharedSetTypeEnum_SharedSetType> values =
      <SharedSetTypeEnum_SharedSetType>[
    UNSPECIFIED,
    UNKNOWN,
    NEGATIVE_KEYWORDS,
    NEGATIVE_PLACEMENTS,
  ];

  static final $core.Map<$core.int, SharedSetTypeEnum_SharedSetType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static SharedSetTypeEnum_SharedSetType valueOf($core.int value) =>
      _byValue[value];

  const SharedSetTypeEnum_SharedSetType._($core.int v, $core.String n)
      : super(v, n);
}