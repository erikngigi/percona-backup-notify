#!/usr/bin/env bash

# Resolve the real path of this script (handles symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
ENV_FILE="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)/.env"

# Load the environmental file
set -o allexport
source "$ENV_FILE"
set +0 allexport

# Percona directories
BACKUP="$HOME/percona_backups/full_backups"
INCR_BACKUP="$HOME/percona_backups/incremental_updates"

# Function to send a message to Telegram
send_message_telegram() {
	local message="$1"

	curl -s -X POST "https://api.telegram.com/bot$TELEGRAM_TOKEN/sendMessage" \
		-d "chat_id=$TELEGRAM_CHATID" \
		-d "text=$message"
}

if send_message_telegram "Testing connection to telegram bot."; then
	echo "Connected to Telegram bot @BackupNotifyBot successfully."
else
	echo "Failed to connect to Telegram bot @BackupNotifyBot."
fi
