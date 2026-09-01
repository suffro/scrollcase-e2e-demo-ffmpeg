#!/usr/bin/env bash
set -euo pipefail

# The Codespace is a scratch clone: dropping the remote makes it impossible to push the commit the
# walkthrough asks for back into the demo repository by accident.
if [[ ${CODESPACES:-} == true ]] && git remote get-url origin >/dev/null 2>&1; then
  git remote remove origin
fi
