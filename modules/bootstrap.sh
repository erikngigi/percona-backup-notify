#!/usr/bin/env bash

# --- Setup logging ---
LOGDIR="$SCRIPT_DIR/logs"

if [[ ! -d "$LOGDIR" ]]; then
	mkdir -p "$LOGDIR"
fi

# Use timestamped log file names: YYYY-MM-DD_HH-MM-SS.log
timestamp=$(date +%Y%m%d-%H%M%S)
LOGFILE="$LOGDIR/backup_$timestamp.log"

# Backup stdout & stderr so we can still talk to the terminal
exec 3>&1 4>&2

# Redirect normal stdout & stderr to log file
exec 1>"$LOGFILE" 2>&1

# Enable command tracing and exit on error
set -ex

message() {
	echo "$*" >&3
}
