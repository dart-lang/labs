///
//  Generated code. Do not modify.
//  source: google/ads/googleads/v1/services/feed_item_service.proto
///
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name

import 'dart:async' as $async;

import 'package:grpc/service_api.dart' as $grpc;

import 'dart:core' as $core show int, String, List;

import 'feed_item_service.pb.dart';
import '../resources/feed_item.pb.dart' as $0;
export 'feed_item_service.pb.dart';

class FeedItemServiceClient extends $grpc.Client {
  static final _$getFeedItem =
      $grpc.ClientMethod<GetFeedItemRequest, $0.FeedItem>(
          '/google.ads.googleads.v1.services.FeedItemService/GetFeedItem',
          (GetFeedItemRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.FeedItem.fromBuffer(value));
  static final _$mutateFeedItems =
      $grpc.ClientMethod<MutateFeedItemsRequest, MutateFeedItemsResponse>(
          '/google.ads.googleads.v1.services.FeedItemService/MutateFeedItems',
          (MutateFeedItemsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              MutateFeedItemsResponse.fromBuffer(value));

  FeedItemServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions options})
      : super(channel, options: options);

  $grpc.ResponseFuture<$0.FeedItem> getFeedItem(GetFeedItemRequest request,
      {$grpc.CallOptions options}) {
    final call = $createCall(
        _$getFeedItem, $async.Stream.fromIterable([request]),
        options: options);
    return $grpc.ResponseFuture(call);
  }

  $grpc.ResponseFuture<MutateFeedItemsResponse> mutateFeedItems(
      MutateFeedItemsRequest request,
      {$grpc.CallOptions options}) {
    final call = $createCall(
        _$mutateFeedItems, $async.Stream.fromIterable([request]),
        options: options);
    return $grpc.ResponseFuture(call);
  }
}

abstract class FeedItemServiceBase extends $grpc.Service {
  $core.String get $name => 'google.ads.googleads.v1.services.FeedItemService';

  FeedItemServiceBase() {
    $addMethod($grpc.ServiceMethod<GetFeedItemRequest, $0.FeedItem>(
        'GetFeedItem',
        getFeedItem_Pre,
        false,
        false,
        ($core.List<$core.int> value) => GetFeedItemRequest.fromBuffer(value),
        ($0.FeedItem value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<MutateFeedItemsRequest, MutateFeedItemsResponse>(
            'MutateFeedItems',
            mutateFeedItems_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                MutateFeedItemsRequest.fromBuffer(value),
            (MutateFeedItemsResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.FeedItem> getFeedItem_Pre(
      $grpc.ServiceCall call, $async.Future request) async {
    return getFeedItem(call, await request);
  }

  $async.Future<MutateFeedItemsResponse> mutateFeedItems_Pre(
      $grpc.ServiceCall call, $async.Future request) async {
    return mutateFeedItems(call, await request);
  }

  $async.Future<$0.FeedItem> getFeedItem(
      $grpc.ServiceCall call, GetFeedItemRequest request);
  $async.Future<MutateFeedItemsResponse> mutateFeedItems(
      $grpc.ServiceCall call, MutateFeedItemsRequest request);
}
