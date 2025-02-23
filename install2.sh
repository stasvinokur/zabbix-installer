#!/usr/bin/env bash

# -- Starting Zabbix Installation --
echo "Determining the latest major version of Zabbix..."
ZABBIX_MAJOR=$(curl -s https://repo.zabbix.com/zabbix/ | grep -Po '(?<=href=")\d+\.\d+/' | sed 's/\///' | sort -V | tail -1)
echo "The latest major version of Zabbix is: $ZABBIX_MAJOR"

# Detect distro and version
OS_NAME=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')
OS_VERSION=$(lsb_release -rs 2>/dev/null)

if [ -z "$OS_NAME" ] || [ -z "$OS_VERSION" ]; then
  echo "ERROR: Could not detect OS using 'lsb_release'. Make sure 'lsb_release' is installed."
  exit 1
fi

echo "Detected OS: $OS_NAME $OS_VERSION"

# We only handle Ubuntu or Debian in this script
if [[ "$OS_NAME" == "ubuntu" ]]; then
  # Ubuntu logic
  DISTRO_ID="ubuntu${OS_VERSION}"
elif [[ "$OS_NAME" == "debian" ]]; then
  # Debian logic
  DEBIAN_MAJOR=$(echo "$OS_VERSION" | cut -d '.' -f1)
  DISTRO_ID="debian${DEBIAN_MAJOR}"
else
  echo "ERROR: This installer supports only Ubuntu or Debian. Detected: $OS_NAME"
  exit 1
fi

echo "Searching for the zabbix-release package for: $DISTRO_ID"

ZABBIX_RELEASE_DEB=$(
  curl -s "https://repo.zabbix.com/zabbix/${ZABBIX_MAJOR}/release/${OS_NAME}/pool/main/z/zabbix-release/" \
  | grep -Po "zabbix-release_latest_${ZABBIX_MAJOR}\+${DISTRO_ID}_[^\"]*\.deb" \
  | sort -V | tail -1
)

if [ -z "$ZABBIX_RELEASE_DEB" ]; then
  echo "ERROR: Could not find a suitable zabbix-release .deb package for $DISTRO_ID!"
  echo "Make sure that Zabbix officially supports your OS version in the repository."
  exit 1
fi

ZABBIX_RELEASE_URL="https://repo.zabbix.com/zabbix/${ZABBIX_MAJOR}/release/${OS_NAME}/pool/main/z/zabbix-release/${ZABBIX_RELEASE_DEB}"
echo "Found zabbix-release package: ${ZABBIX_RELEASE_DEB}"
echo "URL: ${ZABBIX_RELEASE_URL}"

wget -O "${ZABBIX_RELEASE_DEB}" "${ZABBIX_RELEASE_URL}" || {
  echo "ERROR: Failed to download ${ZABBIX_RELEASE_URL}"
  exit 1
}

sudo dpkg -i "${ZABBIX_RELEASE_DEB}" || {
  echo "ERROR: Failed to install ${ZABBIX_RELEASE_DEB} via dpkg"
  exit 1
}

# Remove the downloaded .deb file if the installation was successful.
rm -f "${ZABBIX_RELEASE_DEB}"

echo "Running apt-get update..."
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

echo "Installing Zabbix Agent 2..."
yes 'N' | sudo DEBIAN_FRONTEND=noninteractive apt-get install -y zabbix-agent2

echo "Restarting and enabling Zabbix Agent 2..."
sudo systemctl restart zabbix-agent2
sudo systemctl enable zabbix-agent2

echo "Zabbix installation completed successfully!"
# -- End of Zabbix Installation --