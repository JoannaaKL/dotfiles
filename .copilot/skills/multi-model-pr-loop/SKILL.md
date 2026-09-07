---
name: multi-model-pr-loop
description: Run the user's custom multi-model PR review/fix loop. Use when the user names "multi-model-pr-loop", asks to "run my multi-model loop", "run my PR review loop", "keep reviewing and fixing until it passes", or wants different Copilot models to review and fix a GitHub PR in repeated rounds. Launches the installed pr-review-loop shell command, not the app's built-in PR review or a one-shot code-review agent. Works from any repository.
---

# Multi-model PR Loop

Run the agentic PR review/fix loop: one model reviews a pull request and writes
a machine-readable verdict, a second distinct model addresses every finding and
commits, and the cycle repeats with a new random pair each round until the
reviewer returns PASS or the iteration cap is hit.

The loop is the `pr-review-loop` command (installed on PATH at
`~/.local/bin/pr-review-loop`). This skill is a thin launcher: use the supplied
PR URL and optional max iterations, then run the command. Ask for the URL only
if it is missing. Do not reimplement the loop. The command clones the target
PR into its own temp workdir, so it works from any directory or repository.

## Invoking from the GitHub Copilot App

Use an explicit request: "Use the multi-model-pr-loop skill on <PR URL>".
The distinct skill name avoids the built-in PR review shortcut. If an existing
session still lists the old skill, start a new session to reload discovery.

After loading this skill, execute the shell command below. Do not substitute
the app's built-in review, a one-shot `code-review` subagent, or the standalone
`pr-review` command for a requested loop. Opening a PR review session alone
does not run this skill.

## When to Use This Skill

- User provides a GitHub pull request URL and wants it reviewed-and-fixed in a loop.
- User asks to "keep reviewing until it passes" or "run my multi-model loop".
- User wants two different models to alternate reviewer/fixer roles per round.

## Three Commands: Loop or Split

The review and fix agents ship as three commands so they can run together or
on their own:

- `pr-review <pr-url> [-o <file>] [--model <m>]`: review only. Writes a
  PASS/FAIL verdict JSON and changes no code. Exits 0 on PASS, 3 on FAIL.
- `pr-address-feedback <pr-url> <verdict-file> [--model <m>]`: fix only. Reads
  a verdict file and commits fixes on the PR branch.
- `pr-review-loop <pr-url> [max-iters]`: runs both in a loop until PASS.

Use the loop by default for this skill. Use `pr-review` alone only when the user
explicitly requests review-only, and `pr-address-feedback` alone when they already
have a verdict file and just want the fixes applied.

## Prerequisites

The command preflights these itself, but confirm they are set up:

- `copilot` CLI authenticated (`copilot login`) with an active Copilot subscription.
- `gh` CLI authenticated with access to the PR's repository. Access is
  per-repo and per-account: if `gh pr view <url>` 404s, switch accounts with
  `gh auth switch --user <other>` and retry.
- `git`, `jq`, and Node.js on PATH. On this Mac, include `~/.local/bin` and
  `/opt/homebrew/bin` so the Copilot CLI's Node.js launcher works.

## How to Run

The command takes a PR URL and an optional max-iterations count (default 6):

```bash
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
"$HOME/.local/bin/pr-review-loop" <pr-url> [max-iters]
```

Example:

```bash
pr-review-loop https://github.com/github/github-mcp-server/pull/42 8
```

It clones the PR's repo into a temp workdir, checks out the PR branch, derives
the base ref automatically, and runs the loop there. Commits land on the
checked-out PR branch in that temp clone; the command does not push or submit
a GitHub review.

## Model Selection

Each cycle draws two distinct model IDs at random. The shared library at
`~/.local/lib/pr-review-lib.sh` is the source of truth for all three commands.
The default pool is a snapshot of the public models returned by the
authenticated Copilot CLI catalog (`CopilotClient.listModels()`) on 2026-09-07:

```text
claude-sonnet-5 claude-opus-5 claude-opus-4.8 claude-opus-4.7
claude-haiku-4.5
gpt-6-astra gpt-5.6-sol gpt-5.6-terra gpt-5.6-luna gpt-5.5
gpt-5.4 gpt-5.4-mini gpt-5.3-codex gpt-5-mini
mai-code-1.1-flash mai-code-1-flash-picker
grok-4.5 grok-4.6 kimi-k2.7-code
```

`auto` and internal-only models are excluded. Sonnet 4.5, Sonnet 4.6, Kimi K3,
and Gemini models are not in this CLI catalog, even if another Copilot client
lists some of them. Available models depend on the subscription and organization
policies, and runs consume the subscription's AI credits. Check the CLI's
`/model` picker and [Copilot model availability](https://docs.github.com/en/copilot/reference/ai-models/supported-models)
when refreshing the pool; the app's subagent model list is not the CLI catalog.

Override the pool for a run using at least two distinct supported model IDs:

```bash
COPILOT_MODEL_POOL="gpt-6-astra claude-opus-5 grok-4.6" pr-review-loop <pr-url>
```

## Exit Codes

- `0`: reviewer returned PASS locally; no GitHub approval is posted.
- `2`: reached max iterations without a PASS; report the last verdict file
  path (`.pr-review/review.json` in the temp workdir) to the user.
- `1`: setup/resolution error (auth, missing tool, unresolvable PR).

## Steps

1. Use the supplied PR URL. If the user gave a max-iterations count, pass it as the
   second argument.
2. Set PATH as above and run `"$HOME/.local/bin/pr-review-loop" <pr-url> [max-iters]`.
   This works from any working directory, with no need to open a PR review session.
3. Stream the loop output. Each round header names the reviewer and fixer models
   chosen for that cycle.
4. On PASS, tell the user which round passed. On exit code 2, surface the
   last verdict summary and the remaining findings. Include the temp checkout
   path when fixes were committed, and make clear they have not been pushed.
