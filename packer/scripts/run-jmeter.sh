#!/usr/bin/env bash
set -euo pipefail
HOST=${1:-}
THREADS=${2:-150}
RAMP=${3:-20}
DURATION=${4:-180}
CORES=${5:-2}
SECS=${6:-30}
if [[ -z "$HOST" ]]; then
  echo "Usage: run-jmeter.sh <ALB_DNS> [threads ramp duration cores seconds]"
  exit 1
fi
export JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto.x86_64
export PATH="$JAVA_HOME/bin:/opt/jmeter/bin:$PATH"
TS="$(date +%Y%m%d-%H%M%S)"; OUT="/opt/jmeter/reports/${TS}"
mkdir -p "$OUT"
jmeter -n -t /opt/jmeter/test.jmx \
  -Jtarget_host="$HOST" -Jthreads="$THREADS" -Jrampup="$RAMP" -Jduration="$DURATION" \
  -Jcores="$CORES" -Jseconds="$SECS" -l "$OUT/results.jtl" -e -o "$OUT/html"
echo "Report: $OUT/html"