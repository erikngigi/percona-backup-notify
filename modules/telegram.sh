#!/usr/bin/env bash

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
