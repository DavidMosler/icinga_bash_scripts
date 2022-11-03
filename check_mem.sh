#!/usr/bin/env bash

set -o errexit -o pipefail



# DESCRIPTION
# This script uses values from /proc/meminfo and counts used memory in percent.
# For caclucating is used algorithm from RedHat's article "Interpreting /proc/meminfo and
# free output for Red Hat Enterprise Linux 5, 6 and 7" (1):

# mem_used = MemTotal - MemFree - Buffers - Cached - Slab

# Be aware that the script has been written for Red Hat Enterprise Linux 7.1 or later and
# its derived distributions.

# (1) https://access.redhat.com/solutions/406773


# DESIGN
# 1. Collect data.
# 2. Count utilization as TOP and FREE utility do.
# ( used = total - free - buffers - cache )
# 3. Prepare output.



warning=80
critical=95



# 1. Collect data.

while read -r label number unit ; do
    case "$label" in
      MemTotal:)
        mem_total=$number
        ;;
      MemFree:)
        mem_free=$number
        ;;
      Buffers:)
        buffers=$number
        ;;
      Cached:)
        cached=$number
	;;
      Slab:)
        slab=$number
        ;;
    esac
done < /proc/meminfo



# 2. Count memory usage in percent.

mem_usage=$(( mem_total - mem_free - buffers - cached - slab ))
mem_usage_inpercent=$(( 100 * mem_usage / mem_total ))



# 3. Prepare output.

echo "memory_usage=$(( mem_usage / 1024 ))MiB (${mem_usage_inpercent}%) of"	\
     "memory_total=$(( mem_total / 1024 ))MiB |"				\
     "memory_usage %=${mem_usage_inpercent}%;$warning;$critical;0;100"  	\
     "memory_usage=${mem_usage}kB"

exit $(( (mem_usage_inpercent > warning) + (mem_usage_inpercent > critical) ))
