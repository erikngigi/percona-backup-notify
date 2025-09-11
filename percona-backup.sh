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

# Function to send a message to Telegram
send_message_telegram() {
	local message="$1"

	curl -s -o /dev/null -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
		-d "chat_id=$TELEGRAM_CHATID" \
		-d "text=$message"
}

# Function to get latest percona full directory
get_last_full_backup() {
	latest_backup=$(ls --all --reverse --sort=time $BACKUP | tail -n 1)
	LAST_FULL_BACKUP="$latest_backup"
}

get_last_full_backup

create_incr_backup() {
	# Generate a timestamp for the backups and log files
	timestamp=$(date +%Y%m%d-%H%M%S)
    target_dir="$INCR_BACKUP/backup-$timestamp"

	xtrabackup --login-path=backup_operator \
        --backup \
        --target-dir="$target_dir" \
		--incremental-basedir="$BACKUP/$LAST_FULL_BACKUP" > /dev/null 2>&1

    # Extract info from xtrabackup_info
    info_file="$target_dir/xtrabackup_info"

    if [[ -f "$info_file" ]]; then
        binlog_file=$(grep "binlog_pos" "$info_file" | awk '{print $3}')
        binlog_pos=$(grep "binlog_pos" "$info_file" | awk '{print $4}')
        gtid=$(grep "GTID of the last change" "$info_file" | cut -d= -f2 | xargs)

        message="Binlog Postion: $binlog_pos"
        message="Binlog File: $binlog_file"
        message="GTID: $gtid"
    else
        message="Incremental backup completed, but xtrabackup_info not found in $target_dir"
    fi

    send_message_telegram "$message"
}

create_incr_backup
