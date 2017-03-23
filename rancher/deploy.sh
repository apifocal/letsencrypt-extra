#!/bin/bash

COMMAND="$1"
CERTNAME="$2"
ENVIRONMENT="$3"

#LETSENCRYPT_DIR=/etc/letsencrypt
LETSENCRYPT_DIR=/home/cipi/letsencrypt
ENVTAB="${HOME}/.envtab"

ARGS=good
[ -z "${CERTNAME}" ] && ARGS=bad
[ -z "${ENVIRONMENT}" ] && ARGS=bad
[ -z "${COMMAND}" ] && ARGS=bad        

if [ ${ARGS} != good ] ; then
    echo "usage: $(basename $0) <command> <certname> <environment>"
    echo "  - command can be 'create', 'update', 'delete' or 'create-or-update'"
    exit 1
fi

if ! whereis jq > /dev/null ; then
    echo "this program needs jq (https://stedolan.github.io/jq/) installed"
    exit 1
fi

if ! -f ${ENVTAB} ; then
    echo "${ENVTAB} missng. please create it"
    exit 1
fi


set -e
set -u

CERTDIR="${LETSENCRYPT_DIR}/live/${CERTNAME}"

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


grep "^${ENVIRONMENT}\s" | read -r CODENAME RANCHER_URL PROJECT_ID APIKEY
[[ -z "$CODENAME" ]] && continue
[[ -z "$RANCHER_URL" ]] && continue
[[ -z "$PROJECT_ID" ]] && continue

# only parse the environment we need
[[ "$CODENAME" != "$ENVIRONMENT" ]] && continue

[[ -z "$APIKEY" ]] && CURL_AUTH="--netrc" || CURL_AUTH="-u ${APIKEY}"

RANCHER_CERTS_URL="${RANCHER_URL}/v1/projects/${PROJECT_ID}/certificates"
JQ_FILTER=".data[] | select(.CN==\"${CERTNAME}\") | .id"
RANCHER_CERT_ID=$(curl -s ${CURL_AUTH} -X GET "${RANCHER_CERTS_URL}" |
                         jq -r "${JQ_FILTER}")

case "${COMMAND}" in
    create)
        CURL_METHOD=POST
        CURL_URL="${RANCHER_URL}/v1/projects/${PROJECT_ID}/certificates"
        ;;
    update)
        CURL_METHOD=PUT
        CURL_URL="${RANCHER_URL}/v1/projects/${PROJECT_ID}/certificates/${RANCHER_CERT_ID}"
        ;;
    delete)
        CURL_METHOD=DELETE
        CURL_URL="${RANCHER_URL}/v1/projects/${PROJECT_ID}/certificates/${RANCHER_CERT_ID}"
        ;;
    create-or-update)
        if [ -z "${RANCHER_CERT_ID}" ] ; then
            CURL_METHOD=POST
            CURL_URL="${RANCHER_URL}/v1/projects/${PROJECT_ID}/certificates"
        else
            CURL_METHOD=PUT
            CURL_URL="${RANCHER_URL}/v1/projects/${PROJECT_ID}/certificates/${RANCHER_CERT_ID}"
        fi
        ;;
    **)
esac

curl -s ${CURL_AUTH} -X "${CURL_METHOD}" -H 'Content-Type: application/json' -d "${CERT_JSON}" "${CURL_URL}" |
    jq -r 'if (.type == "error") then "error: status="+(.status|tostring)+", code="+(.code|tostring)+", detail="+(.detail|tostring) else "success" end'

