#!/usr/bin/env bash
# Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

export PATH="$HOME/.local/bin:$PATH"

echo "==> Resolving dependencies..."
dart pub get

echo "==> Preparing Sigstore conformance CLI wrapper..."
cat << 'EOF' > "$DIR/bin/conformance"
#!/usr/bin/env bash
CALLER_CWD="$(pwd)"
SIGSTORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export CONFORMANCE_CWD="$CALLER_CWD"
cd "$SIGSTORE_DIR"
exec dart run bin/conformance.dart "$@"
EOF
chmod +x "$DIR/bin/conformance"

echo "==> Running Sigstore conformance tests..."
CONFORMANCE_DIR="/tmp/sigstore-conformance-repo"
if [ ! -d "$CONFORMANCE_DIR" ]; then
  echo "Cloning sigstore-conformance test suite to $CONFORMANCE_DIR..."
  git clone --depth 1 https://github.com/sigstore/sigstore-conformance.git "$CONFORMANCE_DIR"
fi

if command -v pytest &> /dev/null; then
  pytest --entrypoint "$DIR/bin/conformance" -k "test_verify" "$CONFORMANCE_DIR/test"
else
  echo "pytest not found in PATH."
fi
