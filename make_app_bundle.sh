#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
echo "make_app_bundle.sh is deprecated. Using scripts/package_app.sh ..."
"${PROJECT_ROOT}/scripts/package_app.sh"
