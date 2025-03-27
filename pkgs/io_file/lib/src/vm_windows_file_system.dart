// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io' as io;

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win32;

import 'file_system.dart';

const _hundredsOfNanosecondsPerMicrosecond = 10;

DateTime _fileTimeToDateTime(int t) {
  final microseconds = t ~/ _hundredsOfNanosecondsPerMicrosecond;
  return DateTime.utc(1601, 1, 1, 0, 0, 0, 0, microseconds);
}

String _formatMessage(int errorCode) {
  final buffer = win32.wsalloc(1024);
  try {
    final result = win32.FormatMessage(
      win32.FORMAT_MESSAGE_FROM_SYSTEM | win32.FORMAT_MESSAGE_IGNORE_INSERTS,
      nullptr,
      errorCode,
      0, // default language
      buffer,
      1024,
      nullptr,
    );
    if (result == 0) {
      return '';
    } else {
      return buffer.toDartString();
    }
  } finally {
    win32.free(buffer);
  }
}

Exception _getError(int errorCode, String message, String path) {
  final osError = io.OSError(_formatMessage(errorCode), errorCode);

  switch (errorCode) {
    case win32.ERROR_ACCESS_DENIED:
    case win32.ERROR_CURRENT_DIRECTORY:
    case win32.ERROR_WRITE_PROTECT:
    case win32.ERROR_BAD_LENGTH:
    case win32.ERROR_SHARING_VIOLATION:
    case win32.ERROR_LOCK_VIOLATION:
    case win32.ERROR_NETWORK_ACCESS_DENIED:
    case win32.ERROR_DRIVE_LOCKED:
      return io.PathAccessException(path, osError, message);
    case win32.ERROR_FILE_EXISTS:
    case win32.ERROR_ALREADY_EXISTS:
      return io.PathExistsException(path, osError, message);
    case win32.ERROR_FILE_NOT_FOUND:
    case win32.ERROR_PATH_NOT_FOUND:
    case win32.ERROR_INVALID_DRIVE:
    case win32.ERROR_INVALID_NAME:
    case win32.ERROR_NO_MORE_FILES:
    case win32.ERROR_BAD_NETPATH:
    case win32.ERROR_BAD_NET_NAME:
    case win32.ERROR_BAD_PATHNAME:
      return io.PathNotFoundException(path, osError, message);
    default:
      return io.FileSystemException(message, path, osError);
  }
}

/// File system entity data available on Windows.
final class WindowsMetadata implements Metadata {
  // TODO(brianquinlan): Reoganize fields when the POSIX `metadata` is
  // available.
  // TODO(brianquinlan): Document the public fields.

  @override
  final bool isDirectory;

  @override
  final bool isFile;

  @override
  final bool isLink;

  @override
  final int size;

  final bool isReadOnly;
  final bool isHidden;
  final bool isSystem;
  final bool isArchive;
  final bool isTemporary;
  final bool isOffline;
  final bool isContentNotIndexed;

  final int creationTime100Nanos;
  final int lastAccessTime100Nanos;
  final int lastWriteTime100Nanos;

  DateTime get creation => _fileTimeToDateTime(creationTime100Nanos);
  DateTime get access => _fileTimeToDateTime(lastAccessTime100Nanos);
  DateTime get modification => _fileTimeToDateTime(lastWriteTime100Nanos);

  /// TODO(bquinlan): Document this constructor.
  WindowsMetadata({
    this.isDirectory = false,
    this.isFile = false,
    this.isLink = false,

    this.size = 0,

    this.isReadOnly = false,
    this.isHidden = false,
    this.isSystem = false,
    this.isArchive = false,
    this.isTemporary = false,
    this.isOffline = false,
    this.isContentNotIndexed = false,

    this.creationTime100Nanos = 0,
    this.lastAccessTime100Nanos = 0,
    this.lastWriteTime100Nanos = 0,
  });

  @override
  bool operator ==(Object other) =>
      other is WindowsMetadata &&
      isDirectory == other.isDirectory &&
      isFile == other.isFile &&
      isLink == other.isLink &&
      size == other.size &&
      isReadOnly == other.isReadOnly &&
      isHidden == other.isHidden &&
      isSystem == other.isSystem &&
      isArchive == other.isArchive &&
      isTemporary == other.isTemporary &&
      isOffline == other.isOffline &&
      isContentNotIndexed == other.isContentNotIndexed &&
      creationTime100Nanos == other.creationTime100Nanos &&
      lastAccessTime100Nanos == other.lastAccessTime100Nanos &&
      lastWriteTime100Nanos == other.lastWriteTime100Nanos;

  @override
  int get hashCode => Object.hash(
    isDirectory,
    isFile,
    isLink,
    size,
    isReadOnly,
    isHidden,
    isSystem,
    isArchive,
    isTemporary,
    isOffline,
    isContentNotIndexed,
    creationTime100Nanos,
    lastAccessTime100Nanos,
    lastWriteTime100Nanos,
  );
}

