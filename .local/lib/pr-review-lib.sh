#!/usr/bin/env bash
#
# pr-review-lib.sh — shared code for the PR review and fix agents.
#
# Sourced by: pr-review, pr-address-feedback, pr-review-loop.
# Provides the model pool, the copilot invocation, the coding standards, the
# reviewer and fixer prompt templates, and the PR clone/resolve helpers.
#
# The sourcing script must have already run `set -euo pipefail`.

# --- Model pool -------------------------------------------------------------
# Override the whole pool via COPILOT_MODEL_POOL="m1 m2 m3".
if [[ -n "${COPILOT_MODEL_POOL:-}" ]]; then
  read -r -a MODEL_POOL <<< "$COPILOT_MODEL_POOL"
else
  MODEL_POOL=(
    claude-sonnet-5
    claude-opus-5
    claude-opus-4.8
    claude-opus-4.7
    claude-haiku-4.5
    gpt-6-astra
    gpt-5.6-sol
    gpt-5.6-terra
    gpt-5.6-luna
    gpt-5.5
    gpt-5.4
    gpt-5.4-mini
    gpt-5.3-codex
    gpt-5-mini
    mai-code-1.1-flash
    mai-code-1-flash-picker
    grok-4.5
    grok-4.6
    kimi-k2.7-code
  )
fi

# One random model from the pool.
pick_one_model() {
  printf '%s\n' "${MODEL_POOL[@]}" | sort -R | head -1
}

# Two distinct random models: prints "<first> <second>".
pick_two_models() {
  printf '%s\n' "${MODEL_POOL[@]}" | sort -R | head -2 | tr '\n' ' '
}

# --- Logging ----------------------------------------------------------------
log() { printf '\n\033[1;36m[pr-agent]\033[0m %s\n' "$*"; }

# --- Preconditions ----------------------------------------------------------
require_tools() {
  command -v gh      >/dev/null || { echo "ERROR: gh CLI not found" >&2; exit 1; }
  command -v git     >/dev/null || { echo "ERROR: git not found" >&2; exit 1; }
  command -v jq      >/dev/null || { echo "ERROR: jq not found" >&2; exit 1; }
  command -v copilot >/dev/null || { echo "ERROR: copilot CLI not found" >&2; exit 1; }
}

