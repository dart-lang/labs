// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'package:win32/win32.dart' as win32;

import 'file_system.dart';
import 'internal_constants.dart';

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

  /// Will never have the `FILE_ATTRIBUTE_NORMAL` bit set.
  int _attributes;

  @override
  bool get isDirectory => _attributes & win32.FILE_ATTRIBUTE_DIRECTORY != 0;

  @override
  bool get isFile => !isDirectory && !isLink;

  @override
  bool get isLink => _attributes & win32.FILE_ATTRIBUTE_REPARSE_POINT != 0;

  @override
  final int size;

  bool get isReadOnly => _attributes & win32.FILE_ATTRIBUTE_READONLY != 0;
  bool get isHidden => _attributes & win32.FILE_ATTRIBUTE_HIDDEN != 0;
  bool get isSystem => _attributes & win32.FILE_ATTRIBUTE_SYSTEM != 0;
  bool get isArchive => _attributes & win32.FILE_ATTRIBUTE_ARCHIVE != 0;
  bool get isTemporary => _attributes & win32.FILE_ATTRIBUTE_TEMPORARY != 0;
  bool get isOffline => _attributes & win32.FILE_ATTRIBUTE_OFFLINE != 0;
  bool get isContentNotIndexed =>
      _attributes & win32.FILE_ATTRIBUTE_NOT_CONTENT_INDEXED != 0;

  final int creationTime100Nanos;
  final int lastAccessTime100Nanos;
  final int lastWriteTime100Nanos;

  DateTime get creation => _fileTimeToDateTime(creationTime100Nanos);
  DateTime get access => _fileTimeToDateTime(lastAccessTime100Nanos);
  DateTime get modification => _fileTimeToDateTime(lastWriteTime100Nanos);

  WindowsMetadata._(
    this._attributes,
    this.size,
    this.creationTime100Nanos,
    this.lastAccessTime100Nanos,
    this.lastWriteTime100Nanos,
  );

  /// TODO(bquinlan): Document this constructor.
  ///
  /// Make sure to reference:
  /// [File Attribute Constants](https://learn.microsoft.com/en-us/windows/win32/fileio/file-attribute-constants)
  factory WindowsMetadata.fromFileAttributes({
    int attributes = 0,
    int size = 0,
    int creationTime100Nanos = 0,
    int lastAccessTime100Nanos = 0,
    int lastWriteTime100Nanos = 0,
  }) => WindowsMetadata._(
    attributes == win32.FILE_ATTRIBUTE_NORMAL ? 0 : attributes,
    size,
    creationTime100Nanos,
    lastAccessTime100Nanos,
    lastWriteTime100Nanos,
  );

  /// TODO(bquinlan): Document this constructor.
  factory WindowsMetadata.fromLogicalProperties({
    bool isDirectory = false,
    bool isLink = false,

    int size = 0,

    bool isReadOnly = false,
    bool isHidden = false,
    bool isSystem = false,
    bool isArchive = false,
    bool isTemporary = false,
    bool isOffline = false,
    bool isContentNotIndexed = false,

    int creationTime100Nanos = 0,
    int lastAccessTime100Nanos = 0,
    int lastWriteTime100Nanos = 0,
  }) => WindowsMetadata._(
    (isDirectory ? win32.FILE_ATTRIBUTE_DIRECTORY : 0) |
        (isLink ? win32.FILE_ATTRIBUTE_REPARSE_POINT : 0) |
        (isReadOnly ? win32.FILE_ATTRIBUTE_READONLY : 0) |
        (isHidden ? win32.FILE_ATTRIBUTE_HIDDEN : 0) |
        (isSystem ? win32.FILE_ATTRIBUTE_SYSTEM : 0) |
        (isArchive ? win32.FILE_ATTRIBUTE_ARCHIVE : 0) |
        (isTemporary ? win32.FILE_ATTRIBUTE_TEMPORARY : 0) |
        (isOffline ? win32.FILE_ATTRIBUTE_OFFLINE : 0) |
        (isContentNotIndexed ? win32.FILE_ATTRIBUTE_NOT_CONTENT_INDEXED : 0),
    size,
    creationTime100Nanos,
    lastAccessTime100Nanos,
    lastWriteTime100Nanos,
  );

  @override
  bool operator ==(Object other) =>
      other is WindowsMetadata &&
      _attributes == other._attributes &&
      size == other.size &&
      creationTime100Nanos == other.creationTime100Nanos &&
      lastAccessTime100Nanos == other.lastAccessTime100Nanos &&
      lastWriteTime100Nanos == other.lastWriteTime100Nanos;

  @override
  int get hashCode => Object.hash(
    _attributes,
    size,
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
  /// Make sure to document that [original] should come from a call to
  /// `metadata`. Creating your own `WindowsMetadata` will result in unsupported
  /// fields being cleared.
  void setMetadata(
    String path, {
    bool? isReadOnly,
    bool? isHidden,
    bool? isSystem,
    bool? isArchive,
    bool? isTemporary,
    bool? isContentNotIndexed,
    bool? isOffline,
    WindowsMetadata? original,
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
    int attributes;
    if (original == null) {
      if (win32.GetFileAttributesEx(
            nativePath,
            win32.GetFileExInfoStandard,
            fileInfo,
          ) ==
          win32.FALSE) {
        final errorCode = win32.GetLastError();
        throw _getError(errorCode, 'set metadata failed', path);
      }
      attributes = fileInfo.ref.dwFileAttributes;
    } else {
      attributes = original._attributes;
    }

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
    return WindowsMetadata.fromFileAttributes(
      attributes: attributes,
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

  @override
  Uint8List readAsBytes(String path) => using((arena) {
    // Calling `GetLastError` for the first time causes the `GetLastError`
    // symbol to be loaded, which resets `GetLastError`. So make a harmless
    // call before the value is needed.
    win32.GetLastError();

    final f = win32.CreateFile(
      path.toNativeUtf16(),
      win32.GENERIC_READ | win32.FILE_SHARE_READ,
      win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE,
      nullptr,
      win32.OPEN_EXISTING,
      win32.FILE_ATTRIBUTE_NORMAL,
      0,
    );
    if (f == win32.INVALID_HANDLE_VALUE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, 'open failed', path);
    }
    try {
      // The result of `GetFileSize` is not defined for non-seeking devices
      // such as pipes.
      if (win32.GetFileType(f) == win32.FILE_TYPE_DISK) {
        final highFileSize = arena<win32.DWORD>();
        final lowFileSize = win32.GetFileSize(f, highFileSize);
        if (lowFileSize == 0xffffffff) {
          // Indicates an error OR that the low order word of the is actually
          // that constant.
          final errorCode = win32.GetLastError();
          if (errorCode != win32.ERROR_SUCCESS) {
            return _readUnknownLength(path, f);
          }
        }
        final fileSize = highFileSize.value << 32 | lowFileSize;
        if (fileSize == 0) {
          return Uint8List(0);
        } else {
          return _readKnownLength(path, f, fileSize);
        }
      }
      return _readUnknownLength(path, f);
    } finally {
      win32.CloseHandle(f);
    }
  });

  Uint8List _readUnknownLength(String path, int file) => ffi.using((arena) {
    final buffer = arena<Uint8>(blockSize);
    final bytesRead = arena<win32.DWORD>();
    final builder = BytesBuilder(copy: true);

    while (true) {
      if (win32.ReadFile(file, buffer, blockSize, bytesRead, nullptr) ==
          win32.FALSE) {
        final errorCode = win32.GetLastError();
        // On Windows, reading from a pipe that is closed by the writer results
        // in ERROR_BROKEN_PIPE.
        if (errorCode == win32.ERROR_BROKEN_PIPE ||
            errorCode == win32.ERROR_SUCCESS) {
          return builder.takeBytes();
        }
        throw _getError(errorCode, 'read failed', path);
      }

      if (bytesRead.value == 0) {
        return builder.takeBytes();
      } else {
        final typed = buffer.asTypedList(bytesRead.value);
        builder.add(typed);
      }
    }
  });

  Uint8List _readKnownLength(String path, int file, int length) {
    // In the happy path, `buffer` will be returned to the caller as a
    // `Uint8List`. If there in an exception, free it and rethrow the exception.
    final buffer = ffi.malloc<Uint8>(length);
    try {
      return ffi.using((arena) {
        final bytesRead = arena<win32.DWORD>();
        var bufferOffset = 0;

        while (bufferOffset < length) {
          if (win32.ReadFile(
                file,
                (buffer + bufferOffset).cast(),
                min(length - bufferOffset, maxReadSize),
                bytesRead,
                nullptr,
              ) ==
              win32.FALSE) {
            final errorCode = win32.GetLastError();
            throw _getError(errorCode, 'read failed', path);
          }
          bufferOffset += bytesRead.value;
          if (bytesRead.value == 0) {
            break;
          }
        }
        return buffer.asTypedList(
          bufferOffset,
          finalizer: ffi.malloc.nativeFree,
        );
      });
    } on Exception {
      ffi.malloc.free(buffer);
      rethrow;
    }
  }
}
