#!/usr/bin/env bash

set -o errexit -o pipefail



# DESCRIPTION
# This script counts load average using values from /proc/loadavg - more precisely it
# counts with 15-minute averages. Frankly, if your box spikes above 1.0 on the one-minute
# average, you're still fine. It's when the 15-minute average goes north of 1.0 and stays
# there that you need to snap to (1).
#    Collected data are compared with number of CPU cores. Notice that How the cores are
# spread out over CPUs doesn't matter. Two quad-cores == four dual-cores == eight single-cores.
# It's all eight cores for these purposes (2).
#    Sometimes it's helpful to consider load as percentage of the available resources
# (the load value divided by the number or cores) (3). So the output is served this way.

# (1,2) Andre Lewis, https://scoutapm.com/blog/understanding-load-averages
# (3) RedHat, https://access.redhat.com/solutions/30554


# DESIGN
# 1. Collect data.
# 2. Convert load into percentage.
# 3. Compare result with desired status and prepare output.



warning=95
critical=100



# 1. Collect data.

read -r _ _ quarter_load_average _ _ < /proc/loadavg


while read -a row; do
  if [[ ${row[0]} = "cpu" ]] && [[ ${row[1]} = "cores" ]]; then
    cpu_cores=$(( cpu_cores + row[3] ))
  fi
done < /proc/cpuinfo



# 2. Convert load value into percentage.

# Divide by 1 is a little hack to remove decimal point from a result.
load_mlt=$(bc <<< "$quarter_load_average*100/1")
load_prc=$(( $load_mlt / cpu_cores ))



# 3. Compare result with desired status and prepare output.

echo "cpu_cores=$cpu_cores load=$quarter_load_average | load_in_percentage=$load_prc;$warning;$critical"
exit $(( (load_prc > warning) + (load_prc > critical) ))

