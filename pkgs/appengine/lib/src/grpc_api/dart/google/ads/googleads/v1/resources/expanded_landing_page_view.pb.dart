///
//  Generated code. Do not modify.
//  source: google/ads/googleads/v1/resources/expanded_landing_page_view.proto
///
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name

import 'dart:core' as $core
    show bool, Deprecated, double, int, List, Map, override, String;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../protobuf/wrappers.pb.dart' as $0;

class ExpandedLandingPageView extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('ExpandedLandingPageView',
      package: const $pb.PackageName('google.ads.googleads.v1.resources'))
    ..aOS(1, 'resourceName')
    ..a<$0.StringValue>(2, 'expandedFinalUrl', $pb.PbFieldType.OM,
        $0.StringValue.getDefault, $0.StringValue.create)
    ..hasRequiredFields = false;

  ExpandedLandingPageView() : super();
  ExpandedLandingPageView.fromBuffer($core.List<$core.int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ExpandedLandingPageView.fromJson($core.String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ExpandedLandingPageView clone() =>
      ExpandedLandingPageView()..mergeFromMessage(this);
  ExpandedLandingPageView copyWith(
          void Function(ExpandedLandingPageView) updates) =>
      super.copyWith((message) => updates(message as ExpandedLandingPageView));
  $pb.BuilderInfo get info_ => _i;
  static ExpandedLandingPageView create() => ExpandedLandingPageView();
  ExpandedLandingPageView createEmptyInstance() => create();
  static $pb.PbList<ExpandedLandingPageView> createRepeated() =>
      $pb.PbList<ExpandedLandingPageView>();
  static ExpandedLandingPageView getDefault() =>
      _defaultInstance ??= create()..freeze();
  static ExpandedLandingPageView _defaultInstance;

  $core.String get resourceName => $_getS(0, '');
  set resourceName($core.String v) {
    $_setString(0, v);
  }

  $core.bool hasResourceName() => $_has(0);
  void clearResourceName() => clearField(1);

  $0.StringValue get expandedFinalUrl => $_getN(1);
  set expandedFinalUrl($0.StringValue v) {
    setField(2, v);
  }

  $core.bool hasExpandedFinalUrl() => $_has(1);
  void clearExpandedFinalUrl() => clearField(2);
}
