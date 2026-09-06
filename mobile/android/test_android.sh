#!/usr/bin/env bash
set -euo pipefail
exec bash "$(dirname "$0")/android.sh" test "$@"
