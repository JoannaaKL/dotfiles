#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# sparse-checkout.sh — Clone or convert repos with blobless sparse checkout,
# automatically excluding secrets and large generated artifacts.
#
# Usage:
#   sparse-checkout.sh clone  <repo-url> [dest-dir]   Clone a new repo sparsely
#   sparse-checkout.sh convert [repo-dir]              Convert an existing full clone
#   sparse-checkout.sh add    [repo-dir] <path> ...    Add paths to the sparse set
#   sparse-checkout.sh remove [repo-dir] <path> ...    Remove paths from the sparse set
#   sparse-checkout.sh list   [repo-dir]               Show current sparse-checkout rules
#   sparse-checkout.sh bulk-convert <dir>               Convert every git repo under <dir>
#
# Environment:
#   SPARSE_SECRETS_FILE  Path to a custom secrets-exclusion file (one pattern/line).
#                        Falls back to ~/.config/sparse-checkout/exclude-secrets.

# ─── Logging ────────────────────────────────────────────────────────────────
log()  { printf "\033[1;34m[sparse]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[sparse]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[sparse]\033[0m %s\n" "$*" >&2; }
ok()   { printf "\033[1;32m[sparse]\033[0m %s\n" "$*"; }

# ─── Secret / junk exclusion patterns ───────────────────────────────────────
# These patterns are EXCLUDED from checkout via sparse-checkout "no-match" rules.
# Format: one gitignore-style pattern per line. Lines starting with # are ignored.
DEFAULT_EXCLUDE_PATTERNS='
# ── Secrets & credentials ──
.env
.env.*
!.env.example
!.env.template
!.env.sample
*.pem
*.key
*.p12
*.pfx
*.keystore
*.jks
*.secret
.netrc
credentials.json
service-account*.json
secrets.yml
secrets.yaml
**/config/secrets.*

# ── Auth tokens / API keys (real files, not source code about tokens) ──
.npmrc
.pypirc
.docker/config.json
.kube/config

# ── Large generated artifacts ──
**/node_modules
**/vendor
**/.terraform
**/*.tfstate
**/*.tfstate.*
**/dist
**/build/output
**/__pycache__
**/.gradle
**/.next
'

_get_exclude_patterns() {
    local secrets_file="${SPARSE_SECRETS_FILE:-${HOME}/.config/sparse-checkout/exclude-secrets}"
    if [[ -f "$secrets_file" ]]; then
        cat "$secrets_file"
    else
        printf '%s\n' "$DEFAULT_EXCLUDE_PATTERNS"
    fi
}

_build_sparse_rules() {
    local patterns
    patterns="$(_get_exclude_patterns)"

    echo "/*"
    echo "!/*/"

    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" || "$line" == \#* ]] && continue

        # In our config: !pattern means "re-include" (override a prior exclude).
        # In sparse-checkout: no prefix = include, ! prefix = exclude.
        # Config "exclude X" → sparse "!X";  Config "!X (re-include)" → sparse "X"
        if [[ "$line" == !* ]]; then
            echo "${line#!}"
        else
            echo "!${line}"
        fi
    done <<< "$patterns"
}

# ─── Commands ───────────────────────────────────────────────────────────────

cmd_clone() {
    local repo_url="${1:?Usage: sparse-checkout.sh clone <repo-url> [dest-dir]}"
    local dest="${2:-}"

    if [[ -z "$dest" ]]; then
        # Derive name from URL: org/repo.git → repo
        dest="$(basename "$repo_url" .git)"
    fi

    if [[ -d "$dest/.git" ]]; then
        err "$dest already exists as a git repo"
        return 1
    fi

    log "Cloning $repo_url → $dest (blobless + sparse)"
    git clone --filter=blob:none --sparse "$repo_url" "$dest"

    log "Configuring sparse-checkout with secret exclusions"
    git -C "$dest" sparse-checkout init --no-cone
    _apply_exclusions "$dest"

    ok "Done. Working tree: $(du -sh "$dest" | cut -f1)"
    log "Adjust with: sparse-checkout.sh add $dest <path>"
}

