///
//  Generated code. Do not modify.
//  source: google/ads/googleads/v1/enums/conversion_action_status.proto
///
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name

import 'dart:core' as $core
    show bool, Deprecated, double, int, List, Map, override, String;

import 'package:protobuf/protobuf.dart' as $pb;

export 'conversion_action_status.pbenum.dart';

class ConversionActionStatusEnum extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      'ConversionActionStatusEnum',
      package: const $pb.PackageName('google.ads.googleads.v1.enums'))
    ..hasRequiredFields = false;

  ConversionActionStatusEnum() : super();
  ConversionActionStatusEnum.fromBuffer($core.List<$core.int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ConversionActionStatusEnum.fromJson($core.String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ConversionActionStatusEnum clone() =>
      ConversionActionStatusEnum()..mergeFromMessage(this);
  ConversionActionStatusEnum copyWith(
          void Function(ConversionActionStatusEnum) updates) =>
      super.copyWith(
          (message) => updates(message as ConversionActionStatusEnum));
  $pb.BuilderInfo get info_ => _i;
  static ConversionActionStatusEnum create() => ConversionActionStatusEnum();
  ConversionActionStatusEnum createEmptyInstance() => create();
  static $pb.PbList<ConversionActionStatusEnum> createRepeated() =>
      $pb.PbList<ConversionActionStatusEnum>();
  static ConversionActionStatusEnum getDefault() =>
      _defaultInstance ??= create()..freeze();
  static ConversionActionStatusEnum _defaultInstance;
}
