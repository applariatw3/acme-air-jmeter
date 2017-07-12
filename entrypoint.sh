#!/bin/sh
export APP_DIR=/usr/local/jmeter
export JMETER_DIR=$APP_DIR/jmeter-3.1

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

echo "Waiting 2 min"
sleep 120
echo "Loading the database"
curl -Ss http://${ACME_WEB_HOST}:${ACME_WEB_PORT}/rest/api/loader/load?numCustomers=10000

echo "Starting Acme Driver"
exec $JMETER_DIR/bin/jmeter -DusePureIDs=true -n -t AcmeAir.jmx -l AcmeAir1.jtl -Jwebport=${ACME_WEB_PORT}

echo "Acme Driver Run Completed Successfully"
echo "Pushing results for review"
cat AcmeAir1.jtl
