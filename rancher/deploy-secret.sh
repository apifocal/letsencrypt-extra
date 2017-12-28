#!/bin/bash

COMMAND="$1"
ENVIRONMENT="$2"
SECRETNAME="$3"
SECRETDESCRIPTION="$4"

echo "$(basename $0) $COMMAND $ENVIRONMENT $SECRETNAME $SECRETDESCRIPTION"

ENVTAB="${HOME}/.envtab"

ARGS=good
[ -z "${SECRETNAME}" ] && ARGS=bad
[ -z "${ENVIRONMENT}" ] && ARGS=bad
[ -z "${COMMAND}" ] && ARGS=bad

if [ ${ARGS} != good ] ; then
    echo "usage: $(basename $0) <command> <environment> <secret> [description]"
    echo "  - command can be 'create', 'update', 'delete' or 'create-or-update'"
    exit 1
fi

if ! whereis jq > /dev/null ; then
    echo "this program needs jq (https://stedolan.github.io/jq/) installed"
    exit 1
fi

if [ ! -r "${ENVTAB}" ] ; then
    echo "${ENVTAB} missng. please create it"
    exit 1
fi

read -r CODENAME RANCHER_URL PROJECT_ID APIKEY < <(grep "^${ENVIRONMENT}\s" "${ENVTAB}")
[ -z "$CODENAME" ] && { echo "environment ${ENVIRONMENT} not found"; exit 1; }
[ -z "$RANCHER_URL" ] && { echo "environment ${ENVIRONMENT} not found"; exit 1; }
[ -z "$PROJECT_ID" ] && { echo "environment ${ENVIRONMENT} not found"; exit 1; }

[ "$CODENAME" != "$ENVIRONMENT" ] && { echo "CODENAME $CODENAME != ENVIRONMENT $ENVIRONMENT"; exit 1; }

[ -z "$APIKEY" ] && CURL_AUTH="--netrc" || CURL_AUTH="-u ${APIKEY}"


set -e
set -u

SECRET=$(base64 "/etc/apifocal/${ENVIRONMENT}/secrets/${SECRETNAME}")

SECRET_JSON=$(cat << _EOF | tr --delete '\n'
{

    "description": "${SECRETDESCRIPTION}",
    "name": "${SECRETNAME}",
    "value": "${SECRET}"

}
_EOF
	   )

RANCHER_SECRETS_URL="${RANCHER_URL}/v2-beta/projects/${PROJECT_ID}/secrets"
JQ_FILTER=".data[] | select(.name==\"${SECRETNAME}\") | .id"
RANCHER_SECRET_ID=$(curl -s ${CURL_AUTH} -X GET "${RANCHER_SECRETS_URL}" |
                        jq -r "${JQ_FILTER}")

case "${COMMAND}" in
    create)
        CURL_METHOD=POST
        CURL_URL="${RANCHER_URL}/v2-beta/projects/${PROJECT_ID}/secrets"
        ;;
    delete)
        CURL_METHOD=DELETE
        CURL_URL="${RANCHER_URL}/v2-beta/projects/${PROJECT_ID}/secrets/${RANCHER_SECRET_ID}"
        ;;
    update)
        if [ -z "${RANCHER_SECRET_ID}" ] ; then
	    echo "Secret not present in environment ${ENVIRONMENT}"
	    exit 0
	fi
	;&
    create-or-update)
	if [ ! -z "${RANCHER_SECRET_ID}" ] ; then
	    CURL_METHOD=DELETE
	    CURL_URL="${RANCHER_URL}/v2-beta/projects/${PROJECT_ID}/secrets/${RANCHER_SECRET_ID}"
	    curl -s ${CURL_AUTH} -X "${CURL_METHOD}" -H 'Content-Type: application/json' -d "${SECRET_JSON}" "${CURL_URL}" |
		jq -r 'if (.type == "error") then "error: status="+(.status|tostring)+", code="+(.code|tostring)+", detail="+(.detail|tostring) else "success" end'
	fi
	CURL_METHOD=POST
	CURL_URL="${RANCHER_URL}/v2-beta/projects/${PROJECT_ID}/secrets"
	;;
    **)
esac

curl -s ${CURL_AUTH} -X "${CURL_METHOD}" -H 'Content-Type: application/json' -d "${SECRET_JSON}" "${CURL_URL}" |
    jq -r 'if (.type == "error") then "error: status="+(.status|tostring)+", code="+(.code|tostring)+", detail="+(.detail|tostring) else "success" end'
