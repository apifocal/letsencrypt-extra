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
    openssl x509 -noout -text -certopt no_header,no_version,no_serial,no_signame,no_issuer,no_pubkey,no_sigdump,no_aux 2>/dev/null | \
    {
	while read line
	do
	    case $line in
		Not\ Before* )
		    from="${line#*:}"
		    ;;
		Not\ After* )
		    to="${line#*:}"
		    ;;
		Subject* )
		    subject="${line#*CN=}"
		    ;;
		X509v3\ Subject\ Alternative\ Name* )
		    read alternative_names
		    alternative_names=$(echo ${alternative_names} | tr ", DNS:" " " | tr -s " ")
		    ;;
	    esac
	done
	status=0
	# service is probably down
	[ -z "$from" ] || [ -z "$to" ] || [ -z "$subject" ] && { status=1; status_message="invalid, failed to connect/obtain certificate information"; }
	from_seconds=`date --date="$from" "+%s"`
	to_seconds=`date --date="$to" "+%s"`
	now_seconds=`date "+%s"`
	seconds="$(($to_seconds - $now_seconds))"
	if [ $status -eq 0 ]
	then
	    [ $seconds -le 0 ] && { status=2; status_message="invalid, certificate expired $((-$seconds/86400)) days ago"; }
	    name_match=0
	    for alternative_name in $alternative_names
	    do
		# note that this does not support wildcard matching 
		[ "${service_name}" = "${alternative_name}" ] && name_match=1 && break
	    done
	    [ $name_match -eq 0 ] && { status=3; status_message="invalid, name ${service_name} does not match alternative names${alternative_names}"; }
	fi
	if [ "$format" = "h" ]
	then
	    [ $status -eq 0 ] && status_message="valid, for $(($seconds/86400)) days"
	    echo "${service_name}:${service_port} is ${status_message}"
	else
	    # status mapping: 0 - service OK, 1 - service down, 2 - service up but expired certificate, 3 - service up,certificate valid, but name does not match alternative names
	    if [ $status -eq 1 ]
	    then
		# since the service is down send only the status
		echo tls_verify,host=${service_name},port=${service_port} status=$status
	    else
		echo tls_verify,host=${service_name},port=${service_port} seconds_from_valid=$(($now_seconds - $from_seconds)),seconds_to_expire=$(($to_seconds - $now_seconds)),status=$status
	    fi
	fi
    }
