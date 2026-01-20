#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$BASE_DIR/config.conf"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/acme.log"
ACME_HOME="$BASE_DIR/acme"
ACME_SH="$ACME_HOME/acme.sh"
ACME_TAR_URL="https://github.com/acmesh-official/acme.sh/archive/2.8.6.tar.gz"

mkdir -p "$LOG_DIR"
exec >>"$LOG_FILE" 2>&1

echo "===== $(date) START ====="

source "$CONFIG_FILE"

DOMAIN_ARGS="-d $DOMAIN"
[ "$ENABLE_WILDCARD" = "true" ] && DOMAIN_ARGS="$DOMAIN_ARGS -d *.$DOMAIN"

CERT_PATH="/usr/syno/etc/certificate/_archive/$DOMAIN"
BACKUP_PATH="/usr/syno/etc/certificate/_archive/${DOMAIN}.bak"

# 安装 acme.sh（tar.gz）
if [ ! -x "$ACME_SH" ]; then
  echo "Installing acme.sh from tarball..."
  mkdir -p "$ACME_HOME"
  curl -L "$ACME_TAR_URL" | tar xz --strip-components=1 -C "$ACME_HOME"
  chmod +x "$ACME_SH"
fi

# 证书过期检测（预警）
if [ -f "$CERT_PATH/fullchain.pem" ]; then
  END_DATE=$(openssl x509 -enddate -noout -in "$CERT_PATH/fullchain.pem" | cut -d= -f2)
  END_TS=$(date -d "$END_DATE" +%s)
  NOW_TS=$(date +%s)
  LEFT_DAYS=$(( (END_TS - NOW_TS) / 86400 ))
  if [ "$LEFT_DAYS" -le "$EXPIRE_WARN_DAYS" ]; then
    curl -s       -F "token=$PUSHOVER_APP_TOKEN"       -F "user=$PUSHOVER_USER_KEY"       -F "title=SSL Expiry Warning"       -F "message=$DOMAIN expires in $LEFT_DAYS days"       https://api.pushover.net/1/messages.json
  fi
fi

# 备份旧证书
[ -d "$CERT_PATH" ] && rm -rf "$BACKUP_PATH" && cp -a "$CERT_PATH" "$BACKUP_PATH"

set +e
"$ACME_SH" --issue --dns dns_cf $DOMAIN_ARGS --home "$ACME_HOME"
ISSUE_RC=$?
set -e

if [ "$ISSUE_RC" -ne 0 ]; then
  echo "Issue failed, rollback old certificate"
  [ -d "$BACKUP_PATH" ] && rm -rf "$CERT_PATH" && mv "$BACKUP_PATH" "$CERT_PATH"
  exit 1
fi

"$ACME_SH"   --install-cert   -d "$DOMAIN"   --cert-file "$CERT_PATH/cert.pem"   --key-file "$CERT_PATH/privkey.pem"   --fullchain-file "$CERT_PATH/fullchain.pem"   --reloadcmd "/usr/syno/bin/synoservicecfg --reload nginx"

rm -rf "$BACKUP_PATH"

echo "===== $(date) FINISHED ====="
