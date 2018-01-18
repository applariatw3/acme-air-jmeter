#!/bin/sh
export APP_DIR=/usr/local/jmeter
export JMETER_DIR=$APP_DIR/jmeter-3.1

CONCUR_THREAD=${CONCUR_THREAD:-100}

echo "Printing build log"
cat /tmp/build.log

cd $APP_DIR/scripts

#update web host name if ACME_WEB_HOST is set
if [ -z "${ACME_WEB_HOST}" ]; then
   echo "Using default ACME_WEB_HOST=acmeair-web"
   export ACME_WEB_HOST=acmeair-web
else
   echo "${ACME_WEB_HOST}" > hosts.csv
fi

if [ -z "${ACME_WEB_PORT}" ]; then
   echo "Using default ACME_WEB_PORT=3000"
   export ACME_WEB_PORT=3000
fi

#echo "Waiting 2 min"
#sleep 120
echo "Clearing old results"
rm -f *.jtl *.log
echo "Loading the database"
[ $RUN_LOADER -eq 1 ] && curl -Ss http://${ACME_WEB_HOST}:${ACME_WEB_PORT}/rest/api/loader/load?numCustomers=10000
echo
echo "Starting Acme Load Generator"
exec $JMETER_DIR/bin/jmeter -DusePureIDs=true -n -t ${JM_SCRIPT}.jmx -l ${JM_SCRIPT}.jtl -Jwebport=${ACME_WEB_PORT} -Jcthread=${CONCUR_THREAD}
#exec $@