/// A [FileSystem] implementation for Windows systems.
base class WindowsFileSystem extends FileSystem {
  WindowsFileSystem() {
    // Calling `GetLastError` for the first time causes the `GetLastError`
    // symbol to be loaded, which resets `GetLastError`. So make a harmless
    // call before the value is needed.
    //
    // TODO(brianquinlan): Remove this after it is fixed in the Dart SDK.
    win32.GetLastError();
  }

  @override
  void rename(String oldPath, String newPath) => using((arena) {
    if (win32.MoveFileEx(
          oldPath.toNativeUtf16(allocator: arena),
          newPath.toNativeUtf16(allocator: arena),
          win32.MOVEFILE_WRITE_THROUGH | win32.MOVEFILE_REPLACE_EXISTING,
        ) ==
        win32.FALSE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, 'rename failed', oldPath);
    }
  });

  /// Sets metadata for the file system entity.
  ///
  /// TODO(brianquinlan): Document the arguments.
  void setMetadata(
    String path, {
    bool? isReadOnly,
    bool? isHidden,
    bool? isSystem,
    bool? isArchive,
    bool? isTemporary,
    bool? isContentNotIndexed,
    bool? isOffline,
  }) => using((arena) {
    if ((isReadOnly ??
            isHidden ??
            isSystem ??
            isArchive ??
            isTemporary ??
            isContentNotIndexed ??
            isOffline) ==
        null) {
      return;
    }
    final fileInfo = arena<win32.WIN32_FILE_ATTRIBUTE_DATA>();
    final nativePath = path.toNativeUtf16(allocator: arena);
    if (win32.GetFileAttributesEx(
          nativePath,
          win32.GetFileExInfoStandard,
          fileInfo,
        ) ==
        win32.FALSE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, 'set metadata failed', path);
    }

    var attributes = fileInfo.ref.dwFileAttributes;
    if (attributes == win32.FILE_ATTRIBUTE_NORMAL) {
      // `FILE_ATTRIBUTE_NORMAL` indicates that no other attributes are set and
      // is valid only when used alone.
      attributes = 0;
    }

    int updateBit(int base, int value, bool? bit) => switch (bit) {
      null => base,
      true => base | value,
      false => base & ~value,
    };

    attributes = updateBit(
      attributes,
      win32.FILE_ATTRIBUTE_READONLY,
      isReadOnly,
    );
    attributes = updateBit(attributes, win32.FILE_ATTRIBUTE_HIDDEN, isHidden);
    attributes = updateBit(attributes, win32.FILE_ATTRIBUTE_SYSTEM, isSystem);
    attributes = updateBit(attributes, win32.FILE_ATTRIBUTE_ARCHIVE, isArchive);
    attributes = updateBit(
      attributes,
      win32.FILE_ATTRIBUTE_TEMPORARY,
      isTemporary,
    );
    attributes = updateBit(
      attributes,
      win32.FILE_ATTRIBUTE_NOT_CONTENT_INDEXED,
      isContentNotIndexed,
    );
    attributes = updateBit(attributes, win32.FILE_ATTRIBUTE_OFFLINE, isOffline);
    if (attributes == 0) {
      // `FILE_ATTRIBUTE_NORMAL` indicates that no other attributes are set and
      // is valid only when used alone.
      attributes = win32.FILE_ATTRIBUTE_NORMAL;
    }
    if (win32.SetFileAttributes(nativePath, attributes) == win32.FALSE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, 'set metadata failed', path);
    }
  });

  @override
  WindowsMetadata metadata(String path) => using((arena) {
    final fileInfo = arena<win32.WIN32_FILE_ATTRIBUTE_DATA>();
    if (win32.GetFileAttributesEx(
          path.toNativeUtf16(allocator: arena),
          win32.GetFileExInfoStandard,
          fileInfo,
        ) ==
        win32.FALSE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, 'metadata failed', path);
    }
    final info = fileInfo.ref;
    final attributes = info.dwFileAttributes;

    final isDirectory = attributes & win32.FILE_ATTRIBUTE_DIRECTORY != 0;
    final isLink = attributes & win32.FILE_ATTRIBUTE_REPARSE_POINT != 0;
    final isFile = !(isDirectory || isLink);

    return WindowsMetadata(
      isReadOnly: attributes & win32.FILE_ATTRIBUTE_READONLY != 0,
      isHidden: attributes & win32.FILE_ATTRIBUTE_HIDDEN != 0,
      isSystem: attributes & win32.FILE_ATTRIBUTE_SYSTEM != 0,
      isDirectory: isDirectory,
      isArchive: attributes & win32.FILE_ATTRIBUTE_ARCHIVE != 0,
      isTemporary: attributes & win32.FILE_ATTRIBUTE_TEMPORARY != 0,
      isLink: isLink,
      isFile: isFile,
      isOffline: attributes & win32.FILE_ATTRIBUTE_OFFLINE != 0,
      isContentNotIndexed:
          attributes & win32.FILE_ATTRIBUTE_NOT_CONTENT_INDEXED != 0,

      size: info.nFileSizeHigh << 32 | info.nFileSizeLow,
      creationTime100Nanos:
          info.ftCreationTime.dwHighDateTime << 32 |
          info.ftCreationTime.dwLowDateTime,
      lastAccessTime100Nanos:
          info.ftLastAccessTime.dwHighDateTime << 32 |
          info.ftLastAccessTime.dwLowDateTime,
      lastWriteTime100Nanos:
          info.ftLastWriteTime.dwHighDateTime << 32 |
          info.ftLastWriteTime.dwLowDateTime,
    );
  });
}
