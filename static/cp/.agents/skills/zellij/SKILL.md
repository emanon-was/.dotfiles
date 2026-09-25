---
name: zellij
description: Operate Zellij sessions, tabs, and panes from the CLI to run, observe, and interact with long-running or interactive commands. Use when a task should run in Zellij, must continue independently of the current shell, needs periodic terminal-output monitoring, or requires sending input to a managed pane. Do not use for ordinary foreground commands that can be completed directly.
---

# Zellij

Use Zellij as a controlled terminal workspace. Identify the target session and pane explicitly, retain their identifiers, and verify results from captured pane output.

## Establish the target

1. Confirm that `zellij` is available. Follow the active project's dependency policy before using it.
2. List sessions with `zellij list-sessions --short --no-formatting`.
3. Use `$ZELLIJ_SESSION_NAME` when already inside the intended session. Otherwise, use a session named by the user or create a short task-specific name.
4. If multiple existing sessions could be the target, do not guess. Ask the user which session to use.
5. Create a missing detached session with `zellij attach --create-background SESSION`.

Pass `--session SESSION` before `action`, `run`, or another subcommand when operating from outside the target session. Do not rely on whichever session happens to be active.

## Run a command

Prefer argument-based execution so the command does not require an extra shell:

```sh
zellij --session SESSION run --name PANE --cwd DIRECTORY -- COMMAND ARGUMENT...
```

Capture the returned pane ID, such as `terminal_3`, and use it for later operations. Use `bash -lc` or another shell only when shell syntax is genuinely required; ensure that shell is declared by the active environment.

Keep the pane after command exit when its output or exit state must be inspected. Use `--close-on-exit` only when losing the completed pane is acceptable. Use a blocking option only when the task specifically benefits from waiting in the calling process.

## Observe progress

Inspect pane metadata in a machine-readable form:

```sh
zellij --session SESSION action list-panes --json --command --state --tab
```

Read a pane's visible output:

```sh
zellij --session SESSION action dump-screen --pane-id PANE_ID
```

Add `--full` only when scrollback is needed and `--ansi` only when styling is relevant. Poll at reasonable intervals for long-running work, report meaningful state changes, and avoid waits longer than 60 seconds at a time.

Do not infer success only from terminal text. When exit status matters, use pane state or arrange for the command to emit an unambiguous completion status, then verify it.

## Send input

Target the pane ID explicitly. Send literal text with:

```sh
zellij --session SESSION action write-chars --pane-id PANE_ID 'TEXT'
```

Send special keys with:

```sh
zellij --session SESSION action send-keys --pane-id PANE_ID Enter
```

Dump the pane again after sending input to confirm the effect. Treat prompts that publish, deploy, delete, overwrite, reveal secrets, or otherwise change external state as new actions requiring the same authorization they would require outside Zellij.

## Safety rules

- List and inspect before modifying an existing session.
- Use stable session names and pane IDs; re-list panes when an ID may be stale.
- Do not enable synchronized input across panes unless the user explicitly requests it.
- Do not send secrets through pane input when a safer environment or credential mechanism exists.
- Do not interrupt, close, kill, or delete a pane or session unless the user requested that lifecycle action or it is clearly part of the authorized task.
- Never use `kill-all-sessions` or `delete-all-sessions` without explicit confirmation immediately before the action.
- Leave unrelated sessions, tabs, and panes unchanged.

## Finish

Before reporting completion, dump the relevant pane output and inspect its state. Report the session name, pane ID, outcome, and whether the session or pane remains running. Preserve the workspace by default so the user can inspect it; clean it up only when requested.
