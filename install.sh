#!/usr/bin/env bash

# -- Starting Zabbix Installation --

echo "Retrieving all available Zabbix major versions..."
ZABBIX_MAJORS=$(
  curl -s https://repo.zabbix.com/zabbix/ \
  | grep 'href=' \
  | sed -n 's/.*href="\([0-9]\+\.[0-9]\+\)\/".*/\1/p' \
  | sort -uV
)

if [ -z "$ZABBIX_MAJORS" ]; then
  echo "ERROR: Could not retrieve a list of major versions from https://repo.zabbix.com/zabbix/"
  exit 1
fi

# Берём самую последнюю (новую) версию
ZABBIX_MAJOR=$(echo "$ZABBIX_MAJORS" | tail -1)

echo "The latest major version of Zabbix (initial): $ZABBIX_MAJOR"

# Проверяем, существует ли stable/ в репозитории для найденной версии
CHECK_STABLE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://repo.zabbix.com/zabbix/${ZABBIX_MAJOR}/stable/")

if [ "$CHECK_STABLE_CODE" -ne 200 ]; then
  echo "No 'stable' folder found for Zabbix $ZABBIX_MAJOR. Trying the previous major version..."

  # Получаем предыдущую версию — вторую с конца
  ZABBIX_MAJOR_PREV=$(echo "$ZABBIX_MAJORS" | tail -2 | head -1)

  if [ -z "$ZABBIX_MAJOR_PREV" ]; then
    echo "ERROR: There is no previous version to fallback to!"
    exit 1
  fi

  # Дополнительно можно проверить stable-папку и у предыдущей версии
  CHECK_STABLE_PREV_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://repo.zabbix.com/zabbix/${ZABBIX_MAJOR_PREV}/stable/")
  if [ "$CHECK_STABLE_PREV_CODE" -ne 200 ]; then
    echo "ERROR: 'stable' folder does not exist for $ZABBIX_MAJOR_PREV either."
    echo "Cannot continue automatically. Please check Zabbix repository manually."
    exit 1
  fi

  # Если всё нормально, переключаемся на предыдущую версию
  ZABBIX_MAJOR="$ZABBIX_MAJOR_PREV"
fi

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

echo "Installing Zabbix Agent..."
# Сохраняем вывод команды в переменную OUTPUT
OUTPUT=$(yes 'N' | sudo DEBIAN_FRONTEND=noninteractive apt-get install -y zabbix-agent 2>&1)
INSTALL_EXIT_CODE=$?

# Если команда вернулась с ошибкой или в выводе есть строка о том, что нет кандидата — выходим
if [ $INSTALL_EXIT_CODE -ne 0 ] || echo "$OUTPUT" | grep -q "E: Package 'zabbix-agent' has no installation candidate"; then
  echo "ERROR: Failed to install zabbix-agent. It might have no installation candidate or another error occurred."
  exit 1
fi

echo "Restarting and enabling Zabbix Agent..."
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent

echo "Zabbix installation completed successfully!"
# -- End of Zabbix Installation --