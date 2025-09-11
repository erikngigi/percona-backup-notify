# Percona MySQL Backup with Telegram Notifications

## Overview

A small, secure, and production-ready shell-based solution to create consistent MySQL backups using **Percona XtraBackup** and notify a **Telegram channel** via a bot each time a backup completes (success or failure). This repository contains a sample `backup.sh` script, configuration examples, rotation/retention helpers, and instructions for automating the job with `cron` or `systemd`.

This project is useful for DBAs and DevOps engineers who want a lightweight, auditable backup workflow that integrates with team communication (Telegram) for immediate visibility.

---

## Features

* Consistent, non-blocking backups using Percona XtraBackup (`xtrabackup`).
* Optional prepare step to create a ready-to-restore backup.
* Compression of backup archives to save space.
* Retention policy (automatic pruning of old backups).
* Telegram notifications (success / failure) via bot.
* Simple CLI usage and automation via `cron` or `systemd`.
* Logging and error handling for easier troubleshooting.

---

## Requirements & Dependencies

* Linux (tested on Ubuntu/Debian, RHEL/CentOS-family). Other POSIX-like systems may work but are unsupported.
* MySQL server (server must be running and accessible for hot backup with XtraBackup).
* Percona XtraBackup (commonly packaged as `percona-xtrabackup` or `percona-xtrabackup-80`).
* `bash` (script assumes Bash features).
* `curl` (for Telegram API calls).
* `tar`, `gzip` (or `pigz` for faster compression) — for archiving/compressing backups.
* Optional: `pv` (progress), `gzip`/`xz` alternatives.

Install examples (Debian/Ubuntu):

```bash
# Example (may vary by distribution / Percona repo):
sudo apt update
sudo apt install -y percona-xtrabackup-80 curl tar gzip
```

> **Security note:** Never commit credentials or tokens to the repository. Use environment variables or a protected config file with strict permissions (`chmod 600`).

---

## Installation

1. **Clone the repository**

```bash
git clone https://github.com/<your-org>/percona-mysql-backup-notify.git
cd percona-mysql-backup-notify
```

2. **Copy example config and edit**

```bash
cp .env.example .env
# Edit .env and add your DB credentials, Telegram token, chat ID, paths, etc.
ano .env
```

3. **Make the script executable**

```bash
chmod +x backup.sh
```

4. **(Optional) Install system-wide**

Place the script in a predictable path such as `/usr/local/bin/mysql-backup.sh` and create a dedicated system user if desired.

---

## Configuration

Store runtime parameters in environment variables (see `.env.example`). The script reads these values at runtime.

### `.env.example`

```ini
# MySQL connection
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=backup_user
DB_PASSWORD="replace_with_secure_password"
DB_NAME=               # leave blank to back up full server

# Backup storage
BACKUP_BASE_DIR=/var/backups/mysql
COMPRESS=true           # true|false
RETENTION_DAYS=14

# Percona/XtraBackup
XTRABACKUP_CMD=xtrabackup

# Telegram
TELEGRAM_BOT_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
TELEGRAM_CHAT_ID=@your_channel_or_numeric_id

# Logging
LOG_FILE=/var/log/mysql-backup.log

# Dry run (set to true to test without performing backup)
DRY_RUN=false
```

**Environment notes**

* `TELEGRAM_CHAT_ID`: for channels you can use the `@channelusername` or the numeric chat id (often starts with `-100...`). The bot must be an admin of the channel to post messages.
* Consider storing DB credentials in `~/.my.cnf` with `chmod 600` and avoid plaintext env vars in shared systems.

---

## Usage

### Run manually

```bash
./backup.sh
# or
bash backup.sh
```

### Cron (daily at 02:00 UTC)

Edit the crontab for the user that has permissions (e.g., root or a dedicated backup user):

```cron
0 2 * * * /usr/local/bin/mysql-backup.sh >> /var/log/mysql-backup.log 2>&1
```

