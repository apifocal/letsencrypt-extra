#!/bin/bash


#API_KEY=$(tr '\n' ' ' < ${HOME}/.netrc | sed 's/.*\smachine\s\+api.godaddy.com\s\+login\s\+\(\w\+\)\s\+password\s\+\(\w\+\)\s.*/\1:\2/')
#SHOPPER_ID=$(tr '\n' ' ' < ${HOME}/.netrc | sed 's/.*\smachine\s\+api.godaddy.com\s\+login\s\+\w\+\s\+password\s\+\w\+\s\+shopper\s\+\(\w\+\)\s.*/\1/')

API_KEY=$(cat $HOME/.godaddyrc)

[ -z "${API_KEY}" ] && { echo "no API key available"; exit 1; }

# Strip the domain from the subdomain
DOMAIN=$(expr match "$CERTBOT_DOMAIN" '.\+\.\([^.]\+\.[^.]\+\)')
SUBDOMAIN=$(expr match "$CERTBOT_DOMAIN" '\(.\+\)\.[^.]\+\.[^.]\+')
[ -z "${SUBDOMAIN}" ] && DOMAIN=$(expr match "$CERTBOT_DOMAIN" '\([^.]\+\.[^.]\+\)')

# No domain found
[ -z "${DOMAIN}" ] && { echo "could not determine domain"; exit 1; }

# prepare REST request
[ -z "${SUBDOMAIN}" ] && RECORD_NAME="_acme-challenge" || RECORD_NAME="_acme-challenge.$SUBDOMAIN"
[ -n "${SHOPPER_ID}" ] && SHOPPER_HEADER='-H "'"${SHOPPER_ID}"'"'

# for debugging
if false ; then
    curl -s -X GET "https://api.godaddy.com/v1/domains/${DOMAIN}/records" \
         -H "Authorization: sso-key ${API_KEY}" ${SHOPPER_HEADER} \
        | jq .
fi


# Create TXT record
curl -s -X PUT "https://api.godaddy.com/v1/domains/${DOMAIN}/records/TXT/$RECORD_NAME" \
     -H "Authorization: sso-key ${API_KEY}" ${SHOPPER_HEADER} \
     -H "Content-Type: application/json" \
     --data '{"type":"TXT","name":"'"$RECORD_NAME"'","data":"'"$CERTBOT_VALIDATION"'","ttl":600}' \
   | jq .


# Sleep to make sure the change has time to propagate over to DNS
sleep 1
