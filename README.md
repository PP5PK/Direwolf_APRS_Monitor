# APRS Direwolf Web Monitor

A lightweight web monitor for an existing Direwolf installation.

The monitor does not install or configure Direwolf. It assumes that
`direwolf.service` is already installed, configured and running.

## Architecture

```text
Direwolf
   |
   | journalctl -u direwolf.service -n 15 -f -o cat
   v
ttyd :7688
   |
   | HTTP + WebSocket
   v
Apache
   |
   | /terminal
   v
index.html
```

The browser page contains an iframe pointing to `/terminal`. Apache proxies
that path to ttyd, while `mod_proxy_wstunnel` and the rewrite rule allow the
WebSocket connection used by ttyd.

## Files

```text
.
├── README.md
├── install.sh
├── uninstall.sh
├── index.html
├── systemd/
│   └── ttyd-direwolf.service
└── apache/
    ├── 000-default.conf
    └── aprs.whre.be.conf
```

## Requirements

- Debian/Raspberry Pi OS with `apt`
- Apache2
- A working `direwolf.service`
- User `aprs`
- Network access to the package repositories

The installer installs Apache2 and ttyd if necessary.

## Installation

First make sure Direwolf is already running:

```bash
systemctl status direwolf.service
```

Then:

```bash
sudo ./install.sh
```

The installer:

1. Verifies that `direwolf.service` is running.
2. Installs Apache2 and ttyd.
3. Enables:
   - `proxy`
   - `proxy_http`
   - `proxy_wstunnel`
   - `rewrite`
   - `ssl`
4. Installs `index.html`.
5. Installs `ttyd-direwolf.service`.
6. Configures Apache `/terminal` proxy and WebSocket support.
7. Enables the `aprs.whre.be` HTTP VirtualHost.
8. Validates the Apache configuration.
9. Enables and starts ttyd.
10. Restarts Apache.

## SSL

SSL/Certbot is intentionally outside this project.

The included `aprs.whre.be.conf` redirects HTTP to HTTPS. After installing
the monitor, configure the certificate with Certbot separately.

The generated SSL VirtualHost is not included in this repository.

## Service

The ttyd service listens on:

```text
0.0.0.0:7688
```

It runs:

```bash
journalctl -u direwolf.service -n 15 -f -o cat
```

as user `aprs`.

Check it with:

```bash
systemctl status ttyd-direwolf.service
```

## Apache

The `/terminal` endpoint is proxied to:

```text
http://127.0.0.1:7688/
```

WebSocket requests are forwarded to:

```text
ws://127.0.0.1:7688/
```

Required modules:

```text
proxy_module
proxy_http_module
proxy_wstunnel_module
rewrite_module
ssl_module
```

Validate Apache with:

```bash
sudo /usr/sbin/apache2ctl configtest
```

## Uninstallation

```bash
sudo ./uninstall.sh
```

The uninstaller removes the monitor's systemd service, web page and
`aprs.whre.be` VirtualHost. It intentionally does not remove Apache, ttyd,
or their packages.

## Scope

This repository reproduces the currently working ttyd/WebSocket monitor.

It does not include the older experimental Python/ansi2html implementation,
nor does it parse APRS frames or classify traffic as `RX_IS`/`TX_RF`.
