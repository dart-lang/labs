// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'package:path/path.dart' as p;
import 'package:win32/win32.dart' as win32;

import 'exceptions.dart';
import 'file_system.dart';
import 'internal_constants.dart';

const _hundredsOfNanosecondsPerMicrosecond = 10;

DateTime _fileTimeToDateTime(int t) {
  final microseconds = t ~/ _hundredsOfNanosecondsPerMicrosecond;
  return DateTime.utc(1601, 1, 1, 0, 0, 0, 0, microseconds);
}

void _primeGetLastError() {
  // Calling `GetLastError` for the first time causes the `GetLastError`
  // symbol to be loaded, which resets `GetLastError`. So make a harmless
  // call before the value is needed.
  win32.GetLastError();
}

extension on Allocator {
  /// Duplicate a `LPCWSTR` into the [Allocator]'s memory pool.
  Pointer<Utf16> duplicateUtf16(Pointer<Utf16> str) {
    final wcharString = str.cast<WChar>();
    var length = 0;
    while (wcharString[length] != 0) {
      length++;
    }

    final duplicateString = this<WChar>(length + 1);
    for (var i = 0; i < length; ++i) {
      duplicateString[i] = wcharString[i];
    }
    duplicateString[length] = 0;
    return duplicateString.cast();
  }
}