### systemd timer (recommended for better observability)

Create `/etc/systemd/system/mysql-backup.service`:

```ini
[Unit]
Description=MySQL backup (Percona XtraBackup)
After=network.target

[Service]
Type=oneshot
User=backup
EnvironmentFile=/etc/default/mysql-backup
ExecStart=/usr/local/bin/mysql-backup.sh
```

Create `/etc/systemd/system/mysql-backup.timer`:

```ini
[Unit]
Description=Run MySQL backup daily

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start the timer:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now mysql-backup.timer
sudo systemctl status mysql-backup.timer
```

---

## Example Workflow

1. `backup.sh` runs (manual, cron, or systemd).
2. XtraBackup creates a consistent backup under `$BACKUP_BASE_DIR/<timestamp>/`.
3. XtraBackup `--prepare` makes the backup ready to restore.
4. The script compresses the backup (optional) and stores a `.tar.gz` archive.
5. The script prunes backups older than `$RETENTION_DAYS`.
6. Script sends a Telegram message to the configured channel with the result (success/failure) and path.

---

## Error Handling & Logging

* The script uses `set -euo pipefail` to fail fast on unexpected errors.
* All runtime messages are appended to `LOG_FILE` (default: `/var/log/mysql-backup.log`).
* Failure to create or prepare a backup will trigger a Telegram failure message.
* For `systemd` users, use `journalctl -u mysql-backup.service` for service logs.
* Typical errors to watch for:

  * Disk full (`No space left on device`) — monitor available backup disk space.
  * Permission issues — ensure the backup user can read MySQL datadir and write to backup directory.
  * Incorrect credentials — XtraBackup requires a user with appropriate replication/backup privileges.

**Tip:** Add logrotate rules for `LOG_FILE` or send logs to your central logging (ELK/Promtail) solution.

---

## Security & Best Practices

* Do not store secrets in the repository. Use `EnvironmentFile` owned by root with `chmod 600` or secret managers (Vault, AWS Secrets Manager).
* The MySQL user used for backups should have the minimum privileges required (RELOAD, LOCK TABLES, REPLICATION CLIENT, SHOW VIEW, PROCESS if required by your XtraBackup version).
* Ensure backups are copied to a different physical storage or remote location (S3, NFS, offsite) for disaster recovery.
* Consider encrypting archives at rest (gpg, openssl) if backups contain sensitive data.

---

## Contributing

We welcome contributions!

1. Fork the repository.
2. Create a feature branch: `git checkout -b feat/your-feature`.
3. Add tests or update docs where applicable.
4. Open a pull request with a clear description of changes.

Please open issues for bugs or feature requests. Keep pull requests small and focused. Sign the Contributor License Agreement (if any) before submitting large changes.

---

## License

This repository is available under the `MIT` license — replace with your preferred license (e.g., Apache-2.0) as needed.

---

## Suggested Badges

Place these at the top of the README (replace placeholders):

[![CI](https://img.shields.io/badge/ci-github%20actions-blue.svg)](https://github.com/<your-org>/<repo>/actions)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
[![ShellCheck](https://img.shields.io/badge/shellcheck-passed-brightgreen.svg)](https://github.com/koalaman/shellcheck)

---

## FAQ / Troubleshooting

**Q: Bot does not post to my Telegram channel.**

* Ensure the bot is added to the channel as an administrator. For public channels use `@channelusername` as `TELEGRAM_CHAT_ID` or the numeric `-100...` ID for private channels.
* Test with a direct message to a personal chat first (use your user id) to ensure the bot token is correct.

**Q: Backups are failing with permission denied.**

* Ensure the user running the script has read access to the MySQL datadir (or use `--datadir` pointing to the correct path) and write access to `BACKUP_BASE_DIR`.

**Q: How do I verify a backup?**

* Use `xtrabackup --prepare` and then restore to a test instance. Always perform periodic restore drills.
