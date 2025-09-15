#!/usr/bin/env bash

# Resolve the real path of this script (handles symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
ENV_FILE="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)/.env"

# Load the environmental file
set -o allexport
source "$ENV_FILE"
set +o allexport

# Percona directories
BACKUP="$HOME/percona_backups/full_backups"
INCR_BACKUP="$HOME/percona_backups/incremental_updates"

# send_message_telegram
#
# Sends a plain text message to a Telegram chat using the Telegram Bot API.
#
# Globals:
#   TELEGRAM_TOKEN   - The API token of the Telegram bot.
#   TELEGRAM_CHATID  - The target chat ID (user, group, or channel).
#
# Arguments:
#   $1 - The message text to send.
#
# Outputs:
#   None (suppresses curl output).
#
# Example:
#   send_message_telegram "Backup completed successfully."
#
send_message_telegram() {
	local message="$1"

	curl -s -o /dev/null -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
		-d "chat_id=$TELEGRAM_CHATID" \
		-d "text=$message"
}

# get_last_full_backup
#
# Finds the most recent full backup directory inside the backup root path.
# Uses `find` to list directories, sorts them by modification time, and
# stores the latest one in the global variable LAST_FULL_BACKUP.
#
# Globals:
#   BACKUP            - Root directory containing backup directories.
#   LAST_FULL_BACKUP  - Set by this function to the most recent backup directory.
#
# Arguments:
#   None
#
# Outputs:
#   None (result is stored in LAST_FULL_BACKUP).
#
# Example:
#   BACKUP=/var/backups/mysql
#   get_last_full_backup
#   echo "Latest backup: $LAST_FULL_BACKUP"
#
get_last_full_backup() {
	LAST_FULL_BACKUP=$(find "$BACKUP" -maxdepth 1 -type d -printf "%T@ %p\n" | sort -n | tail -1 | awk '{print $2}')
}

# create_incr_backup
#
# Creates an incremental Percona XtraBackup based on the latest full backup.
# Generates a timestamped directory for the incremental backup, runs the backup,
# parses the xtrabackup_info file for completion time, and sends a Telegram
# notification with the result.
#
# Globals:
#   INCR_BACKUP        - Root directory where incremental backups are stored.
#   LAST_FULL_BACKUP   - Path to the latest full backup (used as base).
#   message            - Status message passed to Telegram notification.
#
# Arguments:
#   None
#
# Outputs:
#   None (backup files are written to disk; status is sent via Telegram).
#
# Side Effects:
#   Creates a new subdirectory under $INCR_BACKUP with the current timestamp.
#   Updates global variable 'message'.
#
# Example:
#   LAST_FULL_BACKUP=/var/backups/mysql/full-20250915-010000
#   INCR_BACKUP=/var/backups/mysql/incrementals
#   create_incr_backup
#
create_incr_backup() {
	# Generate a timestamp for the backups and log files
	timestamp=$(date +%Y%m%d-%H%M%S)
	target_dir="$INCR_BACKUP/backup-$timestamp"

	xtrabackup --login-path=backup_operator \
		--backup \
		--target-dir="$target_dir" \
		--incremental-basedir="$LAST_FULL_BACKUP" >/dev/null 2>&1

	# Extract info from xtrabackup_info
	info_file="$target_dir/xtrabackup_info"

	if [[ -f "$info_file" ]]; then
		created_on=$(grep "end_time" "$info_file" | awk '{print $3, $4}')
		message="Incremental Backup Completed: $created_on"
	else
		message="Incremental backup completed, but xtrabackup_info not found in $target_dir"
	fi

	send_message_telegram "$message"
}

get_last_full_backup
create_incr_backup
