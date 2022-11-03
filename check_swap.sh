#!/usr/bin/env bash

set -o errexit -o pipefail



# DESCRIPTION
# This script uses values from /proc/meminfo and count used swap in percent.



warning=80
critical=90



# 1. Collect data.

while read -r label number unit ; do
  case "$label" in
    SwapTotal:)
      swap_total=$number
      ;;
    SwapFree:)
      swap_free=$number
      ;;
  esac
done < /proc/meminfo



# 2. Count utilization.

swap_usage=$(( swap_total - swap_free ))
swap_usage_inpercent=$(( 100 * swap_usage / swap_total ))



# 3. Prepare output.

echo "swap_usage=$(( swap_usage / 1024 ))MiB (${swap_usage_inpercent}%) of"	\
     "swap_total=$(( swap_total / 1024 ))MiB |"					\
     "swap_usage %=${swap_usage_inpercent}%;${warning};${critical};0;100"	\
     "swap_usage=${swap_usage}kB"

exit $(( (swap_usage_inpercent > warning) + (swap_usage_inpercent > critical) ))
