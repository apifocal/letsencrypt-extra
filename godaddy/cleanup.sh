#!/bin/bash

DRYRUN=true

#API_KEY=$(tr '\n' ' ' < ${HOME}/.netrc | sed 's/.*\smachine\s\+api.godaddy.com\s\+login\s\+\(\w\+\)\s\+password\s\+\(\w\+\)\s.*/\1:\2/')
#SHOPPER_ID=$(tr '\n' ' ' < ${HOME}/.netrc | sed 's/.*\smachine\s\+api.godaddy.com\s\+login\s\+\w\+\s\+password\s\+\w\+\s\+shopper\s\+\(\w\+\)\s.*/\1/')

API_KEY=$(cat $HOME/.godaddyrc)

[ -n "${SHOPPER_ID}" ] && SHOPPER_HEADER='-H "'"${SHOPPER_ID}"'"'

DOMAINS=$(curl -s -X GET "https://api.godaddy.com/v1/domains" \
               -H "Authorization: sso-key ${API_KEY}" ${SHOPPER_HEADER} \
                 | jq -r '.[] | .domain' | sort -u)
#DOMAINS=silkmq.net

for DOMAIN in ${DOMAINS} ; do
    if ${DRYRUN} ; then
        curl -s -X GET "https://api.godaddy.com/v1/domains/${DOMAIN}/records/TXT" \
             -H "Authorization: sso-key ${API_KEY}" ${SHOPPER_HEADER} \
            | jq -r '.[] | select(.name | test("_acme-challenge.*")) | .name + "." + "'"$DOMAIN"'"'
    else
        NAMES=$(curl -s -X GET "https://api.godaddy.com/v1/domains/${DOMAIN}/records/TXT" \
                     -H "Authorization: sso-key ${API_KEY}" ${SHOPPER_HEADER} \
                       | jq -r '.[] | select(.name | test("_acme-challenge.*")) | .name')
#        NAMES=_acme-challenge
        for NAME in $NAMES ; do
            curl -s -X PUT "https://api.godaddy.com/v1/domains/${DOMAIN}/records/TXT/${NAME}" \
                 -H "Authorization: sso-key ${API_KEY}" ${SHOPPER_HEADER} \
                 --data '[]' \
                | jq .
        done
    fi
done
