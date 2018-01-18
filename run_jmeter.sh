#!/bin/bash
set -e # Exit with nonzero exit code if anything fails
ACME_WEB_HOST=${1:?Missing required input Web Host}
ACME_WEB_PORT=${2:-3000}
RUN_LOADER=${3:-1}
JM_SCRIPT=${4:-aa-base}
CONCUR_THREAD=${5:-200}

set +e

DARGS="-e ACME_WEB_HOST=$ACME_WEB_HOST \
 -e ACME_WEB_PORT=$ACME_WEB_PORT \
 -e RUN_LOADER=$RUN_LOADER \
 -e JM_SCRIPT=$JM_SCRIPT \
 -e CONCUR_THREAD=$CONCUR_THREAD \
 -v /Users/wwatson/GitHub/acme-air-jmeter-fork/code/scripts:/usr/local/jmeter/scripts"

#for normal run
docker run -d --name ${JM_SCRIPT} $DARGS applariat/aa-jmeter
#for testing
#docker run --rm -it --name ${JM_SCRIPT} $DARGS applariat/aa-jmeter