/// Create a Windows `LPCWSTR` path from a Dart path, possibly with (`r'\\?\'`)
/// prepended.
///
/// Prepending a path with `r'\\?\'` "...tells the Windows APIs to disable all
/// string parsing and to send the string that follows it straight to the file
/// system." This has several effects (for full details, see
/// https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file):
/// - the 260 character limit on paths no longer applies
/// - files in the Win32 device namespace (e.g. "COM1" or named pipes) are not
///   visible
/// - special characters are no longer interpreted (e.g. "./foo" would refer to
///   a file with that literal name)
///
/// In order to allow paths longer than 260 character, while still allowing
/// virtual files to accessed, this function does not prepend `r'\\?\'` to UNC
/// paths (paths starting with `r'\\'`). This means that, to open "COM1", the
/// caller has to explicitly indicate that "COM1" is in the device namespace by
/// adding the `r'\\.\'` prefix, i.e. `r'\\.\COM1'`. Note that for named pipes
/// and serial communication ports greater than "COM9", the Windows API already
/// requires that the device namespace prefix be used.
///
/// In order to continue to allow special characters in paths, this function
/// converts the given path to an absolute path and then canonicalizes it before
/// prepending `r'\\?\'`.
Pointer<Utf16> _extendedPath(String path, Allocator allocator) {
  if (path.startsWith(r'\\')) {
    return path.toNativeUtf16(allocator: allocator);
  }

  // Optimistically assume that the full path will be only slightly longer than
  // the given path. If that turns out to not to be enough, we will get the
  // required size from `GetFullPathName` and try again.
  var length = path.length + 16;
  var utf16Path = path.toNativeUtf16(allocator: allocator);
  do {
    final buffer = win32.wsalloc(length);
    try {
      final result = win32.GetFullPathName(utf16Path, length, buffer, nullptr);
      if (result == 0) {
        final errorCode = win32.GetLastError();
        throw _getError(errorCode, systemCall: 'GetFullPathName', path1: path);
      }
      if (result < length) {
        final canonicalPath = allocator<Pointer<Utf16>>();
        win32.PathAllocCanonicalize(
          buffer,
          win32.PATHCCH_ENSURE_IS_EXTENDED_LENGTH_PATH,
          canonicalPath,
        );
        final dup = allocator.duplicateUtf16(canonicalPath.value);
        return dup;
      } else {
        length = result;
      }
    } finally {
      win32.free(buffer);
    }
  } while (true);
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

Exception _getError(
  int errorCode, {
  required String systemCall,
  String? path1,
  String? path2,
}) {
  final message = _formatMessage(errorCode);

  switch (errorCode) {
    case win32.ERROR_DIR_NOT_EMPTY:
      return DirectoryNotEmptyException(
        message,
        errorCode: errorCode,
        path1: path1,
        path2: path2,
        systemCall: systemCall,
      );
    case win32.ERROR_DISK_FULL:
      return DiskFullException(
        message,
        errorCode: errorCode,
        path1: path1,
        path2: path2,
        systemCall: systemCall,
      );
    case win32.ERROR_DIRECTORY:
      return NotADirectoryException(
        message,
        errorCode: errorCode,
        path1: path1,
        path2: path2,
        systemCall: systemCall,
      );
    case win32.ERROR_ACCESS_DENIED:
    case win32.ERROR_CURRENT_DIRECTORY:
    case win32.ERROR_WRITE_PROTECT:
    case win32.ERROR_BAD_LENGTH:
    case win32.ERROR_SHARING_VIOLATION:
    case win32.ERROR_LOCK_VIOLATION:
    case win32.ERROR_NETWORK_ACCESS_DENIED:
    case win32.ERROR_DRIVE_LOCKED:
      return PathAccessException(
        message,
        errorCode: errorCode,
        path1: path1,
        path2: path2,
        systemCall: systemCall,
      );
    case win32.ERROR_FILE_EXISTS:
    case win32.ERROR_ALREADY_EXISTS:
      return PathExistsException(
        message,
        errorCode: errorCode,
        path1: path1,
        path2: path2,
        systemCall: systemCall,
      );
    case win32.ERROR_FILE_NOT_FOUND:
    case win32.ERROR_PATH_NOT_FOUND:
    case win32.ERROR_INVALID_DRIVE:
    case win32.ERROR_INVALID_NAME:
    case win32.ERROR_NO_MORE_FILES:
    case win32.ERROR_BAD_NETPATH:
    case win32.ERROR_BAD_NET_NAME:
    case win32.ERROR_BAD_PATHNAME:
      return PathNotFoundException(
        message,
        errorCode: errorCode,
        path1: path1,
        path2: path2,
        systemCall: systemCall,
      );
    case win32.ERROR_TOO_MANY_OPEN_FILES:
      return TooManyOpenFilesException(
        message,
        errorCode: errorCode,
        path1: path1,
        path2: path2,
        systemCall: systemCall,
      );
    default:
      return IOFileException(
        message,
        errorCode: errorCode,
        path1: path1,
        path2: path2,
        systemCall: systemCall,
      );
  }
}

/// File system entity data available on Windows.
final class WindowsMetadata implements Metadata {
  // TODO(brianquinlan): Reoganize fields when the POSIX `metadata` is
  // available.
  // TODO(brianquinlan): Document the public fields.

  /// Will never have the `FILE_ATTRIBUTE_NORMAL` bit set.
  int _attributes;
  int _fileType;

  @override
  FileSystemType get type {
    if (isDirectory) {
      return FileSystemType.directory;
    }
    if (isLink) {
      return FileSystemType.link;
    }

    if (_fileType == win32.FILE_TYPE_CHAR) {
      return FileSystemType.character;
    }
    if (_fileType == win32.FILE_TYPE_DISK) {
      return FileSystemType.file;
    }
    if (_fileType == win32.FILE_TYPE_PIPE) {
      return FileSystemType.pipe;
    }
    return FileSystemType.unknown;
  }

  @override
  // On Windows, a reparse point that refers to a directory will have the
  // `FILE_ATTRIBUTE_DIRECTORY` attribute.
  bool get isDirectory =>
      _attributes & win32.FILE_ATTRIBUTE_DIRECTORY != 0 && !isLink;

  @override
  bool get isFile => type == FileSystemType.file;

  @override
  bool get isLink => _attributes & win32.FILE_ATTRIBUTE_REPARSE_POINT != 0;

  @override
  final int size;

  bool get isReadOnly => _attributes & win32.FILE_ATTRIBUTE_READONLY != 0;
  @override
  bool get isHidden => _attributes & win32.FILE_ATTRIBUTE_HIDDEN != 0;
  bool get isSystem => _attributes & win32.FILE_ATTRIBUTE_SYSTEM != 0;

  // TODO(brianquinlan): Refer to
  // https://learn.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/windows-scripting/5tx15443(v=vs.84)?redirectedfrom=MSDN
  bool get needsArchive => _attributes & win32.FILE_ATTRIBUTE_ARCHIVE != 0;
  bool get isTemporary => _attributes & win32.FILE_ATTRIBUTE_TEMPORARY != 0;
  bool get isOffline => _attributes & win32.FILE_ATTRIBUTE_OFFLINE != 0;
  bool get isContentIndexed =>
      _attributes & win32.FILE_ATTRIBUTE_NOT_CONTENT_INDEXED == 0;

  final int creationTime100Nanos;
  final int lastAccessTime100Nanos;
  final int lastWriteTime100Nanos;

  @override
  DateTime get access => _fileTimeToDateTime(lastAccessTime100Nanos);

  @override
  DateTime get creation => _fileTimeToDateTime(creationTime100Nanos);

  @override
  DateTime get modification => _fileTimeToDateTime(lastWriteTime100Nanos);

  WindowsMetadata._(
    this._attributes,
    this._fileType,
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
    int fileType = 0, // FILE_TYPE_UNKNOWN
    int size = 0,
    int creationTime100Nanos = 0,
    int lastAccessTime100Nanos = 0,
    int lastWriteTime100Nanos = 0,
  }) => WindowsMetadata._(
    attributes == win32.FILE_ATTRIBUTE_NORMAL ? 0 : attributes,
    fileType,
    size,
    creationTime100Nanos,
    lastAccessTime100Nanos,
    lastWriteTime100Nanos,
  );

  /// TODO(bquinlan): Document this constructor.
  factory WindowsMetadata.fromLogicalProperties({
    FileSystemType type = FileSystemType.unknown,

    int size = 0,

    bool isReadOnly = false,
    bool isHidden = false,
    bool isSystem = false,
    bool needsArchive = false,
    bool isTemporary = false,
    bool isOffline = false,
    bool isContentIndexed = false,

    int creationTime100Nanos = 0,
    int lastAccessTime100Nanos = 0,
    int lastWriteTime100Nanos = 0,
  }) => WindowsMetadata._(
    (type == FileSystemType.directory ? win32.FILE_ATTRIBUTE_DIRECTORY : 0) |
        (type == FileSystemType.link ? win32.FILE_ATTRIBUTE_REPARSE_POINT : 0) |
        (isReadOnly ? win32.FILE_ATTRIBUTE_READONLY : 0) |
        (isHidden ? win32.FILE_ATTRIBUTE_HIDDEN : 0) |
        (isSystem ? win32.FILE_ATTRIBUTE_SYSTEM : 0) |
        (needsArchive ? win32.FILE_ATTRIBUTE_ARCHIVE : 0) |
        (isTemporary ? win32.FILE_ATTRIBUTE_TEMPORARY : 0) |
        (isOffline ? win32.FILE_ATTRIBUTE_OFFLINE : 0) |
        (!isContentIndexed ? win32.FILE_ATTRIBUTE_NOT_CONTENT_INDEXED : 0),
    switch (type) {
      FileSystemType.character => win32.FILE_TYPE_CHAR,
      FileSystemType.file => win32.FILE_TYPE_DISK,
      FileSystemType.pipe => win32.FILE_TYPE_PIPE,
      _ => throw UnsupportedError('$type is not supoorted on Windows'),
    },
    size,
    creationTime100Nanos,
    lastAccessTime100Nanos,
    lastWriteTime100Nanos,
  );

  @override
  bool operator ==(Object other) =>
      other is WindowsMetadata &&
      _attributes == other._attributes &&
      _fileType == other._fileType &&
      size == other.size &&
      creationTime100Nanos == other.creationTime100Nanos &&
      lastAccessTime100Nanos == other.lastAccessTime100Nanos &&
      lastWriteTime100Nanos == other.lastWriteTime100Nanos;

  @override
  int get hashCode => Object.hash(
    _attributes,
    _fileType,
    size,
    isContentIndexed,
    creationTime100Nanos,
    lastAccessTime100Nanos,
    lastWriteTime100Nanos,
  );
}

