#!/bin/bash

CERTNAME="${RENEWED_LINEAGE##*/live/}"
LETSENCRYPT_DIR=/etc/letsencrypt

echo "CERTNAME=${CERTNAME}"
echo "LETSENCRYPT_DIR=${LETSENCRYPT_DIR}"
echo "RENEWED_LINEAGE=${RENEWED_LINEAGE}"
echo "RENEWED_DOMAINS=${RENEWED_DOMAINS}"

if [ -z "${CERTNAME}" ] ; then
    echo "CERTNAME missing; exiting"
    exit 1
fi

set -e
set -u

CERTDIR="${LETSENCRYPT_DIR}/live/${CERTNAME}"

if [ -r "${CERTDIR}/keystore.jks" ] ; then
    echo "Updating java keystore file for ${CERTNAME}"
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    ${DIR}/update-jks -f "${CERTNAME}" $(head -n 1 "${CERTDIR}/keystore.jks.pwd") "${CERTDIR}/keystore.jks"
else
    echo "${CERTNAME} not packed as java keystore"
fi
