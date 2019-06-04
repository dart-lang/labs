///
//  Generated code. Do not modify.
//  source: google/cloud/videointelligence/v1p3beta1/video_intelligence.proto
///
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME,UNUSED_SHOWN_NAME
import 'dart:core' as $core show int, dynamic, String, List, Map;
import 'package:protobuf/protobuf.dart' as $pb;

class Feature extends $pb.ProtobufEnum {
  static const Feature FEATURE_UNSPECIFIED =
      Feature._(0, 'FEATURE_UNSPECIFIED');
  static const Feature LABEL_DETECTION = Feature._(1, 'LABEL_DETECTION');
  static const Feature SHOT_CHANGE_DETECTION =
      Feature._(2, 'SHOT_CHANGE_DETECTION');
  static const Feature EXPLICIT_CONTENT_DETECTION =
      Feature._(3, 'EXPLICIT_CONTENT_DETECTION');
  static const Feature TEXT_DETECTION = Feature._(7, 'TEXT_DETECTION');
  static const Feature OBJECT_TRACKING = Feature._(9, 'OBJECT_TRACKING');

  static const $core.List<Feature> values = <Feature>[
    FEATURE_UNSPECIFIED,
    LABEL_DETECTION,
    SHOT_CHANGE_DETECTION,
    EXPLICIT_CONTENT_DETECTION,
    TEXT_DETECTION,
    OBJECT_TRACKING,
  ];

  static final $core.Map<$core.int, Feature> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static Feature valueOf($core.int value) => _byValue[value];

  const Feature._($core.int v, $core.String n) : super(v, n);
}

class LabelDetectionMode extends $pb.ProtobufEnum {
  static const LabelDetectionMode LABEL_DETECTION_MODE_UNSPECIFIED =
      LabelDetectionMode._(0, 'LABEL_DETECTION_MODE_UNSPECIFIED');
  static const LabelDetectionMode SHOT_MODE =
      LabelDetectionMode._(1, 'SHOT_MODE');
  static const LabelDetectionMode FRAME_MODE =
      LabelDetectionMode._(2, 'FRAME_MODE');
  static const LabelDetectionMode SHOT_AND_FRAME_MODE =
      LabelDetectionMode._(3, 'SHOT_AND_FRAME_MODE');

  static const $core.List<LabelDetectionMode> values = <LabelDetectionMode>[
    LABEL_DETECTION_MODE_UNSPECIFIED,
    SHOT_MODE,
    FRAME_MODE,
    SHOT_AND_FRAME_MODE,
  ];

  static final $core.Map<$core.int, LabelDetectionMode> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static LabelDetectionMode valueOf($core.int value) => _byValue[value];

  const LabelDetectionMode._($core.int v, $core.String n) : super(v, n);
}

class Likelihood extends $pb.ProtobufEnum {
  static const Likelihood LIKELIHOOD_UNSPECIFIED =
      Likelihood._(0, 'LIKELIHOOD_UNSPECIFIED');
  static const Likelihood VERY_UNLIKELY = Likelihood._(1, 'VERY_UNLIKELY');
  static const Likelihood UNLIKELY = Likelihood._(2, 'UNLIKELY');
  static const Likelihood POSSIBLE = Likelihood._(3, 'POSSIBLE');
  static const Likelihood LIKELY = Likelihood._(4, 'LIKELY');
  static const Likelihood VERY_LIKELY = Likelihood._(5, 'VERY_LIKELY');

  static const $core.List<Likelihood> values = <Likelihood>[
    LIKELIHOOD_UNSPECIFIED,
    VERY_UNLIKELY,
    UNLIKELY,
    POSSIBLE,
    LIKELY,
    VERY_LIKELY,
  ];

  static final $core.Map<$core.int, Likelihood> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static Likelihood valueOf($core.int value) => _byValue[value];

  const Likelihood._($core.int v, $core.String n) : super(v, n);
}

class StreamingFeature extends $pb.ProtobufEnum {
  static const StreamingFeature STREAMING_FEATURE_UNSPECIFIED =
      StreamingFeature._(0, 'STREAMING_FEATURE_UNSPECIFIED');
  static const StreamingFeature STREAMING_LABEL_DETECTION =
      StreamingFeature._(1, 'STREAMING_LABEL_DETECTION');
  static const StreamingFeature STREAMING_SHOT_CHANGE_DETECTION =
      StreamingFeature._(2, 'STREAMING_SHOT_CHANGE_DETECTION');
  static const StreamingFeature STREAMING_EXPLICIT_CONTENT_DETECTION =
      StreamingFeature._(3, 'STREAMING_EXPLICIT_CONTENT_DETECTION');
  static const StreamingFeature STREAMING_OBJECT_TRACKING =
      StreamingFeature._(4, 'STREAMING_OBJECT_TRACKING');

  static const $core.List<StreamingFeature> values = <StreamingFeature>[
    STREAMING_FEATURE_UNSPECIFIED,
    STREAMING_LABEL_DETECTION,
    STREAMING_SHOT_CHANGE_DETECTION,
    STREAMING_EXPLICIT_CONTENT_DETECTION,
    STREAMING_OBJECT_TRACKING,
  ];

  static final $core.Map<$core.int, StreamingFeature> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static StreamingFeature valueOf($core.int value) => _byValue[value];

  const StreamingFeature._($core.int v, $core.String n) : super(v, n);
}
