///
//  Generated code. Do not modify.
//  source: google/ads/googleads/v1/enums/frequency_cap_time_unit.proto
///
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name

import 'dart:core' as $core
    show bool, Deprecated, double, int, List, Map, override, String;

import 'package:protobuf/protobuf.dart' as $pb;

export 'frequency_cap_time_unit.pbenum.dart';

class FrequencyCapTimeUnitEnum extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('FrequencyCapTimeUnitEnum',
      package: const $pb.PackageName('google.ads.googleads.v1.enums'))
    ..hasRequiredFields = false;

  FrequencyCapTimeUnitEnum() : super();
  FrequencyCapTimeUnitEnum.fromBuffer($core.List<$core.int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  FrequencyCapTimeUnitEnum.fromJson($core.String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  FrequencyCapTimeUnitEnum clone() =>
      FrequencyCapTimeUnitEnum()..mergeFromMessage(this);
  FrequencyCapTimeUnitEnum copyWith(
          void Function(FrequencyCapTimeUnitEnum) updates) =>
      super.copyWith((message) => updates(message as FrequencyCapTimeUnitEnum));
  $pb.BuilderInfo get info_ => _i;
  static FrequencyCapTimeUnitEnum create() => FrequencyCapTimeUnitEnum();
  FrequencyCapTimeUnitEnum createEmptyInstance() => create();
  static $pb.PbList<FrequencyCapTimeUnitEnum> createRepeated() =>
      $pb.PbList<FrequencyCapTimeUnitEnum>();
  static FrequencyCapTimeUnitEnum getDefault() =>
      _defaultInstance ??= create()..freeze();
  static FrequencyCapTimeUnitEnum _defaultInstance;
}
