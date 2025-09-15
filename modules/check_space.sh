#!/usr/bin/env bash

# check_backup_space
#
# Checks disk usage for /dev/sda1 and ensures it is below 50% before running backups.
# Sends a Telegram alert if the usage exceeds 50% or if the device is not found in
# the output of `df -h`. This prevents XtraBackup from failing due to insufficient space.
#
# Globals:
#   TELEGRAM_TOKEN   - The API token of the Telegram bot.
#   TELEGRAM_CHATID  - The target chat ID (user, group, or channel).
#
# Arguments:
#   None
#
# Outputs:
#   None (status is communicated via Telegram message).
#
# Returns:
#   0 if usage is <= 50% and device is found.
#   1 if usage > 50% or device is not found.
#
# Example:
#   if ! check_backup_space; then
#       echo "Not enough space for backup. Exiting."
#       exit 1
#   fi
#   create_full_backup
check_backup_space() {
	local device="/dev/sda1"
	local usage

	# Get usage % (just the number, e.g. 42)
	usage=$(df -h | awk -v dev="$device" '$1==dev {gsub("%","",$5); print $5}')

	if [[ -z "$usage" ]]; then
		send_message_telegram "Backup Warning: Device $device not found in df output."
		return 1
	fi

	if ((usage > 50)); then
		send_message_telegram "Backup Warning: $device usage is at ${usage}%, backups stored in HOME may fail soon."
		return 1
	fi

	return 0
}

check_backup_space
