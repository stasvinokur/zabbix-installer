# Zabbix Installer

This script automatically installs the **latest** version of the Zabbix Agent or Zabbix Agent 2 on **Ubuntu** and **Debian**.

## Why use this script?
Manually finding and installing the correct Zabbix repository packages can be error-prone and time-consuming, especially if you need the latest release. This script automates:
- Detecting your OS version (Ubuntu or Debian).
- Retrieving the matching Zabbix repository package for your system.
- Installing either the standard Zabbix Agent or Zabbix Agent 2.
- Ensuring the service is properly started and enabled.

By running a single command, you get a fully configured and up-to-date Zabbix Agent, saving you from manual package lookups and potential compatibility issues.

## Installation

Make sure you have `curl` installed. If not, install it first:
```bash
sudo apt-get install -y curl
```

## Zabbix Agent
To install **Zabbix Agent**, use:
```bash
curl -fsSL https://raw.githubusercontent.com/stasvinokur/zabbix-installer/main/install.sh | bash
```

## Zabbix Agent 2

To install **Zabbix Agent 2**, use:
```bash
curl -fsSL https://raw.githubusercontent.com/stasvinokur/zabbix-installer/main/install2.sh | bash
```