/// A [FileSystem] implementation for Windows systems.
///
/// On Windows, paths refering to objects in the
/// [win32 device namespace](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file#win32-device-namespaces),
/// such as named pipes, physical disks, and serial comnmunications ports
/// (e.g. 'COM1'), must be prefixed with `r'\\.\'`. For example, `'NUL'` would
/// be refered to by the path `r'\\.\NUL'`.
final class WindowsFileSystem extends FileSystem {
  void _slowCopy(
    String oldPath,
    String newPath,
    int fromHandle,
    int toHandle,
    Allocator arena,
  ) {
    final buffer = arena<Uint8>(blockSize);
    final bytesRead = arena<win32.DWORD>();

    while (true) {
      if (win32.ReadFile(fromHandle, buffer, blockSize, bytesRead, nullptr) ==
          win32.FALSE) {
        final errorCode = win32.GetLastError();
        // On Windows, reading from a pipe that is closed by the writer results
        // in ERROR_BROKEN_PIPE.
        if (errorCode == win32.ERROR_BROKEN_PIPE ||
            errorCode == win32.ERROR_SUCCESS) {
          return;
        }
        throw _getError(errorCode, systemCall: 'ReadFile', path1: oldPath);
      }

      if (bytesRead.value == 0) {
        return;
      }

      var writeRemaining = bytesRead.value;
      var writeBuffer = buffer;
      final bytesWritten = arena<win32.DWORD>();
      while (writeRemaining > 0) {
        if (win32.WriteFile(
              toHandle,
              writeBuffer,
              writeRemaining,
              bytesWritten,
              nullptr,
            ) ==
            win32.FALSE) {
          final errorCode = win32.GetLastError();
          throw _getError(errorCode, systemCall: 'WriteFile', path1: newPath);
        }
        writeRemaining -= bytesWritten.value;
        writeBuffer += bytesWritten.value;
      }
    }
  }

