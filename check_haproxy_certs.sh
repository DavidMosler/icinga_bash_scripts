#!/usr/bin/env bash



CERTIFICATES_PATH="/etc/haproxy/certs"
DAYS_TO_CHECK="7"

secs_to_check="$(( $DAYS_TO_CHECK * 24 * 60 * 60 ))"
exit_code="0"

declare -a check_these_certificates

for certificate in $(ls $CERTIFICATES_PATH); do
   if /bin/openssl x509 -checkend $secs_to_check -noout -in ${CERTIFICATES_PATH}/${certificate} > /dev/null; then 
      continue
   else
      expiration_date=$( openssl x509 -enddate -noout -in ${CERTIFICATES_PATH}/${certificate} | awk '{sub(/^notAfter\=/,"",$1); print $1 " " $2 " " $4}')
      check_these_certificates+=("${certificate} (expiration at ${expiration_date})")
      exit_code="2"
   fi
done

if [[ exit_code -gt 0 ]]; then
   printf '%s\n' "Following certificates are going to expire less than 7 days:"
   printf '%s\n' "${check_these_certificates[@]}"
else
   printf '%s\n' "OK"
fi

exit $exit_code

