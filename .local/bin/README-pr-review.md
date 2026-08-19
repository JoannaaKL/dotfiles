# PR review agents

Three commands that review a GitHub pull request and fix review findings, driven
by the GitHub Copilot CLI. You can run the reviewer on its own, run the fixer on
its own, or run both in a loop until the PR passes.

All three clone the target PR into their own temp workdir, so you can run them
from any directory. They never push. Commits land on the checked-out PR branch
in the temp clone.

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

All three share a model pool. Override it for a single run with an environment
variable:

```bash
COPILOT_MODEL_POOL="gpt-5.6-sol claude-opus-4.8 grok-4.6" pr-review-loop <pr-url>
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

`pr-review-loop` is also wired as a Copilot CLI skill, so inside a `copilot`
session you can say "run the PR review loop on <url>" and it launches the
command. The skill also documents the two standalone agents.