cmd_convert() {
    local repo_dir="${1:-.}"
    repo_dir="$(cd "$repo_dir" && pwd)"

    if [[ ! -d "$repo_dir/.git" ]]; then
        err "$repo_dir is not a git repository"
        return 1
    fi

    local repo_name
    repo_name="$(basename "$repo_dir")"
    log "Converting $repo_name to sparse checkout"

    # Enable sparse-checkout
    git -C "$repo_dir" sparse-checkout init --no-cone

    # Reconfigure remote for blobless fetch going forward
    local remote_url
    remote_url="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"
    if [[ -n "$remote_url" ]]; then
        git -C "$repo_dir" config remote.origin.promisor true
        git -C "$repo_dir" config remote.origin.partialclonefilter "blob:none"
    fi

    _apply_exclusions "$repo_dir"

    ok "Converted $repo_name. Working tree: $(du -sh "$repo_dir" | cut -f1)"
    log "Run 'git gc' to reclaim disk space from old blobs."
}

cmd_bulk_convert() {
    local parent_dir="${1:?Usage: sparse-checkout.sh bulk-convert <directory>}"
    parent_dir="$(cd "$parent_dir" && pwd)"

    local count=0
    local skipped=0

    for dir in "$parent_dir"/*/; do
        [[ -d "$dir/.git" ]] || { skipped=$((skipped + 1)); continue; }
        cmd_convert "$dir"
        count=$((count + 1))
    done

    ok "Converted $count repos ($skipped non-git directories skipped)"
}

cmd_add() {
    local repo_dir="${1:-.}"
    shift
    if [[ $# -eq 0 ]]; then
        err "Usage: sparse-checkout.sh add [repo-dir] <path> ..."
        return 1
    fi
    git -C "$repo_dir" sparse-checkout add "$@"
    ok "Added $* to sparse set in $(basename "$repo_dir")"
}

cmd_remove() {
    local repo_dir="${1:-.}"
    shift
    if [[ $# -eq 0 ]]; then
        err "Usage: sparse-checkout.sh remove [repo-dir] <path> ..."
        return 1
    fi

    # sparse-checkout doesn't have a native "remove" — rewrite the set
    local current
    current="$(git -C "$repo_dir" sparse-checkout list)"
    local new_set=()
    for entry in $current; do
        local keep=true
        for removal in "$@"; do
            if [[ "$entry" == "$removal" ]]; then
                keep=false
                break
            fi
        done
        $keep && new_set+=("$entry")
    done

    if [[ ${#new_set[@]} -eq 0 ]]; then
        warn "Cannot remove all paths; keeping root"
        new_set=("/")
    fi

    git -C "$repo_dir" sparse-checkout set "${new_set[@]}"
    ok "Removed $* from sparse set in $(basename "$repo_dir")"
}

cmd_pull() {
    local repo_dir="${1:-.}"
    repo_dir="$(cd "$repo_dir" && pwd)"

    if [[ ! -d "$repo_dir/.git" ]]; then
        err "$repo_dir is not a git repository"
        return 1
    fi

    local repo_name
    repo_name="$(basename "$repo_dir")"

    if ! git -C "$repo_dir" remote get-url origin >/dev/null 2>&1; then
        warn "$repo_name: no origin remote — skipping"
        return 0
    fi

    local default_branch
    default_branch="$(git -C "$repo_dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')"
    if [[ -z "$default_branch" ]]; then
        for candidate in main master; do
            if git -C "$repo_dir" rev-parse --verify "origin/$candidate" >/dev/null 2>&1; then
                default_branch="$candidate"
                break
            fi
        done
    fi

    if [[ -z "$default_branch" ]]; then
        err "$repo_name: cannot determine default branch"
        return 1
    fi

    log "$repo_name: fetching origin/$default_branch (single-branch)"
    git -C "$repo_dir" fetch --filter=blob:none origin "$default_branch" 2>&1 | sed "s/^/  /"

    local current_branch
    current_branch="$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)"

    if [[ "$current_branch" == "$default_branch" ]]; then
        if git -C "$repo_dir" merge-base --is-ancestor HEAD "origin/$default_branch" 2>/dev/null; then
            git -C "$repo_dir" merge --ff-only "origin/$default_branch" 2>&1 | sed "s/^/  /"
            ok "$repo_name: $default_branch fast-forwarded"
        else
            warn "$repo_name: local $default_branch has diverged — skipping merge (rebase manually)"
        fi
    else
        if git -C "$repo_dir" branch -f "$default_branch" "origin/$default_branch" 2>/dev/null; then
            ok "$repo_name: $default_branch updated (on branch $current_branch)"
        else
            warn "$repo_name: could not update $default_branch ref"
        fi
    fi
}

cmd_bulk_pull() {
    local parent_dir="${1:?Usage: sparse-checkout.sh bulk-pull <directory>}"
    parent_dir="$(cd "$parent_dir" && pwd)"

    local count=0
    local failed=0
    local skipped=0

    for dir in "$parent_dir"/*/; do
        [[ -d "$dir/.git" ]] || { skipped=$((skipped + 1)); continue; }
        if cmd_pull "$dir"; then
            count=$((count + 1))
        else
            failed=$((failed + 1))
        fi
    done

    ok "Pulled $count repos ($failed failed, $skipped non-git skipped)"
}

