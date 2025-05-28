//
//  Generated code. Do not modify.
//  source: google/firestore/v1/query_profile.proto
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

import '../../protobuf/duration.pb.dart' as $4;
import '../../protobuf/struct.pb.dart' as $8;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Explain options for the query.
class ExplainOptions extends $pb.GeneratedMessage {
  factory ExplainOptions({
    $core.bool? analyze,
  }) {
    final result = create();
    if (analyze != null) result.analyze = analyze;
    return result;
  }

  ExplainOptions._();

  factory ExplainOptions.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory ExplainOptions.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExplainOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'google.firestore.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'analyze')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExplainOptions clone() => ExplainOptions()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExplainOptions copyWith(void Function(ExplainOptions) updates) => super.copyWith((message) => updates(message as ExplainOptions)) as ExplainOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExplainOptions create() => ExplainOptions._();
  @$core.override
  ExplainOptions createEmptyInstance() => create();
  static $pb.PbList<ExplainOptions> createRepeated() => $pb.PbList<ExplainOptions>();
  @$core.pragma('dart2js:noInline')
  static ExplainOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExplainOptions>(create);
  static ExplainOptions? _defaultInstance;

  /// Optional. Whether to execute this query.
  ///
  /// When false (the default), the query will be planned, returning only
  /// metrics from the planning stages.
  ///
  /// When true, the query will be planned and executed, returning the full
  /// query results along with both planning and execution stage metrics.
  @$pb.TagNumber(1)
  $core.bool get analyze => $_getBF(0);
  @$pb.TagNumber(1)
  set analyze($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAnalyze() => $_has(0);
  @$pb.TagNumber(1)
  void clearAnalyze() => $_clearField(1);
}

/// Explain metrics for the query.
class ExplainMetrics extends $pb.GeneratedMessage {
  factory ExplainMetrics({
    PlanSummary? planSummary,
    ExecutionStats? executionStats,
  }) {
    final result = create();
    if (planSummary != null) result.planSummary = planSummary;
    if (executionStats != null) result.executionStats = executionStats;
    return result;
  }

  ExplainMetrics._();

