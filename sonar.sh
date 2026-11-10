#!/bin/bash
set -euo pipefail

# Run with: sudo bash install-sonarqube.sh

VERSION="26.11.0.134175"
SONAR_HOME="/opt/sonarqube-${VERSION}"

# Install dependencies
dnf install -y wget unzip java-21-amazon-corretto-devel

# Create the application user
if ! id sonar &>/dev/null; then
    useradd --create-home --user-group --shell /bin/bash sonar
fi

# Configure Linux kernel limits
cat > /etc/sysctl.d/99-sonarqube.conf <<'EOF'
vm.max_map_count=524288
fs.file-max=131072
EOF

sysctl -p /etc/sysctl.d/99-sonarqube.conf

# Configure limits for sonar login sessions
cat > /etc/security/limits.d/99-sonarqube.conf <<'EOF'
sonar soft nofile 131072
sonar hard nofile 131072
sonar soft nproc 8192
sonar hard nproc 8192
EOF

# Download and extract
cd /opt
wget -O "sonarqube-${VERSION}.zip" \
    "https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${VERSION}.zip"

unzip -q "sonarqube-${VERSION}.zip"

# Set ownership; do not use chmod 777
chown -R sonar:sonar "$SONAR_HOME"

# Start explicitly as sonar
runuser -l sonar -c \
    "$SONAR_HOME/bin/linux-x86-64/sonar.sh start"
