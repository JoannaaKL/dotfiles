---
name: catchup
description: This skill should be used when the user asks to "catch up on <subject>", "what did I miss", "find recent updates on <topic>", "get me up to speed after vacation", or wants a digest of recent Slack and GitHub activity on a subject with research on any new topics. Runs the `catchup` command and works from any repository.
---

# Catchup

Build a "what did I miss" digest for a subject. Three agents run in sequence:
a scout searches Slack and GitHub for recent activity, a researcher looks up any
new topics that came up, and a writer produces a plain-language report with all
the links. The report avoids AI-sounding prose on purpose.

The pipeline is the `catchup` command (installed on PATH at
`~/.local/bin/catchup`). This skill is a thin launcher: get the subject and the
lookback window from the user, then run the command. Do not reimplement it.

## When to Use This Skill

- User is back from time off and wants to know what happened on a subject.
- User asks "what did I miss on <subject>" or "catch me up on <topic>".
- User wants recent Slack and GitHub activity plus context on unfamiliar topics.

## Prerequisites

- `copilot` CLI authenticated (`copilot login`).
- The Slack MCP server configured in `~/.copilot/mcp-config.json` and
  authenticated. Without it, the scout can still search GitHub but will skip
  Slack.
- GitHub access available (the `gh` CLI logged in, or GitHub MCP tools).
- `jq` on PATH.

## How to Run

```bash
catchup "<subject>" [days] [-o <report-path>]
```

- `subject` is required. Quote it if it has spaces.
- `days` is the lookback window in days. Default is 5. Use a larger number
  after a longer break.
- `-o <path>` writes the report to a file you choose. Without it, the report
  goes to a temp file and is printed to the screen.

Examples:

```bash
catchup "github-mcp-server"
catchup "github-mcp-server" 10
catchup "MCP tool annotations" 14 -o ~/catchup-mcp.md
```

## Model Selection

Each phase picks a model at random from a small pool so the three agents bring
different perspectives. Override the pool with an environment variable:

```bash
CATCHUP_MODEL_POOL="gpt-5.6-sol claude-opus-4.8" catchup "github-mcp-server" 7
```

## Steps

1. Confirm the subject and the lookback window in days. If the user just got
   back from a long break, suggest a larger window (10 to 14 days).
2. Run `catchup "<subject>" [days]`, adding `-o <path>` if the user wants the
   report saved somewhere specific.
3. The command prints the report when it finishes. Each phase logs which model
   it used and how many conversations and new topics it found.
4. If nothing was found, tell the user plainly and offer a wider date window.