  factory ExplainMetrics.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory ExplainMetrics.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExplainMetrics', package: const $pb.PackageName(_omitMessageNames ? '' : 'google.firestore.v1'), createEmptyInstance: create)
    ..aOM<PlanSummary>(1, _omitFieldNames ? '' : 'planSummary', subBuilder: PlanSummary.create)
    ..aOM<ExecutionStats>(2, _omitFieldNames ? '' : 'executionStats', subBuilder: ExecutionStats.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExplainMetrics clone() => ExplainMetrics()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExplainMetrics copyWith(void Function(ExplainMetrics) updates) => super.copyWith((message) => updates(message as ExplainMetrics)) as ExplainMetrics;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExplainMetrics create() => ExplainMetrics._();
  @$core.override
  ExplainMetrics createEmptyInstance() => create();
  static $pb.PbList<ExplainMetrics> createRepeated() => $pb.PbList<ExplainMetrics>();
  @$core.pragma('dart2js:noInline')
  static ExplainMetrics getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExplainMetrics>(create);
  static ExplainMetrics? _defaultInstance;

  /// Planning phase information for the query.
  @$pb.TagNumber(1)
  PlanSummary get planSummary => $_getN(0);
  @$pb.TagNumber(1)
  set planSummary(PlanSummary value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPlanSummary() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlanSummary() => $_clearField(1);
  @$pb.TagNumber(1)
  PlanSummary ensurePlanSummary() => $_ensure(0);

  /// Aggregated stats from the execution of the query. Only present when
  /// [ExplainOptions.analyze][google.firestore.v1.ExplainOptions.analyze] is set
  /// to true.
  @$pb.TagNumber(2)
  ExecutionStats get executionStats => $_getN(1);
  @$pb.TagNumber(2)
  set executionStats(ExecutionStats value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExecutionStats() => $_has(1);
  @$pb.TagNumber(2)
  void clearExecutionStats() => $_clearField(2);
  @$pb.TagNumber(2)
  ExecutionStats ensureExecutionStats() => $_ensure(1);
}

/// Planning phase information for the query.
class PlanSummary extends $pb.GeneratedMessage {
  factory PlanSummary({
    $core.Iterable<$8.Struct>? indexesUsed,
  }) {
    final result = create();
    if (indexesUsed != null) result.indexesUsed.addAll(indexesUsed);
    return result;
  }

  PlanSummary._();

  factory PlanSummary.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory PlanSummary.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PlanSummary', package: const $pb.PackageName(_omitMessageNames ? '' : 'google.firestore.v1'), createEmptyInstance: create)
    ..pc<$8.Struct>(1, _omitFieldNames ? '' : 'indexesUsed', $pb.PbFieldType.PM, subBuilder: $8.Struct.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlanSummary clone() => PlanSummary()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlanSummary copyWith(void Function(PlanSummary) updates) => super.copyWith((message) => updates(message as PlanSummary)) as PlanSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlanSummary create() => PlanSummary._();
  @$core.override
  PlanSummary createEmptyInstance() => create();
  static $pb.PbList<PlanSummary> createRepeated() => $pb.PbList<PlanSummary>();
  @$core.pragma('dart2js:noInline')
  static PlanSummary getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlanSummary>(create);
  static PlanSummary? _defaultInstance;

  /// The indexes selected for the query. For example:
  ///  [
  ///    {"query_scope": "Collection", "properties": "(foo ASC, __name__ ASC)"},
  ///    {"query_scope": "Collection", "properties": "(bar ASC, __name__ ASC)"}
  ///  ]
  @$pb.TagNumber(1)
  $pb.PbList<$8.Struct> get indexesUsed => $_getList(0);
}

/// Execution statistics for the query.
class ExecutionStats extends $pb.GeneratedMessage {
  factory ExecutionStats({
    $fixnum.Int64? resultsReturned,
    $4.Duration? executionDuration,
    $fixnum.Int64? readOperations,
    $8.Struct? debugStats,
  }) {
    final result = create();
    if (resultsReturned != null) result.resultsReturned = resultsReturned;
    if (executionDuration != null) result.executionDuration = executionDuration;
    if (readOperations != null) result.readOperations = readOperations;
    if (debugStats != null) result.debugStats = debugStats;
    return result;
  }

  ExecutionStats._();

  factory ExecutionStats.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory ExecutionStats.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExecutionStats', package: const $pb.PackageName(_omitMessageNames ? '' : 'google.firestore.v1'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'resultsReturned')
    ..aOM<$4.Duration>(3, _omitFieldNames ? '' : 'executionDuration', subBuilder: $4.Duration.create)
    ..aInt64(4, _omitFieldNames ? '' : 'readOperations')
    ..aOM<$8.Struct>(5, _omitFieldNames ? '' : 'debugStats', subBuilder: $8.Struct.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutionStats clone() => ExecutionStats()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecutionStats copyWith(void Function(ExecutionStats) updates) => super.copyWith((message) => updates(message as ExecutionStats)) as ExecutionStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExecutionStats create() => ExecutionStats._();
  @$core.override
  ExecutionStats createEmptyInstance() => create();
  static $pb.PbList<ExecutionStats> createRepeated() => $pb.PbList<ExecutionStats>();
  @$core.pragma('dart2js:noInline')
  static ExecutionStats getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExecutionStats>(create);
  static ExecutionStats? _defaultInstance;

  /// Total number of results returned, including documents, projections,
  /// aggregation results, keys.
  @$pb.TagNumber(1)
  $fixnum.Int64 get resultsReturned => $_getI64(0);
  @$pb.TagNumber(1)
  set resultsReturned($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasResultsReturned() => $_has(0);
  @$pb.TagNumber(1)
  void clearResultsReturned() => $_clearField(1);

  /// Total time to execute the query in the backend.
  @$pb.TagNumber(3)
  $4.Duration get executionDuration => $_getN(1);
  @$pb.TagNumber(3)
  set executionDuration($4.Duration value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasExecutionDuration() => $_has(1);
  @$pb.TagNumber(3)
  void clearExecutionDuration() => $_clearField(3);
  @$pb.TagNumber(3)
  $4.Duration ensureExecutionDuration() => $_ensure(1);

  /// Total billable read operations.
  @$pb.TagNumber(4)
  $fixnum.Int64 get readOperations => $_getI64(2);
  @$pb.TagNumber(4)
  set readOperations($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(4)
  $core.bool hasReadOperations() => $_has(2);
  @$pb.TagNumber(4)
  void clearReadOperations() => $_clearField(4);

  /// Debugging statistics from the execution of the query. Note that the
  /// debugging stats are subject to change as Firestore evolves. It could
  /// include:
  ///  {
  ///    "indexes_entries_scanned": "1000",
  ///    "documents_scanned": "20",
  ///    "billing_details" : {
  ///       "documents_billable": "20",
  ///       "index_entries_billable": "1000",
  ///       "min_query_cost": "0"
  ///    }
  ///  }
  @$pb.TagNumber(5)
  $8.Struct get debugStats => $_getN(3);
  @$pb.TagNumber(5)
  set debugStats($8.Struct value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDebugStats() => $_has(3);
  @$pb.TagNumber(5)
  void clearDebugStats() => $_clearField(5);
  @$pb.TagNumber(5)
  $8.Struct ensureDebugStats() => $_ensure(3);
}


const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
