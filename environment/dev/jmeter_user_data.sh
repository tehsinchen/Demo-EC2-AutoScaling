#!/bin/bash
set -Eeuo pipefail
echo "===== JMeter AMI ready =====" | tee -a /var/log/jmeter.log
echo "Use: sudo /usr/local/bin/run-jmeter.sh <ALB_DNS> [threads ramp duration cores seconds]" | tee -a /var/log/jmeter.log
# Ensure Corretto & JMeter are on PATH for interactive shells
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto.x86_64' >> /etc/profile.d/jmeter.sh
echo 'export PATH=$JAVA_HOME/bin:/opt/jmeter/bin:$PATH' >> /etc/profile.d/jmeter.sh
chmod +x /etc/profile.d/jmeter.sh
