// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'package:path/path.dart' as p;
import 'package:win32/win32.dart' as win32;

import 'file_system.dart';
import 'internal_constants.dart';

void _primeGetLastError() {
  // Calling `GetLastError` for the first time causes the `GetLastError`
  // symbol to be loaded, which resets `GetLastError`. So make a harmless
  // call before the value is needed.
  win32.GetLastError();
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

  @override
  void deleteDirectoryRecursively(String path) => using((arena) {
    _primeGetLastError();

    // Allocate WIN32_FIND_DATAW structure.
    final findData = arena<win32.WIN32_FIND_DATAW>();
    // Construct search pattern (path\*).
    final searchPath = p.join(path, '*').toNativeUtf16(allocator: arena);

    final findHandle = win32.FindFirstFileW(searchPath, findData);

    if (findHandle == win32.INVALID_HANDLE_VALUE) {
      final errorCode = win32.GetLastError();
      // If the directory doesn't exist, it's not an error.
      if (errorCode == win32.ERROR_FILE_NOT_FOUND ||
          errorCode == win32.ERROR_PATH_NOT_FOUND) {
        return;
      }
      throw _getError(errorCode, 'FindFirstFileW failed', path);
    }

    try {
      do {
        final fileName = findData.ref.cFileName.toDartString();
        if (fileName == '.' || fileName == '..') {
          continue;
        }

        final fullPath = p.join(path, fileName);
        final fullPathNative = fullPath.toNativeUtf16(allocator: arena);
        final attributes = findData.ref.dwFileAttributes;

        if (attributes & win32.FILE_ATTRIBUTE_REPARSE_POINT != 0) {
          // It's a junction or symlink. Delete the link itself, not the target.
          if (attributes & win32.FILE_ATTRIBUTE_DIRECTORY != 0) {
            // Directory symlink or junction
            if (win32.RemoveDirectoryW(fullPathNative) == win32.FALSE) {
              final errorCode = win32.GetLastError();
              throw _getError(errorCode, 'RemoveDirectoryW failed for link', fullPath);
            }
          } else {
            // File symlink
            if (win32.DeleteFileW(fullPathNative) == win32.FALSE) {
              final errorCode = win32.GetLastError();
              throw _getError(errorCode, 'DeleteFileW failed for link', fullPath);
            }
          }
        } else if (attributes & win32.FILE_ATTRIBUTE_DIRECTORY != 0) {
          // It's a regular directory, recurse.
          // Need to release arena memory before recursing if using `using`.
          // Let's manually manage memory for the recursive call path.
          arena.releaseAll(); // Release before recursion
          deleteDirectoryRecursively(fullPath); // Recursive call
        } else {
          // It's a file.
          if (win32.DeleteFileW(fullPathNative) == win32.FALSE) {
            final errorCode = win32.GetLastError();
            throw _getError(errorCode, 'DeleteFileW failed', fullPath);
          }
        }
      } while (win32.FindNextFileW(findHandle, findData) != win32.FALSE);

      final findNextErrorCode = win32.GetLastError();
      if (findNextErrorCode != win32.ERROR_NO_MORE_FILES) {
        throw _getError(findNextErrorCode, 'FindNextFileW failed', path);
      }
    } finally {
      win32.FindClose(findHandle);
    }

    // After deleting contents, remove the directory itself.
    if (win32.RemoveDirectoryW(path.toNativeUtf16(allocator: arena)) ==
        win32.FALSE) {
      final errorCode = win32.GetLastError();
      // Check if the directory is already gone (e.g., race condition or initial check failed)
      if (errorCode != win32.ERROR_FILE_NOT_FOUND &&
          errorCode != win32.ERROR_PATH_NOT_FOUND) {
         throw _getError(errorCode, 'RemoveDirectoryW failed', path);
      }
    }
  });
}

Exception _getError(int errorCode, String message, [String? path]) {
  final osError = io.OSError(_formatMessage(errorCode), errorCode);

  if (path != null) {
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
  } else {
    return io.FileSystemException(message, path, osError);
  }
}

