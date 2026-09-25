---
name: zellij
description: "Control Zellij sessions, tabs, panes, commands, and terminal input/output. Use only when the user explicitly mentions Zellij or asks to use Zellij for these operations. Do not use merely because a task could benefit from a background terminal, delegation, or parallel work. Requires running inside Zellij."
---

# Zellij

Before issuing control commands, verify that this agent is running inside a Zellij pane:

```sh
test "${ZELLIJ:-}" = 0 && test -n "${ZELLIJ_SESSION_NAME:-}" && test -n "${ZELLIJ_PANE_ID:-}"
```

If the check fails, explain that this agent is not running inside Zellij and stop terminal operations. Do not attach to, create, or control an external session as a workaround. Reading CLI help or editing configuration does not require a live session.

## Learn the current CLI

Treat the installed binary as the authority for command syntax:

```sh
zellij --version
zellij --help
zellij run --help
zellij action --help
```

Read the relevant action's `--help` before relying on unfamiliar options. Do not run bare `zellij` for discovery; it launches or attaches the TUI. Do not probe mutating commands by omitting arguments. If required targeting or focus-preservation options are unavailable, explain the limitation instead of silently changing the user's workspace or upgrading Zellij.

## Use IDs and caller context

Inspect the inherited context and live panes before modifying them:

```sh
printf '%s\n' "$ZELLIJ_SESSION_NAME" "$ZELLIJ_PANE_ID"
zellij --session "$ZELLIJ_SESSION_NAME" action list-panes --json --command --state --tab --geometry
```

Match the caller's pane ID to the live listing. Terminal IDs may be returned as `terminal_3`; a bare integer such as `3` also identifies that terminal. Retain the session, pane ID, and tab ID from actual responses. Do not predict IDs from names, ordering, or examples. Pane IDs are scoped to a session; re-list when a target may be stale.

Use the verified session explicitly on later commands and target input/output by pane ID. Never use another client's focused pane as a substitute for the caller. If caller context cannot be resolved, stop and clarify the target. Session renaming can leave inherited `ZELLIJ_SESSION_NAME` stale; do not create a session under the old name to recover.

## Run a command in another pane

Default to a sibling pane in the current tab and the caller's working directory. Create a different tab, session, or worktree, or use a different cwd only when requested by the user.

Honor a requested split direction. Otherwise inspect caller geometry: split a wide pane right and a narrow or tall pane down. Avoid repeated splits that leave unusably small panes. Preserve user focus and cwd:

```sh
zellij --session "$ZELLIJ_SESSION_NAME" run --name TASK --cwd "$PWD" --direction right --no-focus -- COMMAND ARGUMENT...
```

Replace `right` with `down` when appropriate. `--no-focus` places the pane relative to the caller without changing client focus. Capture the returned pane ID and inspect the live listing to verify the new pane.

Prefer argument-based execution; use a shell declared by the active environment only when shell syntax is needed. Keep the pane after command exit so its output and state remain available. Use `--close-on-exit` only when discarding them is acceptable. Avoid indefinite blocking options for work that needs progress reports.

## Observe progress and completion

Read the target pane and its state:

```sh
zellij --session "$ZELLIJ_SESSION_NAME" action dump-screen --pane-id PANE_ID
zellij --session "$ZELLIJ_SESSION_NAME" action list-panes --json --command --state --tab
```

Use `--full` when scrollback is needed and `--ansi` when styling is evidence. Poll at reasonable intervals, avoid waits longer than 60 seconds at a time, and report meaningful state changes.

Distinguish successful CLI delivery from completion of the command inside the pane. Verify exit status from available pane metadata; if it is not exposed, arrange an unambiguous completion marker with the command's exit code. A log substring alone is not proof of success.

A timeout or CLI failure does not prove that a command or input was never delivered. Inspect the live panes and captured output before retrying. Do not blindly create another pane, restart a command, or resubmit input.

## Send input and interact with agents

Read the pane first to establish which program or prompt will receive input. Only send shell commands to a shell at its interactive prompt. Prefer a new command pane for ordinary processes.

For text intended as a paste, use bracketed paste and submit separately when the application expects Enter:

```sh
zellij --session "$ZELLIJ_SESSION_NAME" action paste --pane-id PANE_ID 'TEXT'
zellij --session "$ZELLIJ_SESSION_NAME" action send-keys --pane-id PANE_ID Enter
```

Use `write-chars --pane-id PANE_ID 'TEXT'` when literal terminal input is intended. For special keys, use `send-keys` with the spelling shown in its help. Dump the pane after input to confirm the effect before sending more.

A terminal pane is not an agent lifecycle API. Do not assume Herdr-style `working`, `idle`, `blocked`, or `done` states exist, or infer agent completion solely from pane existence. Inspect the application's output and prompt. Starting or delegating work to another agent requires authorization from the active task; this skill alone does not grant it.

When an approval or question UI appears, inspect it and follow the active authorization rules. Do not send Enter reflexively. If completed output cannot be recovered from the pane or scrollback, ask the agent to write it to a temporary file and read that file; use this as a fallback.

## Safety and coordination

- Use `--no-focus` for background work unless the user requests a focus change. Do not switch focus merely to send input or read output.
- Do not close tabs, panes, or sessions you did not create unless the user explicitly requests it. Preserve created panes for inspection by default; clean them up when requested or when cleanup is part of the authorized task.
- Do not enable synchronized input unless explicitly requested.
- Do not send secrets through pane input when a safer credential mechanism exists.
- Do not kill the main Zellij process. Session shutdown stops its processes and requires explicit user intent. Never use all-session kill or delete commands without explicit authorization covering all sessions.
- A missing CLI feature is not permission to stop, restart, or upgrade a session.

Before reporting completion, inspect the relevant output and pane state. Report the session, pane ID, outcome, and whether work remains running.

Environment and targeting references: [Integration](https://zellij.dev/documentation/integration.html), [CLI recipes](https://zellij.dev/documentation/cli-recipes.html). Consult installed CLI help for supported operations.
