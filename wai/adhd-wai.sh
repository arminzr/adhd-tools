#!/usr/bin/env bash
# adhd-wai — "What Am I Doing?" ambient focus anchor for bash.
# ADHD support:
#   * Keeps your ONE current micro-task visible in the shell prompt at all times
#     (working-memory prosthetic).
#   * Every N minutes (default 15) the NEXT prompt asks you to confirm or update
#     the task — a grounded check-in that fights time-blindness and hyperfocus
#     drift. It never interrupts mid-command; it only fires when you return to an
#     empty prompt, so it can't derail a running job.
#
# Idea source: adhd CLI run, shortlist idea #3 [N7 V8 F9].
#
# Install (once):  echo 'source /root/Projects/adhd-tools/wai/adhd-wai.sh' >> ~/.bashrc
# Use:
#   wai "refactor auth middleware"   # set the current task
#   wai                              # show current task + minutes since check-in
#   wai done                         # clear the task
#   wai every 20                     # change check-in interval (minutes)
#   wai off / wai on                 # disable / enable the periodic check-in

WAI_STATE_DIR="${WAI_STATE_DIR:-$HOME/.adhd-wai}"
mkdir -p "$WAI_STATE_DIR"
WAI_TASK_FILE="$WAI_STATE_DIR/task"
WAI_LAST_FILE="$WAI_STATE_DIR/last_checkin"
WAI_INT_FILE="$WAI_STATE_DIR/interval_min"
WAI_ENABLED_FILE="$WAI_STATE_DIR/enabled"

[ -f "$WAI_INT_FILE" ] || echo 15 > "$WAI_INT_FILE"
[ -f "$WAI_ENABLED_FILE" ] || echo 1 > "$WAI_ENABLED_FILE"

_wai_now()   { date +%s; }
_wai_task()  { [ -f "$WAI_TASK_FILE" ] && cat "$WAI_TASK_FILE" || echo ""; }
_wai_int()   { cat "$WAI_INT_FILE" 2>/dev/null || echo 15; }
_wai_on()    { [ "$(cat "$WAI_ENABLED_FILE" 2>/dev/null || echo 1)" = "1" ]; }

# The user-facing command.
wai() {
  local cmd="${1:-}"
  case "$cmd" in
    "")
      local t; t="$(_wai_task)"
      if [ -z "$t" ]; then echo "wai: no current task. Set one: wai \"your task\""; return; fi
      local last mins; last="$(cat "$WAI_LAST_FILE" 2>/dev/null || _wai_now)"
      mins=$(( ( $(_wai_now) - last ) / 60 ))
      echo "🎯 $t   (${mins}m since check-in · interval $(_wai_int)m · $(_wai_on && echo on || echo off))"
      ;;
    done|clear|stop)
      rm -f "$WAI_TASK_FILE"; echo "✓ task cleared."
      ;;
    every)
      local n="${2:-}"; if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ]; then echo "$n" > "$WAI_INT_FILE"; echo "check-in interval → ${n}m"; else echo "usage: wai every <minutes>"; fi
      ;;
    off) echo 0 > "$WAI_ENABLED_FILE"; echo "periodic check-in: off (task still shown in prompt)";;
    on)  echo 1 > "$WAI_ENABLED_FILE"; echo "$(_wai_now)" > "$WAI_LAST_FILE"; echo "periodic check-in: on";;
    *)
      # Set the task to all args.
      printf '%s' "$*" > "$WAI_TASK_FILE"
      echo "$(_wai_now)" > "$WAI_LAST_FILE"
      echo "🎯 task set: $*"
      ;;
  esac
}

# The check-in, fired from PROMPT_COMMAND when due and prompt is idle.
_wai_maybe_checkin() {
  _wai_on || return 0
  local t; t="$(_wai_task)"; [ -z "$t" ] && return 0
  local last int now; last="$(cat "$WAI_LAST_FILE" 2>/dev/null || echo 0)"; int="$(_wai_int)"; now="$(_wai_now)"
  [ $(( now - last )) -lt $(( int * 60 )) ] && return 0
  # Due. Ask on the terminal.
  printf '\n\033[1m🧭 What am I doing?\033[0m  (%dm elapsed)\n' "$(( (now-last)/60 ))" > /dev/tty
  printf '   current: \033[36m%s\033[0m\n' "$t" > /dev/tty
  printf '   [Enter]=still on it · type a new task to switch · "done"=finished: ' > /dev/tty
  local ans=""; IFS= read -r ans < /dev/tty || true
  ans="$(printf '%s' "$ans" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [ "$ans" = "done" ]; then
    rm -f "$WAI_TASK_FILE"; printf '   \033[32m✓ cleared.\033[0m\n' > /dev/tty
  elif [ -n "$ans" ]; then
    printf '%s' "$ans" > "$WAI_TASK_FILE"; printf '   \033[32mswitched → %s\033[0m\n' "$ans" > /dev/tty
  else
    printf '   \033[32mstill on it.\033[0m\n' > /dev/tty
  fi
  echo "$now" > "$WAI_LAST_FILE"
}

# The prompt anchor: a compact tag prepended to PS1 so the task is always visible.
_wai_ps1_tag() {
  local t; t="$(_wai_task)"; [ -z "$t" ] && return 0
  # truncate long tasks for the prompt
  [ ${#t} -gt 40 ] && t="${t:0:37}..."
  printf '\001\033[33m\002🎯 %s\001\033[0m\002 ' "$t"
}

# Wire into the interactive prompt without stomping an existing PROMPT_COMMAND.
case "$PROMPT_COMMAND" in
  *_wai_maybe_checkin*) : ;;  # already wired
  *) PROMPT_COMMAND="_wai_maybe_checkin${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac
# Prepend the task tag to PS1 once.
case "$PS1" in
  *_wai_ps1_tag*) : ;;
  *) PS1='$(_wai_ps1_tag)'"$PS1" ;;
esac
