#!/usr/bin/env bash

set -o errexit -o pipefail



# DESCRIPTION
# Script for checking if a server declared in /etc/keepalived/keepalived.conf as a master,
# is really master or slave.



config_file="/etc/keepalived/keepalived.conf"


# 1. Who am I?.
read _ my_state < <(grep state < $config_file)


# 2. Which is the floating ip?
read floating_ip _ _ < <(grep dev < $config_file)


# 3. Check all IPs on server.
declare -a server_ips

while read -a row; do
  # Remove everything after first slash.
  potential_ip="${row[1]%%/*}"

  case $potential_ip in
    link|host|universe)
      ;;
    *)
      server_ips+=($potential_ip);;
  esac
done < /proc/net/fib_trie


# 4. Return resutls.

if [[ ${server_ips[*]} =~ "$floating_ip" ]] && [[ $my_state = "MASTER" ]]; then
   echo "OK"
   exit 0
fi

if ! [[ ${server_ips[*]} =~ "$floating_ip" ]] && [[ $my_state = "BACKUP" ]]; then
   echo "OK"
   exit 0
fi

echo "Check the master node!"
exit 2