cmd_list() {
    local repo_dir="${1:-.}"
    if ! git -C "$repo_dir" sparse-checkout list >/dev/null 2>&1; then
        err "$repo_dir does not have sparse-checkout enabled"
        return 1
    fi
    log "Sparse-checkout paths for $(basename "$repo_dir"):"
    git -C "$repo_dir" sparse-checkout list
}

# ─── Helpers ────────────────────────────────────────────────────────────────

_apply_exclusions() {
    local repo_dir="$1"
    local sparse_file="$repo_dir/.git/info/sparse-checkout"

    # Write exclusion rules
    _build_sparse_rules > "$sparse_file"

    # Re-apply to working tree
    git -C "$repo_dir" read-tree -mu HEAD 2>/dev/null || true
}

_usage() {
    cat <<'USAGE'
sparse-checkout.sh — Sparse-clone repos with automatic secret exclusion

Commands:
  clone  <repo-url> [dest]    Clone a repo with blobless sparse checkout
  convert [repo-dir]          Convert an existing full clone to sparse
  add    [repo-dir] <path>... Add paths to the checkout set
  remove [repo-dir] <path>... Remove paths from the checkout set
  list   [repo-dir]           List current sparse-checkout paths
  pull   [repo-dir]           Fetch + fast-forward the default branch only
  bulk-convert <dir>          Convert all git repos under a directory
  bulk-pull <dir>             Pull default branch for all repos under a directory

Environment:
  SPARSE_SECRETS_FILE   Custom exclusion patterns file
                        (default: ~/.config/sparse-checkout/exclude-secrets)

Examples:
  # Clone a repo sparsely
  sparse-checkout.sh clone https://github.com/org/big-repo.git

  # Convert all repos under ~/repos
  sparse-checkout.sh bulk-convert ~/repos

  # Focus on specific directories
  sparse-checkout.sh add ~/repos/big-repo src/api tests/api

  # Pull default branch for all repos
  sparse-checkout.sh bulk-pull ~/repos
USAGE
}

# ─── Main ───────────────────────────────────────────────────────────────────

main() {
    local cmd="${1:-}"
    shift 2>/dev/null || true

    case "$cmd" in
        clone)        cmd_clone "$@" ;;
        convert)      cmd_convert "$@" ;;
        bulk-convert) cmd_bulk_convert "$@" ;;
        pull)         cmd_pull "$@" ;;
        bulk-pull)    cmd_bulk_pull "$@" ;;
        add)          cmd_add "$@" ;;
        remove)       cmd_remove "$@" ;;
        list)         cmd_list "$@" ;;
        -h|--help|help|"")
            _usage
            ;;
        *)
            err "Unknown command: $cmd"
            _usage
            return 1
            ;;
    esac
}

main "$@"
