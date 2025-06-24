import '../io_file.dart';

abstract class PosixMetadata implements Metadata {
  int get accessedTimeNanos;

  /// The time that the file system object was created in nanoseconds since the
  /// epoch.
  ///
  /// This will always be `null` on Android and Linux.
  ///
  /// The resolution of the creation time varies by platform and file system.
  int? get creationTimeNanos;

  /// The time that the file system object was last modified in nanoseconds
  /// since the epoch.
  ///
  /// The resolution of the modification time varies by platform and file
  /// system.
  int get modificationTimeNanos;
}

abstract class PosixFileSystem extends FileSystem {}
