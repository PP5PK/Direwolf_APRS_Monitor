#!/bin/bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root:"
    echo "  sudo $0"
    exit 1
fi

echo "== Removing APRS Direwolf Web Monitor =="

systemctl disable --now ttyd-direwolf.service 2>/dev/null || true
rm -f /etc/systemd/system/ttyd-direwolf.service

a2dissite aprs.whre.be.conf 2>/dev/null || true
a2dissite 000-default.conf 2>/dev/null || true

# Restore the package-provided default virtual host when possible.
if [[ -f /usr/share/apache2/default-site/index.html ]]; then
    :
fi

rm -f /etc/apache2/sites-available/aprs.whre.be.conf
rm -f /var/www/html/index.html

systemctl daemon-reload
systemctl restart apache2

echo "Monitor files and ttyd service removed."
echo "Note: ttyd package and Apache modules were intentionally not removed."
echo "The original Apache 000-default.conf is not automatically restored."