require_model_pool() {
  if (( ${#MODEL_POOL[@]} < 1 )); then
    echo "ERROR: model pool is empty" >&2; exit 1
  fi
}

# --- PR resolution and clone ------------------------------------------------
# resolve_pr <pr-url> sets BASE_BRANCH, PR_NUMBER, REPO_SLUG, BASE_REF.
resolve_pr() {
  local pr_url="$1" pr_meta
  pr_meta="$(gh pr view "$pr_url" --json baseRefName,number 2>/dev/null)" \
    || { echo "ERROR: could not resolve PR $pr_url via gh (auth? access?)" >&2; exit 1; }
  BASE_BRANCH="$(jq -r '.baseRefName' <<< "$pr_meta")"
  PR_NUMBER="$(jq -r '.number' <<< "$pr_meta")"
  REPO_SLUG="$(sed -E 's#https?://[^/]+/([^/]+/[^/]+)/pull/.*#\1#' <<< "$pr_url")"
  # shellcheck disable=SC2034  # Used by scripts that source this library.
  BASE_REF="origin/$BASE_BRANCH"
}

# clone_pr <pr-url> <workdir> clones the repo into workdir and checks out the PR.
# Sets WORK_DIR. Skips cloning when the workdir already holds the PR checkout.
clone_pr() {
  local pr_url="$1" workdir="$2"
  resolve_pr "$pr_url"
  WORK_DIR="$workdir"
  if [[ -d "$WORK_DIR/.git" ]]; then
    log "Reusing existing checkout at $WORK_DIR"
    cd "$WORK_DIR" || return 1
    gh pr checkout "$PR_NUMBER" || { echo "ERROR: gh pr checkout $PR_NUMBER failed" >&2; exit 1; }
    return 0
  fi
  log "Cloning $REPO_SLUG and checking out PR #$PR_NUMBER (base: $BASE_BRANCH)"
  gh repo clone "$REPO_SLUG" "$WORK_DIR" -- --filter=blob:none -q \
    || { echo "ERROR: clone failed for $REPO_SLUG" >&2; exit 1; }
  cd "$WORK_DIR" || return 1
  gh pr checkout "$PR_NUMBER" \
    || { echo "ERROR: gh pr checkout $PR_NUMBER failed" >&2; exit 1; }
}

# --- Copilot invocation -----------------------------------------------------
# run_copilot <model> <prompt>. Runs non-interactive and autonomous in WORK_DIR.
run_copilot() {
  local model="$1" prompt="$2"
  copilot -p "$prompt" \
    --model "$model" \
    --allow-all-tools \
    --no-ask-user \
    -s \
    -C "$WORK_DIR"
}

# --- Verdict file handling --------------------------------------------------
# validate_verdict <file> exits non-zero with a message when the file is missing
# or not valid JSON.
validate_verdict() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "ERROR: verdict file not found: $file" >&2; exit 1
  fi
  if ! jq empty "$file" 2>/dev/null; then
    echo "ERROR: verdict file is not valid JSON: $file" >&2
    cat "$file" >&2; exit 1
  fi
}

# --- Shared coding standards ------------------------------------------------
# The reviewer flags violations of these; the fixer conforms to them.
CODING_STANDARDS=$(cat <<'EOF'
Coding standards this code must follow:
- DRY (Do not Repeat Yourself): no duplicated logic; extract shared behavior.
- DAMP (Descriptive And Meaningful Phrases): names read like plain language.
- No multiline/block comments. Code must be self-documenting: it reads like a
  book, logic flows through well-named functions chained together. The intent
  comes from the names, not from prose explaining the code.
- In Go, public (exported) functions appear above private (unexported) ones.
- Tests cover every path: the success path AND failure paths — missing input,
  broken network, malformed/wrong input, boundary conditions, error returns.
- Tests are documentation of system behavior: named and structured so a reader
  learns how the system behaves from reading them.
- Follow the MCP (Model Context Protocol) standard where applicable.
EOF
)

# --- Reviewer prompt --------------------------------------------------------
# printf args: base_ref, base_ref, CODING_STANDARDS, verdict_file
REVIEWER_PROMPT_TMPL=$(cat <<'EOF'
You are a rigorous senior code reviewer. Review the changes on the current
branch against the base ref "%s".

Run: git diff %s...HEAD   to see exactly what changed. Read surrounding code
as needed to judge correctness — do not review the diff in isolation.

Evaluate for: correctness bugs, security issues, race conditions, error
handling gaps, missing/incorrect tests, and violations of the repo
conventions (read AGENTS.md / CLAUDE.md if present). Only report real,
actionable problems — do not invent nitpicks to justify a FAIL.

Also enforce these coding standards and flag any violation as a finding:
%s

When done, write a JSON file to EXACTLY this path:
  %s

The file MUST be valid JSON of this shape:
  {
    "verdict": "PASS" | "FAIL",
    "summary": "one-paragraph overall assessment",
    "findings": [
      { "severity": "critical|major|minor", "location": "file:line", "problem": "...", "fix": "..." }
    ]
  }

Return PASS only if there are no critical or major findings and the change is
genuinely ready to merge. If you return PASS, "findings" may be empty.
Write the file as your final action. Do not commit or modify any source code.
EOF
)

# --- Fixer prompt -----------------------------------------------------------
# printf args: verdict_file, CODING_STANDARDS
FIXER_PROMPT_TMPL=$(cat <<'EOF'
You are a senior engineer addressing code-review findings on the current branch.
The reviewer verdict and findings are in this JSON file:
  %s

Read that file. Address EVERY finding (critical and major first, then minor).
Make minimal, focused edits — change only what the findings require, no
drive-by refactors. Add or update tests where the findings call for it.
Follow the repo conventions in AGENTS.md / CLAUDE.md if present.

Your edits must conform to these coding standards:
%s

When all findings are addressed, stage and commit your work with a clear
message summarizing what you fixed (e.g. "review: address findings").
Do not push. Do not open a PR.
EOF
)

# --- High-level agent actions -----------------------------------------------
# review_pr <model> <base_ref> <verdict_file> runs the reviewer once.
review_pr() {
  local model="$1" base_ref="$2" verdict_file="$3" prompt
  rm -f "$verdict_file"
  # shellcheck disable=SC2059  # The constant template intentionally owns placeholders.
  prompt=$(printf "$REVIEWER_PROMPT_TMPL" "$base_ref" "$base_ref" "$CODING_STANDARDS" "$verdict_file")
  run_copilot "$model" "$prompt" || { echo "reviewer run failed" >&2; exit 1; }
  validate_verdict "$verdict_file"
}

# address_feedback <model> <verdict_file> runs the fixer once.
address_feedback() {
  local model="$1" verdict_file="$2" prompt
  validate_verdict "$verdict_file"
  # shellcheck disable=SC2059  # The constant template intentionally owns placeholders.
  prompt=$(printf "$FIXER_PROMPT_TMPL" "$verdict_file" "$CODING_STANDARDS")
  run_copilot "$model" "$prompt" || { echo "fixer run failed" >&2; exit 1; }
}

# print_verdict <verdict_file> logs the verdict, summary, and finding count.
# Sets VERDICT and NFIND for the caller.
print_verdict() {
  local file="$1"
  VERDICT=$(jq -r '.verdict // "FAIL"' "$file")
  NFIND=$(jq '.findings | length' "$file")
  local summary; summary=$(jq -r '.summary // ""' "$file")
  log "Verdict: $VERDICT — $NFIND finding(s)"
  echo "  $summary"
}
