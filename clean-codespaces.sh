#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "GitHub CLI (gh) is required" >&2; exit 1; }

dry_run=false
if [[ "${1:-}" == "--dry-run" ]]; then
	dry_run=true
fi

names=$(gh codespace list --json name,state | jq -r '.[] | select(.state=="Shutdown") | .name')
if [[ -z "$names" ]]; then
	echo "No shutdown codespaces to delete"
	exit 0
fi

echo "Found shutdown codespaces:" >&2
# shellcheck disable=SC2001
echo "${names}" | sed 's/^/ - /'

for name in $names; do
  if $dry_run; then
    echo "[dry-run] Would delete: $name"
  else
    echo "Deleting codespace: $name"
    if ! gh codespace delete -c "$name" -f; then
      echo "Failed to delete $name" >&2
    fi
  fi
done
