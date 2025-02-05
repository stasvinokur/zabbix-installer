# Zabbix Installer

This script automatically installs the **latest** version of the Zabbix Agent or Zabbix Agent 2 on **Ubuntu** and **Debian**.

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