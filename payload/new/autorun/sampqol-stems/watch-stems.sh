#!/bin/sh
# On-device SD-card queue. The input WAV is never modified.
INSTALL="$1"
CARD="$2"
INBOX="$CARD/Stems/Inbox"
OUTROOT="$CARD/Stems/Separated"
STATE="$CARD/Stems/.state"
STATUS="$CARD/Stems/STATUS.txt"
mkdir -p "$INBOX" "$OUTROOT" "$STATE" || exit 1
status() { printf '%s\n' "$1" > "$STATUS.tmp" && mv "$STATUS.tmp" "$STATUS"; }
LIVE="${SAMPQOL_STEMS_STATUS:-/run/sampqol-stems-status}"
RUNDIR="${STEMS_RUN_DIR:-/tmp/sampqol-stems}"
live() { printf '%s %s\n%s\n' "$1" "$2" "$3" > "$LIVE.shell-tmp" && mv "$LIVE.shell-tmp" "$LIVE"; }
# SD cards can be mounted noexec. Executables and shared libraries run from RAM.
mkdir -p "$RUNDIR/lib" || exit 1
cp "$INSTALL/stem-worker" "$RUNDIR/stem-worker" &&
cp "$INSTALL/lib/libonnxruntime.so.1" "$RUNDIR/lib/libonnxruntime.so.1" &&
chmod 755 "$RUNDIR/stem-worker" || { live error 0 'Could not prepare worker in RAM'; exit 1; }
REQUEST="${SAMPQOL_STEMS_REQUEST:-/run/sampqol-stems-request}"
RESULTFILE="${SAMPQOL_STEMS_RESULT:-/run/sampqol-stems-result}"
# Requests exist only in RAM and are discarded when this service starts.
rm -f "$REQUEST" "$REQUEST.claimed" "$RESULTFILE"
live idle 0 'Sample screen: SHIFT+B1'
status 'Ready. Start separation from the Sample screen with SHIFT+B1.' 
while :; do
 if [ -f "$REQUEST" ] && mv "$REQUEST" "$REQUEST.claimed"; then
  { IFS= read -r INPUT; IFS= read -r MASK; } < "$REQUEST.claimed"
  MASK=${MASK:-15}
  case "$MASK" in 1|2|3|4|5|6|7|8|9|10|11|12|13|14|15) ;; *) live error 0 'Invalid stem selection'; rm -f "$REQUEST.claimed"; continue ;; esac
  rm -f "$REQUEST.claimed"
  case "$INPUT" in "$INBOX/"*.wav|"$INBOX/"*.WAV) ;; *) live error 0 'Invalid sample request'; continue ;; esac
  [ -f "$INPUT" ] || { live error 0 'Requested WAV is missing'; continue; }
  SIZE=$(wc -c < "$INPUT" | tr -d ' ')
  [ "$SIZE" -gt 44 ] 2>/dev/null || continue
  # Wait for the producer to finish writing before hashing and snapshotting.
  sleep "${STEMS_SETTLE_SECONDS:-2}"
  NOW=$(wc -c < "$INPUT" | tr -d ' ')
  [ "$SIZE" = "$NOW" ] || continue
  HASH=$(sha256sum "$INPUT" | cut -d ' ' -f 1)
  [ -n "$HASH" ] || continue
  [ -f "$STATE/$HASH.done" ] && continue
  [ -f "$STATE/$HASH.failed" ] && continue
  NAME=${INPUT##*/}
  BASE=${NAME%.*}
  SHORT=$(printf '%s' "$HASH" | cut -c 1-12)
  OUT="$OUTROOT/$BASE-$SHORT"
  if [ -f "$OUT/COMPLETE" ]; then
   printf '%s\n' "$OUT" > "$STATE/$HASH.done"
   continue
  fi
  if [ -e "$OUT" ]; then
   mv "$OUT" "$OUT.incomplete.$(date +%s).$$" || continue
  fi
  SNAPSHOT="$STATE/$HASH.input.wav"
  cp "$INPUT" "$SNAPSHOT" || { status 'Could not snapshot the input WAV.'; continue; }
  COPIED=$(sha256sum "$SNAPSHOT" | cut -d ' ' -f 1)
  if [ "$HASH" != "$COPIED" ]; then rm -f "$SNAPSHOT"; continue; fi
  status "Separating $NAME. Results will appear in Stems/Separated."
  live starting 0 "Preparing $NAME"
  (
   unset LD_PRELOAD
   "$RUNDIR/stem-worker" "$INSTALL/Models" "$SNAPSHOT" "$OUT" "${STEMS_THREADS:-2}" "$LIVE" "$MASK"
  ) > "$STATE/$HASH.log" 2>&1
  RESULT=$?
  rm -f "$SNAPSHOT"
  if [ "$RESULT" = 0 ] && [ -f "$OUT/COMPLETE" ]; then
   printf '%s\n' "$OUT" > "$STATE/$HASH.done"
   printf '%s\n%s\n%d\n' "$INPUT" "$OUT" "$MASK" > "$RESULTFILE.tmp" && mv "$RESULTFILE.tmp" "$RESULTFILE"
   live done 100 "Stems saved"
   status "Finished $NAME. Load your selected stems from Stems/Separated/$BASE-$SHORT."
  else
   printf '%s\n' "$RESULT" > "$STATE/$HASH.failed"
   IFS= read -r ERROR < "$STATE/$HASH.log"
   ERROR=${ERROR#*: }
   live error 0 "${ERROR:-Worker exited $RESULT; check STATUS.txt}"
   status "Failed to separate $NAME. Details: Stems/.state/$HASH.log. Your source WAV is unchanged."
  fi
  [ "${STEMS_ONCE:-0}" = 1 ] && exit "$RESULT"
 fi
 sleep "${STEMS_POLL_SECONDS:-3}"
done
