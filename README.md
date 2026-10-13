# adhd-tools — Terminal Tools for ADHD-Friendly Workflow

Small, dependency-free shell tools that act as **external working-memory
prosthetics** for people with ADHD. They fight the three classic failure modes —
task amnesia, time-blindness, and context-switch paralysis — right where you
work: the terminal, the shell prompt, and the pre-commit hook.

Everything is plain POSIX `bash` + standard tools. **No install step beyond
sourcing or copying a hook.**

## 🧭 1/ `wai` — "What Am I Doing?" ambient focus anchor

`wai/adhd-wai.sh` keeps your **one current micro-task** visible in the shell
prompt at all times and periodically asks you to re-ground on it.

### Features

- Keeps a single current task in your prompt (working-memory prosthetic).
- Every N minutes (default **15**) the next idle prompt asks you to confirm or
  update the task — a grounded check-in that fights **time-blindness** and
  **hyperfocus drift**.
- Never interrupts mid-command — it only fires when you return to an empty
  prompt, so it can't derail a running job.

### Install (once)

```bash
echo 'source /root/Projects/adhd-tools/wai/adhd-wai.sh' >> ~/.bashrc
```

### Usage

```bash
wai "refactor auth middleware"   # set the current task
wai                              # show current task + minutes since check-in
wai done                         # clear the task
wai every 20                     # change check-in interval (minutes)
wai off  /  wai on               # disable / enable the periodic check-in
```

## 🪵 2/ `decision-log` — git pre-commit "next action" hook

`decision-log/pre-commit` is a git **pre-commit hook** that, before every
commit is allowed, makes you type the **ONE next action**. This leaves a
breadcrumb so that after the commit (a natural context-switch point) you know
exactly where to restart — killing *"What was I doing?"* paralysis.

- Appends to `<repo>/.decision_log.md` — an append-only, chronological trail of
  intent: timestamp, branch, staged-file count, and your next action.
- Auto-skips non-interactive commits (CI, rebase, merges) so it never hangs.

### Install

```bash
cp decision-log/pre-commit <repo>/.git/hooks/pre-commit
chmod +x <repo>/.git/hooks/pre-commit
```

### Usage

```bash
git commit -m "refactor auth"     # hook will ask for a 'next action' first
DECISION_LOG_SKIP=1 git commit    # bypass for a single commit
```

## 📁 Layout

```
adhd-tools/
├── wai/
│   └── adhd-wai.sh        # bash prompt anchor — "wai" command
└── decision-log/
    └── pre-commit         # git hook — logs your next action before each commit
```

## 🤝 Idea Sources

Both tools were shortlisted from the `adhd` CLI run:
- `wai` — idea #3
- `decision-log` — idea #2

## 📄 License

MIT.