/// A [FileSystem] implementation for Windows systems.
base class WindowsFileSystem extends FileSystem {
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
      path.toNativeUtf16(allocator: arena),
      0,
      win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE | win32.FILE_SHARE_DELETE,
      nullptr,
      win32.OPEN_EXISTING,
      win32.FILE_FLAG_BACKUP_SEMANTICS,
      win32.NULL,
    );
    if (h == win32.INVALID_HANDLE_VALUE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, 'CreateFile failed', path);
    }
    try {
      final info = arena<win32.BY_HANDLE_FILE_INFORMATION>();
      if (win32.GetFileInformationByHandle(h, info) == win32.FALSE) {
        final errorCode = win32.GetLastError();
        throw _getError(errorCode, 'GetFileInformationByHandle failed', path);
      }
      return info.ref;
    } finally {
      win32.CloseHandle(h);
    }
  }

  @override
  void createDirectory(String path) => using((arena) {
    _primeGetLastError();

    if (win32.CreateDirectory(path.toNativeUtf16(allocator: arena), nullptr) ==
        win32.FALSE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, 'create directory failed', path);
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
  void removeDirectory(String path) => using((arena) {
    _primeGetLastError();

    if (win32.RemoveDirectory(path.toNativeUtf16(allocator: arena)) ==
        win32.FALSE) {
      final errorCode = win32.GetLastError();
      throw _getError(errorCode, 'remove directory failed', path);
    }
  });

  @override
  void rename(String oldPath, String newPath) => using((arena) {
    _primeGetLastError();

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

  @override
  Uint8List readAsBytes(String path) => using((arena) {
    _primeGetLastError();

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

  @override
  String get temporaryDirectory {
    const maxLength = win32.MAX_PATH + 1;
    final buffer = win32.wsalloc(maxLength);
    try {
      final length = win32.GetTempPath2(maxLength, buffer);
      if (length == 0) {
        final errorCode = win32.GetLastError();
        throw _getError(errorCode, 'GetTempPath failed');
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
      path.toNativeUtf16(allocator: arena),
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
      throw _getError(errorCode, 'open failed', path);
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
          throw _getError(errorCode, 'write failed', path);
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

  @override
  void deleteDirectoryRecursively(String path) {
    _primeGetLastError();

    // Allocate necessary native resources.
    final findData = calloc<win32.WIN32_FIND_DATAW>();
    // Construct search pattern (path\*).
    final searchPath = p.join(path, '*').toNativeUtf16();

    try {
      final findHandle = win32.FindFirstFileW(searchPath, findData);

      if (findHandle == win32.INVALID_HANDLE_VALUE) {
        final errorCode = win32.GetLastError();
        // If the directory doesn't exist, it's not an error for deletion.
        if (errorCode == win32.ERROR_FILE_NOT_FOUND ||
            errorCode == win32.ERROR_PATH_NOT_FOUND) {
          return; // Successfully "deleted" non-existent directory.
        }
        // Otherwise, it's an unexpected error finding the first file/directory.
        throw _getError(errorCode, 'FindFirstFileW failed', path);
      }

      // Ensure FindClose is called even if errors occur during iteration.
      try {
        do {
          final fileName = findData.ref.cFileName.toDartString();
          // Skip '.' and '..' entries.
          if (fileName == '.' || fileName == '..') {
            continue;
          }

          final fullPath = p.join(path, fileName);
          final attributes = findData.ref.dwFileAttributes;
          // Allocate native string for the full path of the current item.
          final fullPathNative = fullPath.toNativeUtf16();

          bool recursed = false; // Flag to track if recursion happened
          try {
            if ((attributes & win32.FILE_ATTRIBUTE_REPARSE_POINT) != 0) {
              // Handle reparse points (symlinks/junctions). Delete the link itself.
              if ((attributes & win32.FILE_ATTRIBUTE_DIRECTORY) != 0) {
                // Directory symlink or junction.
                if (win32.RemoveDirectoryW(fullPathNative) == win32.FALSE) {
                  final errorCode = win32.GetLastError();
                  throw _getError(
                      errorCode, 'RemoveDirectoryW failed for link', fullPath);
                }
              } else {
                // File symlink.
                if (win32.DeleteFileW(fullPathNative) == win32.FALSE) {
                  final errorCode = win32.GetLastError();
                  throw _getError(
                      errorCode, 'DeleteFileW failed for link', fullPath);
                }
              }
            } else if ((attributes & win32.FILE_ATTRIBUTE_DIRECTORY) != 0) {
              // It's a regular directory, recurse.
              // Free the native path string *before* the recursive call.
              calloc.free(fullPathNative);
              recursed = true; // Set flag before recursion
              // Recursive call.
              deleteDirectoryRecursively(fullPath);
            } else {
              // It's a regular file.
              if (win32.DeleteFileW(fullPathNative) == win32.FALSE) {
                final errorCode = win32.GetLastError();
                throw _getError(errorCode, 'DeleteFileW failed', fullPath);
              }
            }
          } finally {
            // Free the native path string unless recursion happened.
            if (!recursed) {
              calloc.free(fullPathNative);
            }
          }
        } while (win32.FindNextFileW(findHandle, findData) != win32.FALSE);

        // Check for errors after the loop finishes.
        final findNextErrorCode = win32.GetLastError();
        if (findNextErrorCode != win32.ERROR_NO_MORE_FILES) {
          throw _getError(findNextErrorCode, 'FindNextFileW failed', path);
        }
      } finally {
        // Close the find handle.
        win32.FindClose(findHandle);
      }

      // After successfully deleting contents, remove the directory itself.
      final pathNative = path.toNativeUtf16();
      try {
        if (win32.RemoveDirectoryW(pathNative) == win32.FALSE) {
          final errorCode = win32.GetLastError();
          // Ignore errors if the directory is already gone.
          if (errorCode != win32.ERROR_FILE_NOT_FOUND &&
              errorCode != win32.ERROR_PATH_NOT_FOUND) {
            throw _getError(errorCode, 'RemoveDirectoryW failed', path);
          }
        }
      } finally {
        calloc.free(pathNative);
      }
    } finally {
      // Free the initial native allocations.
      calloc.free(findData);
      calloc.free(searchPath);
    }
  }
}
