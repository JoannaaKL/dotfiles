# PR review agents

Three commands that review a GitHub pull request and fix review findings, driven
by the GitHub Copilot CLI. You can run the reviewer on its own, run the fixer on
its own, or run both in a loop until the PR passes.

All three use blobless temporary clones, so you can run them from any directory.
They never push. Workdirs with fixer commits are kept and printed so the commits
remain available. Review-only workdirs are removed when the verdict is written
to an explicit output path.

## The commands

### pr-review (review only)

Reviews the PR and writes a machine-readable verdict. Changes no code.

```bash
pr-review <pr-url> [-o <verdict-file>] [--model <model>]
```

- `-o <verdict-file>` saves the verdict where you want it. Without it, the
  verdict goes to `.pr-review/review.json` inside the temp workdir and the path
  is printed at the end.
- `--model <model>` forces a specific model. Without it, one is picked at random
  from the pool.
- Exit codes: `0` PASS, `3` FAIL, `1` setup error.

The verdict file looks like this:

```json
{
  "verdict": "FAIL",
  "summary": "one-paragraph overall assessment",
  "findings": [
    { "severity": "major", "location": "pkg/foo.go:42", "problem": "...", "fix": "..." }
  ]
}
```

### pr-address-feedback (fix only)

Reads a verdict file and applies the fixes on the PR branch, then commits.

```bash
pr-address-feedback <pr-url> <verdict-file> [--model <model>]
```

- The verdict file is the JSON that `pr-review` produced.
- `--model <model>` forces a specific model, otherwise one is picked at random.
- Exit codes: `0` fixer committed, `1` setup or verdict error.

### pr-review-loop (both, in a loop)

Runs the reviewer, and if the verdict is FAIL, runs the fixer, then reviews
again. Repeats until PASS or the iteration cap. Each round draws two distinct
models, one to review and one to fix, so the critic never shares the
implementer's reasoning. The reviewer and fixer share one checkout, so each
round sees the previous round's commits.

```bash
pr-review-loop <pr-url> [max-iters]
```

- `max-iters` defaults to 6.
- Exit codes: `0` PASS, `2` hit the cap without a PASS, `1` setup error.

## Using them separately

Review a PR and keep the verdict:

```bash
pr-review https://github.com/github/github-mcp-server/pull/42 -o ~/review.json
```

Read the verdict yourself, decide what you want, then apply the fixes when ready:

```bash
pr-address-feedback https://github.com/github/github-mcp-server/pull/42 ~/review.json
```

This split is useful when you want a human in the middle. You read the findings,
maybe edit the verdict file to drop findings you disagree with, then run the
fixer on only what is left.

## Using them together

Hands-off, make it pass:

```bash
pr-review-loop https://github.com/github/github-mcp-server/pull/42 8
```

The loop does the same review and fix steps, just chained and repeated, until
the reviewer returns PASS.

## Model pool

All three share a default pool of 19 public, concrete model IDs from the
authenticated Copilot CLI catalog (`CopilotClient.listModels()`), refreshed on
2026-09-07:

```text
claude-sonnet-5 claude-opus-5 claude-opus-4.8 claude-opus-4.7
claude-haiku-4.5
gpt-6-astra gpt-5.6-sol gpt-5.6-terra gpt-5.6-luna gpt-5.5
gpt-5.4 gpt-5.4-mini gpt-5.3-codex gpt-5-mini
mai-code-1.1-flash mai-code-1-flash-picker
grok-4.5 grok-4.6 kimi-k2.7-code
```

`auto` is excluded because it does not identify a concrete model. Internal-only
variants are also excluded. Sonnet 4.5, Sonnet 4.6, and Kimi K3 were removed
because this CLI catalog no longer returns them; GPT-6 Astra was added.

This is a snapshot, not runtime model discovery. Availability depends on the
subscription and organization policies. Other Copilot clients may offer models
that this CLI does not, including Gemini. Check the CLI's `/model` picker and
[Copilot model availability](https://docs.github.com/en/copilot/reference/ai-models/supported-models)
when refreshing the pool. Runs consume the subscription's AI credits.

Override the pool for a single run with an environment variable:

```bash
COPILOT_MODEL_POOL="gpt-6-astra claude-opus-5 grok-4.6" pr-review-loop <pr-url>
```

`pr-review` and `pr-address-feedback` need at least one model. `pr-review-loop`
needs at least two, since it picks a distinct pair each round.

## Requirements

- `copilot` CLI, logged in.
- `gh` CLI, logged in with access to the PR's repo. Access is per-repo and
  per-account. If `gh pr view <url>` returns 404, switch accounts with
  `gh auth switch --user <other>` and retry.
- `git` and `jq` on PATH.

## Coding standards

The reviewer flags violations of a shared set of standards and the fixer follows
them. They live in `pr-review-lib.sh` as `CODING_STANDARDS` and cover DRY, DAMP
naming, no block comments, Go public-before-private ordering, full test coverage
of success and failure paths, and following the MCP standard where it applies.

## Layout

```
.local/bin/pr-review              review-only command
.local/bin/pr-address-feedback    fix-only command
.local/bin/pr-review-loop         loop orchestrator
.local/lib/pr-review-lib.sh       shared code: model pool, prompts, standards,
                                  copilot invocation, PR clone and verdict helpers
```

The three commands are thin. All the shared logic sits in the library, so a
change to the prompts, the standards, or the model pool lands in one place.

## Copilot skill

The skill is named `multi-model-pr-loop` to distinguish it from the GitHub
Copilot app's built-in PR review. Say "Use the multi-model-pr-loop skill on
<PR URL>" to launch the custom loop rather than a one-shot review. Start a new
session if the app still lists the old skill name.

The shell commands keep their existing names. The installer links the renamed
skill and removes only the old installer-managed skill symlink. The skill also
documents the two standalone agents, which run only when explicitly requested.
