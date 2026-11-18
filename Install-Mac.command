#!/bin/sh
cd "$(dirname "$0")" || exit 1
printf 'VigoBeatz Stems + Grid64 (beta)\nEnter SD card root path (e.g. /Volumes/NO NAME): '
IFS= read -r CARD
printf 'Type INSTALL or RESTORE: '
IFS= read -r ACTION
/usr/bin/perl ./installer-mac.pl "$CARD" "$ACTION"
RESULT=$?
printf '\nPress Enter to close...'
IFS= read -r _
exit "$RESULT"
