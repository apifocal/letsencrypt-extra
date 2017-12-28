#!/bin/bash

CERTNAME="${RENEWED_LINEAGE##*/live/}"
LETSENCRYPT_DIR=/etc/letsencrypt
SECRETS_DIR=/etc/apifocal
LETSENCRYPT_EXTRA_DIR="${HOME}/src/letsencrypt-extra"

echo "CERTNAME=${CERTNAME}"
echo "LETSENCRYPT_DIR=${LETSENCRYPT_DIR}"
echo "RENEWED_LINEAGE=${RENEWED_LINEAGE}"
echo "RENEWED_DOMAINS=${RENEWED_DOMAINS}"

if [ -z "${CERTNAME}" ] ; then
    echo "CERTNAME missing; exiting"
    exit 1
fi

if [ ! -d "${LETSENCRYPT_EXTRA_DIR}" ] ; then
    echo "letsencrypt-extra dir is missing; exiting"
    exit 1
fi

set -e
set -u

CERTDIR="${LETSENCRYPT_DIR}/live/${CERTNAME}"

if [ -r "${CERTDIR}/keystore.jks" ] ; then
    echo "Updating java keystore file for ${CERTNAME}"
    "${LETSENCRYPT_EXTRA_DIR}/jks/update-jks" -f "${CERTNAME}" $(head -n 1 "${CERTDIR}/keystore.jks.pwd") "${CERTDIR}/keystore.jks"
    echo "Deploying secrets referencing '${CERTDIR}/keystore.jks'"
    find -L "${SECRETS_DIR}" -samefile "${CERTDIR}/keystore.jks" | \
	{
	    while read SECRET
	    do
		if [[ "$SECRET" =~ ^"${SECRETS_DIR}"/([^/]*)/secrets/(.*) ]] ; then
		    ENVIRONMENT=${BASH_REMATCH[1]}
		    SECRETNAME=${BASH_REMATCH[2]}
		    "${LETSENCRYPT_EXTRA_DIR}/rancher/deploy-secret.sh" update ${ENVIRONMENT} ${SECRETNAME} "${SECRETNAME} keystore"
		else
		    echo "Unable to extract environment and secret name from '${SECRET}'"
		fi
	    done
	}
else
    echo "${CERTNAME} not packed as java keystore"
fi
