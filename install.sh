#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SYSTEMD_FILE="$PROJECT_DIR/systemd/ttyd-direwolf.service"
INDEX_FILE="$PROJECT_DIR/index.html"
APACHE_DEFAULT="$PROJECT_DIR/apache/000-default.conf"
APACHE_SITE="$PROJECT_DIR/apache/aprs.whre.be.conf"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root:"
    echo "  sudo $0"
    exit 1
fi

echo "== APRS Direwolf Web Monitor =="
echo

# Direwolf is an external prerequisite.
if ! systemctl is-active --quiet direwolf.service; then
    die "direwolf.service is not running. Start/configure Direwolf before installing the monitor."
fi

echo "[1/8] Installing dependencies..."
apt-get update
apt-get install -y apache2 ttyd

echo "[2/8] Enabling Apache modules..."
a2enmod proxy
a2enmod proxy_http
a2enmod proxy_wstunnel
a2enmod rewrite
a2enmod ssl

echo "[3/8] Installing web page..."
install -d -m 0755 /var/www/html
install -m 0644 "$INDEX_FILE" /var/www/html/index.html

echo "[4/8] Installing ttyd systemd service..."
install -m 0644 "$SYSTEMD_FILE" /etc/systemd/system/ttyd-direwolf.service

echo "[5/8] Installing Apache configuration..."
install -m 0644 "$APACHE_DEFAULT" /etc/apache2/sites-available/000-default.conf
install -m 0644 "$APACHE_SITE" /etc/apache2/sites-available/aprs.whre.be.conf

echo "[6/8] Enabling Apache sites..."
a2ensite 000-default.conf
a2ensite aprs.whre.be.conf

echo "[7/8] Validating Apache configuration..."
/usr/sbin/apache2ctl configtest

echo "[8/8] Reloading services..."
systemctl daemon-reload
systemctl enable --now ttyd-direwolf.service
systemctl restart apache2

echo
echo "Installation completed."
echo
echo "Monitor:"
echo "  http://aprs.whre.be/"
echo
echo "The domain configuration redirects HTTP to HTTPS."
echo "Run Certbot separately to configure the SSL VirtualHost."
echo
echo "Service status:"
systemctl --no-pager --full status ttyd-direwolf.service
