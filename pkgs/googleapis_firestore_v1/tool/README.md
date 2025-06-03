## Re-generating the gRPC library

To re-generate the gRPC library, run:

```bash
dart tool/generate.dart
```

Any updates will appear in `lib/`.

## Updating the source protos

To update the Firestore API protos with the most recent versions, run:

```bash
dart tool/update_protos.dart
```

Any updates will appear in `protos/`.

You will then want to re-generate the gRPC library.
