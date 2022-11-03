#!/usr/bin/env bash

#set -o errexit -o pipefail



# DESCRIPTION
# All of the numbers reported in this file are aggregates since the system first booted (1).
# So we can use them for counting the total CPU utilization and the vaule CPU spent in active
# time since boot. I use this algorithm:
#
# cpu_total=$(( user + nice + system + idle + iowait + irq + softirq + steal ))
# cpu_activ=$(( user + nice + system + irq + softirq + steal ))
#
# But this isn't the achieve we are looking for. To get a more real-time utilization, we simply
# repeat the steps above with some small sleep interval in between. And then we are able to count
# cpu_inpercent() using this algorithm (2):
#
# cpu_inpercent= 100 * [(cpu_activ_second_run - cpu_activ_first_run) : (cpu_total_second_run - cpu_total_first_run)]
#
# Related to above information the script has to do collect_data() twice. According to $run
# it saves data into two associative arrays cycle_1 and cycle_2 for the finall counting.

# (1) https://www.kernel.org/doc/Documentation/filesystems/proc.txt
# (2) https://rosettacode.org/wiki/Linux_CPU_utilization


# DESIGN
# 1. Collect data.
#  1.a Take all lines from /proc/stat which start with string "cpu."
#  1.b Split rows into values and fill them into arrays.

# 2. Count utilization.
#  2.a Count average of utilization of all CPUs.
#  2.b If there are more then one CPU, count utilization of them all.

# 3. Compare result with desired status and prepare output.


# TODO
# At 1. count_cpu_stats(): Eval is evil. 



warning="95"
critical="99"

declare -A cycle_1
declare -A cycle_2



# 1. Collect data.

run="1"
count_cpu_stats() {
  # 1.b Split rows into values and fill them into arrays.
  read -r cpu user nice system idle iowait irq softirq steal guest guest_nice <<< "${stat_row[@]}"

  cpu_total=$(( user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice ))
  cpu_activ=$(( user + nice + system + irq + softirq + steal ))

  eval cycle_${run}["$cpu"_total]="$cpu_total"
  eval cycle_${run}["$cpu"_activ]="$cpu_activ"
}

# Remember that this funcion is called twice.
# So $all_lines contains count of rows from /proc/stat which start by string "cpu" x 2.
all_lines="0"
collect_data() {
  while read -a stat_row; do
    #1.a Take all lines from /proc/stat which start with string "cpu."
    if [[ ${stat_row[0]:0:3} = cpu ]]; then
      count_cpu_stats
      ((all_lines++))
     fi
  done < /proc/stat
}

collect_data
sleep 1; ((run++))
collect_data



# 2. Count utilization.

count_percentage_utilization() {
cpu_utilization=$(( 100 *						\
  ( ${cycle_2[cpu${1}_activ]} - ${cycle_1[cpu${1}_activ]} ) /		\
  ( ${cycle_2[cpu${1}_total]} - ${cycle_1[cpu${1}_total]} )		\
))

if [[ -z $1 ]]; then
  total_cpu_usage=$cpu_utilization
fi

returned_values+="cpu${1}=${cpu_utilization}%;${warning}%;${critical}%;0;0 "
}

# 2.a Count average of utilization of all CPUs.
count_percentage_utilization

# Subtracting by one excepts the line with average values of all CPUs.
cpu_number=$(( (all_lines / 2) - 1 ))

# 2.b If there are more then one CPU, count utilization of them all.
if [[ cpu_number -ge 2 ]]; then
  # Iterate over all CPUs - start from cpu0.
  for (( number=0; number<=$(( cpu_number - 1 )); number++ )); do
    count_percentage_utilization $number
  done
fi



# 3. Prepare output.

echo "total_cpu_usage=${total_cpu_usage}% | $returned_values"
exit "$(( (total_cpu_usage > warning) + (total_cpu_usage > critical) ))"

