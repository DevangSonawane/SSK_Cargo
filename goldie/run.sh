#!/usr/bin/env bash
set -euo pipefail
STORE_ROOT="$(cd "$(dirname "$0")" && pwd)"
TOOL_ROOT="$STORE_ROOT/.tooling/goldie"
if [[ ! -f "$TOOL_ROOT/src/cli.ts" ]]; then
  echo 'Goldie is missing. Follow goldie/README.md setup instructions.' >&2
  exit 1
fi
action="${1:-render}"
audience="${2:-client}"
case "$audience" in client|driver) ;; *) echo 'Choose client or driver' >&2; exit 1;; esac
case "$action" in
  render)
    bun "$STORE_ROOT/scripts/prepare.ts"
    for target in client driver; do
      for stage in frame manifest verify; do
        bun "$TOOL_ROOT/src/cli.ts" "$stage" --config "$STORE_ROOT/$target/goldie.config.ts"
      done
    done
    bun "$STORE_ROOT/scripts/formats.ts"
    bun "$STORE_ROOT/scripts/package.ts"
    ;;
  studio)
    port=4321
    [[ "$audience" == driver ]] && port=4322
    exec bun "$TOOL_ROOT/src/cli.ts" studio --config "$STORE_ROOT/$audience/goldie.config.ts" --port "$port" --no-open
    ;;
  *) echo 'Usage: bash goldie/run.sh render | studio [client|driver]' >&2; exit 1;;
esac
