---
name: pr-review-loop
description: This skill should be used when the user asks to "run the PR review loop", "review a PR in a loop", "iteratively review and fix a pull request", "run the agentic review loop on <PR url>", or wants an automated reviewer/fixer cycle that repeats until a pull request passes review. Runs the `pr-review-loop` command with a GitHub PR URL, and works from any repository.
---

# PR Review Loop

Run the agentic PR review/fix loop: one model reviews a pull request and writes
a machine-readable verdict, a second distinct model addresses every finding and
commits, and the cycle repeats — fresh model pair each round — until the
reviewer returns PASS or the iteration cap is hit.

The loop is the `pr-review-loop` command (installed on PATH at
`~/.local/bin/pr-review-loop`). This skill is a thin launcher: gather the PR URL
(and optional max iterations) from the user, then run the command. Do not
reimplement the loop. The command clones the target PR into its own temp
workdir, so it works from ANY directory or repository.

## When to Use This Skill

- User provides a GitHub pull request URL and wants it reviewed-and-fixed in a loop.
- User asks to "keep reviewing until it passes" or "run the review loop".
- User wants two different models to alternate reviewer/fixer roles per round.

## Three Commands: Loop or Split

The review and fix agents ship as three commands so they can run together or
on their own:

- `pr-review <pr-url> [-o <file>] [--model <m>]` — review only. Writes a
  PASS/FAIL verdict JSON and changes no code. Exits 0 on PASS, 3 on FAIL.
- `pr-address-feedback <pr-url> <verdict-file> [--model <m>]` — fix only. Reads
  a verdict file and commits fixes on the PR branch.
- `pr-review-loop <pr-url> [max-iters]` — runs both in a loop until PASS.

Use the loop when the user wants a hands-off "make it pass" run. Use `pr-review`
alone when they only want an assessment, and `pr-address-feedback` alone when
they already have a verdict file and just want the fixes applied.

## Prerequisites

The command preflights these itself, but confirm they are set up:

- `copilot` CLI authenticated (`copilot login`).
- `gh` CLI authenticated with access to the PR's repository. Access is
  per-repo and per-account: if `gh pr view <url>` 404s, switch accounts with
  `gh auth switch --user <other>` and retry.
- `git` and `jq` on PATH.

## How to Run

The command takes a PR URL and an optional max-iterations count (default 6):

```bash
pr-review-loop <pr-url> [max-iters]
```

Example:

```bash
pr-review-loop https://github.com/github/github-mcp-server/pull/42 8
```

It clones the PR's repo into a temp workdir, checks out the PR branch, derives
the base ref automatically, and runs the loop there. Commits land on the checked
-out PR branch in that temp clone; the command does not push.

## Model Selection

Each cycle draws two DISTINCT models at random from a pool so the critic never
shares the implementer's reasoning.
```text
claude-sonnet-5 claude-opus-5 claude-opus-4.8 claude-opus-4.7
claude-sonnet-4.6 claude-sonnet-4.5 claude-haiku-4.5
gpt-5.6-sol gpt-5.6-terra gpt-5.6-luna gpt-5.5 gpt-5.4 gpt-5.4-mini
gpt-5.3-codex gpt-5-mini
mai-code-1.1-flash mai-code-1-flash-picker
grok-4.5 grok-4.6 kimi-k3 kimi-k2.7-code
```

```bash
COPILOT_MODEL_POOL="gpt-5.6-sol claude-opus-4.8 grok-4.6" pr-review-loop <pr-url>
```

## Exit Codes

- `0` — reviewer returned PASS; the PR is approved.
- `2` — reached max iterations without a PASS; report the last verdict file
  path (`.pr-review-loop/review.json` in the temp workdir) to the user.
- `1` — setup/resolution error (auth, missing tool, unresolvable PR).

## Steps

1. Confirm the PR URL. If the user gave a max-iterations count, pass it as the
   second argument.
2. Run `pr-review-loop <pr-url> [max-iters]`. This works from any working
   directory — no need to be inside a particular repo.
3. Stream the loop output. Each round header names the reviewer and fixer models
   chosen for that cycle.
4. On PASS, tell the user which round approved it. On exit code 2, surface the
   last verdict summary and the remaining findings.