  @override
  void copyFile(String oldPath, String newPath) => ffi.using((arena) {
    _primeGetLastError();

    final oldHandle = win32.CreateFile(
      _extendedPath(oldPath, arena),
      win32.GENERIC_READ | win32.FILE_SHARE_READ,
      win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE,
      nullptr,
      win32.OPEN_EXISTING,
      win32.FILE_ATTRIBUTE_NORMAL,
      0,
    );
    if (oldHandle == win32.INVALID_HANDLE_VALUE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, systemCall: 'CreateFile', path1: oldPath);
    }
    try {
      final newHandle = win32.CreateFile(
        _extendedPath(newPath, arena),
        win32.FILE_GENERIC_WRITE,
        0,
        nullptr,
        win32.CREATE_NEW,
        win32.FILE_ATTRIBUTE_NORMAL & win32.FILE_FLAG_OPEN_REPARSE_POINT,
        0,
      );
      if (newHandle == win32.INVALID_HANDLE_VALUE) {
        final errorCode = win32.GetLastError();
        throw _getError(errorCode, systemCall: 'CreateFile', path1: newPath);
      }
      try {
        _slowCopy(oldPath, newPath, oldHandle, newHandle, arena);
      } finally {
        win32.CloseHandle(newHandle);
      }
    } finally {
      win32.CloseHandle(oldHandle);
    }
  });

  @override
  void createDirectory(String path) => using((arena) {
    _primeGetLastError();

    if (win32.CreateDirectory(_extendedPath(path, arena), nullptr) ==
        win32.FALSE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, systemCall: 'CreateDirectory', path1: path);
    }
  });

  @override
  String createTemporaryDirectory({String? parent, String? prefix}) {
    _primeGetLastError();

    final suffix = win32.Guid.generate().toString();
    final directory = parent ?? temporaryDirectory;
    final path = p.join(directory, '${prefix ?? ''}$suffix');
    createDirectory(path);
    return path;
  }

  @override
  set currentDirectory(String path) => using((arena) {
    _primeGetLastError();

    if (win32.SetCurrentDirectory(path.toNativeUtf16()) == win32.FALSE) {
      final errorCode = win32.GetLastError();
      throw _getError(
        errorCode,
        systemCall: 'SetCurrentDirectory',
        path1: path,
      );
    }
  });

  @override
  String get currentDirectory => using((arena) {
    _primeGetLastError();

    var length = 256;
    do {
      final buffer = win32.wsalloc(length);
      try {
        final result = win32.GetCurrentDirectory(length, buffer);
        if (result < length) {
          return buffer.toDartString();
        } else {
          length = result;
        }
      } finally {
        win32.free(buffer);
      }
    } while (true);
  });

  @override
  WindowsMetadata metadata(String path) => using((arena) {
    _primeGetLastError();

    final pathUtf16 = _extendedPath(path, arena);
    final fileInfo = arena<win32.WIN32_FILE_ATTRIBUTE_DATA>();
    if (win32.GetFileAttributesEx(
          pathUtf16,
          win32.GetFileExInfoStandard,
          fileInfo,
        ) ==
        win32.FALSE) {
      final errorCode = win32.GetLastError();
      throw _getError(
        errorCode,
        systemCall: 'GetFileAttributesEx',
        path1: path,
      );
    }
    final info = fileInfo.ref;
    final attributes = info.dwFileAttributes;

    final h = win32.CreateFile(
      pathUtf16,
      0,
      win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE | win32.FILE_SHARE_DELETE,
      nullptr,
      win32.OPEN_EXISTING,
      win32.FILE_FLAG_BACKUP_SEMANTICS,
      win32.NULL,
    );
    final int fileType;
    if (h == win32.INVALID_HANDLE_VALUE) {
      // `CreateFile` may have modes incompatible with opening some file types.
      fileType = win32.FILE_TYPE_UNKNOWN;
    } else {
      try {
        // Returns `FILE_TYPE_UNKNOWN` on failure, which is what we want anyway.
        fileType = win32.GetFileType(h);
      } finally {
        win32.CloseHandle(h);
      }
    }
    return WindowsMetadata.fromFileAttributes(
      attributes: attributes,
      fileType: fileType,
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
  void removeDirectory(String path) => using((arena) {
    _primeGetLastError();

    if (win32.RemoveDirectory(_extendedPath(path, arena)) == win32.FALSE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, systemCall: 'RemoveDirectory', path1: path);
    }
  });

  @override
  void removeDirectoryTree(String path) => using((arena) {
    _primeGetLastError();

    path = _extendedPath(path, arena).toDartString();
    final findData = arena<win32.WIN32_FIND_DATA>();
    final searchPath = p.join(path, '*');

    final findHandle = win32.FindFirstFile(
      searchPath.toNativeUtf16(allocator: arena),
      findData,
    );

    if (findHandle == win32.INVALID_HANDLE_VALUE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, systemCall: 'FindFirstFile', path1: path);
    }

    do {
      final childPath = findData.ref.cFileName;
      if (childPath == '.' || childPath == '..') {
        continue;
      }

      final fullPath = p.join(path, childPath);
      final attributes = findData.ref.dwFileAttributes;

      if ((attributes & win32.FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
        // Do not recurse into directory links.
        if ((attributes & win32.FILE_ATTRIBUTE_DIRECTORY) != 0) {
          if (win32.RemoveDirectory(fullPath.toNativeUtf16(allocator: arena)) ==
              win32.FALSE) {
            final errorCode = win32.GetLastError();
            throw _getError(
              errorCode,
              systemCall: 'RemoveDirectory',
              path1: fullPath,
            );
          }
        } else {
          if (win32.DeleteFile(fullPath.toNativeUtf16(allocator: arena)) ==
              win32.FALSE) {
            final errorCode = win32.GetLastError();
            throw _getError(
              errorCode,
              systemCall: 'DeleteFile',
              path1: fullPath,
            );
          }
        }
      } else if ((attributes & win32.FILE_ATTRIBUTE_DIRECTORY) != 0) {
        removeDirectoryTree(fullPath);
      } else {
        if (win32.DeleteFile(fullPath.toNativeUtf16(allocator: arena)) ==
            win32.FALSE) {
          final errorCode = win32.GetLastError();
          throw _getError(errorCode, systemCall: 'DeleteFile', path1: fullPath);
        }
      }
    } while (win32.FindNextFile(findHandle, findData) != win32.FALSE);

    final errorCode = win32.GetLastError();
    if (errorCode != win32.ERROR_NO_MORE_FILES) {
      throw _getError(errorCode, systemCall: 'FindNextFile', path1: path);
    }

    if (win32.RemoveDirectory(path.toNativeUtf16(allocator: arena)) ==
        win32.FALSE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, systemCall: 'RemoveDirectory', path1: path);
    }
  });

  @override
  void removeFile(String path) => using((arena) {
    _primeGetLastError();

    if (win32.DeleteFile(_extendedPath(path, arena)) == win32.FALSE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, systemCall: 'DeleteFile', path1: path);
    }
  });

  @override
  Uint8List readAsBytes(String path) => using((arena) {
    _primeGetLastError();

    final f = win32.CreateFile(
      _extendedPath(path, arena),
      win32.GENERIC_READ | win32.FILE_SHARE_READ,
      win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE,
      nullptr,
      win32.OPEN_EXISTING,
      win32.FILE_ATTRIBUTE_NORMAL,
      0,
    );
    if (f == win32.INVALID_HANDLE_VALUE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, systemCall: 'CreateFile', path1: path);
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
        throw _getError(errorCode, systemCall: 'ReadFile', path1: path);
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
            throw _getError(errorCode, systemCall: 'ReadFile', path1: path);
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

  @override
  void rename(String oldPath, String newPath) => using((arena) {
    _primeGetLastError();

    if (win32.MoveFileEx(
          _extendedPath(oldPath, arena),
          _extendedPath(newPath, arena),
          win32.MOVEFILE_WRITE_THROUGH | win32.MOVEFILE_REPLACE_EXISTING,
        ) ==
        win32.FALSE) {
      final errorCode = win32.GetLastError();
      throw _getError(
        errorCode,
        systemCall: 'MoveFileEx',
        path1: oldPath,
        path2: newPath,
      );
    }
  });

  @override
  bool same(String path1, String path2) => using((arena) {
    // Calling `GetLastError` for the first time causes the `GetLastError`
    // symbol to be loaded, which resets `GetLastError`. So make a harmless
    // call before the value is needed.
    win32.GetLastError();

    final info1 = _byHandleFileInformation(path1, arena);
    final info2 = _byHandleFileInformation(path2, arena);

    return info1.dwVolumeSerialNumber == info2.dwVolumeSerialNumber &&
        info1.nFileIndexHigh == info2.nFileIndexHigh &&
        info1.nFileIndexLow == info2.nFileIndexLow;
  });

  // NOTE: the return value is allocated in the given arena!
  static win32.BY_HANDLE_FILE_INFORMATION _byHandleFileInformation(
    String path,
    ffi.Arena arena,
  ) {
    final h = win32.CreateFile(
      _extendedPath(path, arena),
      0,
      win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE | win32.FILE_SHARE_DELETE,
      nullptr,
      win32.OPEN_EXISTING,
      win32.FILE_FLAG_BACKUP_SEMANTICS,
      win32.NULL,
    );
    if (h == win32.INVALID_HANDLE_VALUE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, systemCall: 'CreateFile', path1: path);
    }
    try {
      final info = arena<win32.BY_HANDLE_FILE_INFORMATION>();
      if (win32.GetFileInformationByHandle(h, info) == win32.FALSE) {
        final errorCode = win32.GetLastError();
        throw _getError(
          errorCode,
          systemCall: 'GetFileInformationByHandle',
          path1: path,
        );
      }
      return info.ref;
    } finally {
      win32.CloseHandle(h);
    }
  }

  /// Sets metadata for the file system entity.
  ///
  /// TODO(brianquinlan): Document the arguments.
  ///
  /// Make sure to document that [original] should come from a call to
  /// `metadata`. Creating your own `WindowsMetadata` will result in unsupported
  /// fields being cleared.
  void setMetadata(
    String path, {
    bool? isReadOnly,
    bool? isHidden,
    bool? isSystem,
    bool? needsArchive,
    bool? isTemporary,
    bool? isContentIndexed,
    bool? isOffline,
    WindowsMetadata? original,
  }) => using((arena) {
    _primeGetLastError();

    if ((isReadOnly ??
            isHidden ??
            isSystem ??
            needsArchive ??
            isTemporary ??
            isContentIndexed ??
            isOffline) ==
        null) {
      return;
    }
    final fileInfo = arena<win32.WIN32_FILE_ATTRIBUTE_DATA>();
    final nativePath = _extendedPath(path, arena);
    int attributes;
    if (original == null) {
      if (win32.GetFileAttributesEx(
            nativePath,
            win32.GetFileExInfoStandard,
            fileInfo,
          ) ==
          win32.FALSE) {
        final errorCode = win32.GetLastError();
        throw _getError(
          errorCode,
          systemCall: 'GetFileAttributesEx',
          path1: path,
        );
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
    attributes = updateBit(
      attributes,
      win32.FILE_ATTRIBUTE_ARCHIVE,
      needsArchive,
    );
    attributes = updateBit(
      attributes,
      win32.FILE_ATTRIBUTE_TEMPORARY,
      isTemporary,
    );
    attributes = updateBit(
      attributes,
      win32.FILE_ATTRIBUTE_NOT_CONTENT_INDEXED,
      isContentIndexed != null ? !isContentIndexed : null,
    );
    attributes = updateBit(attributes, win32.FILE_ATTRIBUTE_OFFLINE, isOffline);
    if (attributes == 0) {
      // `FILE_ATTRIBUTE_NORMAL` indicates that no other attributes are set and
      // is valid only when used alone.
      attributes = win32.FILE_ATTRIBUTE_NORMAL;
    }
    if (win32.SetFileAttributes(nativePath, attributes) == win32.FALSE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, systemCall: 'SetFileAttributes', path1: path);
    }
  });

  @override
  String get temporaryDirectory {
    const maxLength = win32.MAX_PATH + 1;
    final buffer = win32.wsalloc(maxLength);
    try {
      final length = win32.GetTempPath2(maxLength, buffer);
      if (length == 0) {
        final errorCode = win32.GetLastError();
        throw _getError(errorCode, systemCall: 'GetTempPath2');
      }
      return p.canonicalize(buffer.toDartString());
    } finally {
      win32.free(buffer);
    }
  }

  @override
  void writeAsBytes(
    String path,
    Uint8List data, [
    WriteMode mode = WriteMode.failExisting,
  ]) => using((arena) {
    _primeGetLastError();

    var createFlags = 0;
    createFlags |= switch (mode) {
      WriteMode.appendExisting => win32.OPEN_ALWAYS,
      WriteMode.failExisting => win32.CREATE_NEW,
      WriteMode.truncateExisting => win32.CREATE_ALWAYS,
      _ => throw ArgumentError.value(mode, 'invalid write mode'),
    };

    final f = win32.CreateFile(
      _extendedPath(path, arena),
      mode == WriteMode.appendExisting
          ? win32.FILE_APPEND_DATA
          : win32.FILE_GENERIC_WRITE,
      0,
      nullptr,
      createFlags,
      win32.FILE_ATTRIBUTE_NORMAL,
      0,
    );
    if (f == win32.INVALID_HANDLE_VALUE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, systemCall: 'CreateFile', path1: path);
    }

    try {
      // TODO(brianquinlan): Remove this copy when typed data pointers are
      // available for non-leaf calls.
      var buffer = arena<Uint8>(data.length);
      buffer.asTypedList(data.length).setAll(0, data);
      final bytesWritten = arena<win32.DWORD>();
      var remaining = data.length;

      while (remaining > 0) {
        if (win32.WriteFile(
              f,
              buffer.cast(),
              min(maxWriteSize, remaining),
              bytesWritten,
              nullptr,
            ) ==
            win32.FALSE) {
          final errorCode = win32.GetLastError();
          throw _getError(errorCode, systemCall: 'WriteFile', path1: path);
        }

        remaining -= bytesWritten.value;
        buffer += bytesWritten.value;
      }
    } finally {
      win32.CloseHandle(f);
    }
  });

  @override
  void writeAsString(
    String path,
    String contents, [
    WriteMode mode = WriteMode.failExisting,
    Encoding encoding = utf8,
    String? lineTerminator,
  ]) {
    lineTerminator ??= '\r\n';
    final List<int> data;
    if (lineTerminator == '\n') {
      data = encoding.encode(contents);
    } else if (lineTerminator == '\r\n') {
      data = encoding.encode(contents.replaceAll('\n', '\r\n'));
    } else {
      throw ArgumentError.value(lineTerminator, 'lineTerminator');
    }
    writeAsBytes(
      path,
      data is Uint8List ? data : Uint8List.fromList(data),
      mode,
    );
  }
}
