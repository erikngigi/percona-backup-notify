#!/usr/bin/env bash

# Resolve the real path of this script (handles symlinks)
SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
ENV_FILE="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)/.env"

# Load the environmental file
set -o allexport
source "$ENV_FILE"
set +o allexport

# Load the bootstrap script to log events
source "$SCRIPT_DIR/modules/bootstrap.sh"

# Load the telegram message bot
source "$SCRIPT_DIR/modules/telegram.sh"

# Load the full backup script
source "$SCRIPT_DIR/modules/full_backup.sh"

# Load the incremental backup script
source "$SCRIPT_DIR/modules/incr_backup.sh"

show_help() {
	message "Usage: $0 [options]"
	message "Options:"
	message " --full-backup         Performs a full backup using Percona's XtraBackup"
	message " --incr-backup         Performs a incremental backup using Percona's XtraBackup using latest backup"
}

[ $# -eq 0 ] && show_help && exit 1

main() {
	case "$1" in
	--full-backup)
		create_full_backup
		;;
	--incr-backup)
		create_incr_backup
		;;
	*)
		message "Invalid Option"
		show_help
		return 1
		;;
	esac
}

main "$@"
