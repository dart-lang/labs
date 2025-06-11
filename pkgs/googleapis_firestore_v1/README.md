An experimental gRPC client for the Cloud Firestore API.

## About

Cloud Firestore is a fast, fully managed, serverless, cloud-native NoSQL
document database that simplifies storing, syncing, and querying data for
your mobile, web, and IoT apps at global scale. Its client libraries provide
live synchronization and offline support, while its security features and
integrations with Firebase and Google Cloud Platform accelerate building
truly serverless apps.

See also:

- https://firebase.google.com/docs/firestore
- https://cloud.google.com/firestore/native/docs/apis

This package is a generated gRPC client used to access the Firestore API.

## Example

See below for a hello-world example. For a more complete example, including
use of `firestore.listen()`, see
https://github.com/dart-lang/labs/blob/main/pkgs/googleapis_firestore_v1/example/example.dart.

```dart
import 'package:googleapis_firestore_v1/google/firestore/v1/firestore.pbgrpc.dart';
import 'package:grpc/grpc.dart' as grpc;

void main(List<String> args) async {
  final projectId = args[0];

  // set up a connection
  final channel = grpc.ClientChannel(FirestoreClient.defaultHost);
  final auth = await grpc.applicationDefaultCredentialsAuthenticator(
    FirestoreClient.oauthScopes,
  );
  final firestore = FirestoreClient(channel, options: auth.toCallOptions);

  // make a request
  final request = ListCollectionIdsRequest(
    parent: 'projects/$projectId/databases/(default)/documents',
  );
  final result = await firestore.listCollectionIds(request);
  print('collectionIds:');
  for (var collectionId in result.collectionIds) {
    print('- $collectionId');
  }

  // close the channel
  await channel.shutdown();
}
```

## Status: Experimental

**NOTE**: This package is currently experimental and published under the
[labs.dart.dev](https://dart.dev/dart-team-packages) pub publisher in order to
solicit feedback. 

For packages in the labs.dart.dev publisher we generally plan to either graduate
the package into a supported publisher (dart.dev, tools.dart.dev) after a period
of feedback and iteration, or discontinue the package. These packages have a
much higher expected rate of API and breaking changes.

Your feedback is valuable and will help us evolve this package. For general
feedback, suggestions, and comments, please file an issue in the 
[bug tracker](https://github.com/dart-lang/labs/issues).
