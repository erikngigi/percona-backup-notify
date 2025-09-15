#!/usr/bin/env bash

# create_full_backup
#
# Creates a full Percona XtraBackup. Generates a timestamped directory
# for the backup, runs the backup, parses the xtrabackup_info file for
# completion time, and sends a Telegram notification with the result.
#
# Globals:
#   FULL_BACKUP        - Root directory where full backups are stored.
#   message            - Status message passed to Telegram notification.
#
# Arguments:
#   None
#
# Outputs:
#   None (backup files are written to disk; status is sent via Telegram).
#
# Side Effects:
#   Creates a new subdirectory under $FULL_BACKUP with the current timestamp.
#
# Example:
#   FULL_BACKUP=/var/backups/mysql/full
#   create_full_backup
#
create_full_backup() {
	# Generate a timestamp for the backups and log files
	timestamp=$(date +%Y%m%d-%H%M%S)
	target_dir="$HOME/$BACKUP_DIR/$FULL_BACKUP_DIR/$FULL_BACKUP_NAME_$timestamp"

	# Ensure the parent directories exist
	if [[ ! -d "$HOME/$BACKUP_DIR/$FULL_BACKUP_DIR" ]]; then
		mkdir -p "$HOME/$BACKUP_DIR/$FULL_BACKUP_DIR"
	fi

	xtrabackup --login-path="$MYSQL_BACKUP_LOGIN_PATH" \
		--backup \
		--target-dir="$target_dir" >/dev/null 2>&1

	message="Full Compressed Backup Completed: $timestamp"

	send_message_telegram "$message"
}
