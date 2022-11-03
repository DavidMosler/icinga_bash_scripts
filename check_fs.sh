#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail



# DESCRIPTION
# It checks percentage usage of all LOCAL filesystems.



warning=80
critical=95

declare -a output_text
declare -a output_data
exit_code="0"



while read -r filesystem _ _ _ used mountpoint; do
  if [[ ${filesystem:0:4} = "/dev" ]] && [[ ${filesystem:0:8} != "/dev/sr0" ]]; then
    code="$(( ( ${used%"%"} > warning ) + ( ${used%"%"} > critical ) ))"

    if [[ $code -gt 0 ]]; then
      output_text+=("${mountpoint}=${used%"%"}%")

      # Never decrease the exit_code value!
      if [[ $code -gt $exit_code ]]; then
        exit_code="$code"
      fi
    fi

    output_data+=("${mountpoint}=${used%"%"}%;${warning}%;${critical}%;;")
  fi
done < <( df --portability )


if [[ exit_code -gt 0 ]]; then
  echo "CHECK" "${output_text[@]}" "|" "${output_data[@]}"
else
  echo "OK |" "${output_data[@]}"
fi


