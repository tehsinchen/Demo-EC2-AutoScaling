#!/usr/bin/env bash
# Usage: install_jmeter.sh <JMETER_VERSION>
set -euo pipefail
JM="${1:-5.6.3}"

# Basic tooling + Java 17 (headless)
sudo dnf install -y tar gzip unzip java-17-amazon-corretto-headless

# Install JMeter
cd /opt
sudo curl -L -o "apache-jmeter-${JM}.tgz" \
  "https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JM}.tgz" || \
sudo curl -L -o "apache-jmeter-${JM}.tgz" \
  "https://downloads.apache.org/jmeter/binaries/apache-jmeter-${JM}.tgz"
sudo tar xzf "apache-jmeter-${JM}.tgz"
sudo ln -sfn "/opt/apache-jmeter-${JM}" /opt/jmeter

# Convenience PATH for interactive sessions
sudo tee /etc/profile.d/jmeter.sh >/dev/null <<'EOF'
export JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto.x86_64
export PATH=$JAVA_HOME/bin:/opt/jmeter/bin:$PATH
EOF
sudo chmod +x /etc/profile.d/jmeter.sh