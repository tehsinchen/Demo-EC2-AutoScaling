TARGET_HOST ?=
THREADS     ?= 150
RAMP        ?= 20
DURATION    ?= 180
CORES       ?= 2
SECONDS     ?= 30
JMETER_BIN  ?= /opt/jmeter/bin/jmeter
JMX         ?= /opt/jmeter/test.jmx
REPORT_DIR  ?= /opt/jmeter/reports/$(shell date +%Y%m%d-%H%M%S)

load:
    mkdir -p $(REPORT_DIR)
    $(JMETER_BIN) -n -t $(JMX) \
     -Jtarget_host=$(TARGET_HOST) \
     -Jthreads=$(THREADS) -Jrampup=$(RAMP) -Jduration=$(DURATION) \
     -Jcores=$(CORES) -Jseconds=$(SECONDS) \
     -l $(REPORT_DIR)/results.jtl -e -o $(REPORT_DIR)/html

smoke: THREADS=10 RAMP=5 DURATION=30 CORES=1 SECONDS=10
smoke: load

spike: THREADS=300 RAMP=10 DURATION=120 CORES=2 SECONDS=30
spike: load

soak: THREADS=100 RAMP=60 DURATION=900 CORES=2 SECONDS=30
soak: load

lastreport:
    @ls -1dt /opt/jmeter/reports/*/html 2>/dev/null | head -1 || echo "No reports yet"