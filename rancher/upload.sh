#!/bin/bash

CERTNAME="$1"
CODENAME="$2"
APIKEY="$3"
CERTID="$4"

# TODO: better API (e.g. paste URL from brower towards both rancher and its environment, perhaps? e.g. https://rancher.internal.apifocal.org/env/1a5/infra/certificates)
# TODO: better auth options - use API KEY instead
# TODO: automatically detect if we want to create or update an existing certificate

if [[ $# -ne 3 && $# -ne 4 ]] ; then
  echo "usage: $(basename $0) <cert-name> <codename> <apikey> [<cert-id>]"
  echo "  - codename = rancher server codename"
  echo "  - apikey = rancher api key in the form username:password" 
  echo "sample create: $(basename $0) archiva.apifocal.org internal USERNAME:PASSWORD"
  echo "sample update: $(basename $0) archiva.apifocal.org internal USERNAME:PASSWORD 1c4"
  exit 1
fi

set -e
set -u

LETSENCRYPT_DIR=/etc/letsencrypt
#LETSENCRYPT_DIR=/home/cipi/letsencrypt
CERTDIR="${LETSENCRYPT_DIR}/live/${CERTNAME}"

case ${CODENAME} in
    internal)
        RANCHER_URL="https://rancher.internal.apifocal.org"
	PROJECT_ID="1a5"
	;;
    stage)
        RANCHER_URL="https://rancher.stage.apifocal.org"
	PROJECT_ID="1a5"
	;;
    production)
        RANCHER_URL="https://rancher.apifocal.org"
	PROJECT_ID="1a5"
	;;
    *)
        echo "Unknown codename ${CODENAME}"
	exit 2
	;;
esac

CERT_RAW=$(<"${CERTDIR}/cert.pem")
CHAIN_RAW=$(<"${CERTDIR}/chain.pem")
PRIVKEY_RAW=$(<"${CERTDIR}/privkey.pem")

CERT="${CERT_RAW//$'\n'/\\n}"
CHAIN="${CHAIN_RAW//$'\n'/\\n}"
PRIVKEY="${PRIVKEY_RAW//$'\n'/\\n}"

CERT_JSON=$(cat << _EOF | tr --delete '\n'
{
    "type": "certificate",
    "cert": "${CERT}",
    "certChain": "${CHAIN}",
    "key": "${PRIVKEY}",
    "name": "${CERTNAME}"
}
_EOF
)

if [ -z "${CERTID}" ] ; then
    # create new certificate
    curl -u "${APIKEY}" -X POST -H 'Content-Type: application/json' -d "${CERT_JSON}" "${RANCHER_URL}/v1/projects/${PROJECT_ID}/certificates"
else
    # update existing certificate
    curl -u "${APIKEY}" -X PUT -H 'Content-Type: application/json' -d "${CERT_JSON}" "${RANCHER_URL}/v1/projects/${PROJECT_ID}/certificates/${CERTID}"
fi

