#!/usr/bin/env bash

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
	LAST_FULL_BACKUP=$(find "$HOME/$BACKUP_DIR/$FULL_BACKUP_DIR" -maxdepth 1 -type d -printf "%T@ %p\n" | sort -n | tail -1 | awk '{print $2}')
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
	timestamp=$(date +%Y-%m-%d-%H:%M:%S)
	target_dir="$HOME/$BACKUP_DIR/$INCR_BACKUP_DIR/$INCR_BACKUP_NAME-$timestamp"

	# Ensure the parent directories exist
	if [[ ! -d "$HOME/$BACKUP_DIR/$INCR_BACKUP_DIR" ]]; then
		mkdir -p "$HOME/$BACKUP_DIR/$INCR_BACKUP_DIR"
	fi

	get_last_full_backup

	xtrabackup --login-path="$MYSQL_BACKUP_LOGIN_PATH" \
		--backup \
		--target-dir="$target_dir" \
		--incremental-basedir="$LAST_FULL_BACKUP" >/dev/null 2>&1

	# Check if backup was created and measure size
	if [[ -d "$target_dir" ]]; then
		backup_size=$(du -sh "$target_dir" | awk '{print $1}')
		message="Incremental Compressed Completed: $timestamp | Size: $backup_size"
	else
		message="Incremental Backup Failed: $timestamp (target directory missing)"
	fi

	send_message_telegram "$message"
}
