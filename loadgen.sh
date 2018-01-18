#!/bin/bash
set -e # Exit with nonzero exit code if anything fails
ACME_WEB_HOST=${1:?Missing required input Web Host}
ACME_WEB_PORT=${2:?Missing required input Web Host}
BASE_LOAD_TIME=${3:-300}

set +e

./run_jmeter.sh $ACME_WEB_HOST $ACME_WEB_PORT 1 aa-base 1000

sleep $BASE_LOAD_TIME

./run_jmeter.sh $ACME_WEB_HOST $ACME_WEB_PORT 0 aa-exload 1000

