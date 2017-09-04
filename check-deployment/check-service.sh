#!/bin/sh

command -v openssl >/dev/null 2>&1 || { echo >&2 "openssl is require but it's not installed, aborting."; exit 1; }

service_name=$1
service_port=$2
format=$3

if [ -z "$service_name" ] || [ -z "$service_port" ]
then
  echo "Usage: check-servcice.sh host port"
  exit 1
fi

[ -z "$format" ] && format="h"

echo -n | \
openssl s_client -servername ${service_name} -connect ${service_name}:${service_port} 2>/dev/null | \
openssl x509 -noout -dates -fingerprint -subject -nameopt nofname | \
cut -d '=' -f 2 | \
{
  read from;
  read to;
  read sha1;
  read subject;
  subject="${subject##*,}"
  from_seconds=`date --date="$from" "+%s"`
  to_seconds=`date --date="$to" "+%s"`
  now_seconds=`date "+%s"`
  if [ "$format" = "h" ]
  then
      seconds="$(($to_seconds - $now_seconds))"
      [ $seconds -gt 0 ] && status="valid" || status="invalid"
      [ "${service_name}" != "$subject" ] && extra_status=" but subject ${subject} does not match name ${service_name}"
      echo "${service_name}:${service_port} is $status for $(($seconds/86400)) days${extra_status}"
  else
      echo tls_verify,host=${service_name},port=${service_port} seconds_from_valid=$(($now_seconds - $from_seconds)),seconds_to_expire=$(($to_seconds - $now_seconds)),sha1=\"$sha1\"
  fi
}
