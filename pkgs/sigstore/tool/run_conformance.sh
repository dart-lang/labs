#!/usr/bin/env bash
# Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "==> Resolving dependencies..."
dart pub get

echo "==> Compiling Sigstore conformance CLI..."
dart compile exe bin/conformance.dart -o bin/conformance

echo "==> Running Sigstore conformance tests..."
if command -v pytest &> /dev/null && pytest --help | grep -q -- "--entrypoint"; then
  pytest --entrypoint bin/conformance -k "test_verify"
else
  echo "pytest with sigstore-conformance not installed."
  echo "Install via: pip install sigstore-conformance"
  echo "Then run: pytest --entrypoint bin/conformance -k 'test_verify'"
fi
