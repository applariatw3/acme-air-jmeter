#!/bin/bash
set -e # Exit with nonzero exit code if anything fails
DEPLOYMENT=${1:?Missing required deployment name or id}

set +e

#function to check the exit status of a command
get_status(){
  if [ $? -ne 0 ]
  then
    echo "[!] ERROR: Something went wrong. Please check the logs."
    exit 1
  fi
}

#function to get deployment
get_deployment(){
  curl -sS -H "$1" -H "Content-Type:application/json" $API_URL/deployments/$2 | jq -c '.data'
}

#main script
#Load conf file
#echo making sure conf file is present
[ -f ./loader.conf ] || { echo "[!] ERROR: Missing loader.conf config file. Aborting."; exit 1; }

#echo conf file found, importing conf file...
source ./loader.conf
get_status

#Pull deployment information
deployment_rec=$(get_deployment "$API_KEY" "$DEPLOYMENT")
get_status
#echo $deployment_rec

DID=$(echo $deployment_rec | jq -r '.id')
ACME_WEB=$(echo $deployment_rec | jq -r '.status.summary.http_links."node-service"[0].ip')

OIFS=$IFS
IFS=":"

web_parts=($ACME_WEB)

IFS=$OIFS


#Create base load
echo "Launching Jmeter Container with base load script"
./run_jmeter.sh ${web_parts[0]} ${web_parts[1]} 1 aa-base $LOAD_STEP 1

COUNTER=1

while [ $COUNTER -lt $LOAD_LOOPS ]; do
    sleep $LOAD_TIMER
    echo "Launching Jmeter Container with base load script"
    ./run_jmeter.sh ${web_parts[0]} ${web_parts[1]} 0 aa-exload $LOAD_STEP $COUNTER
    let COUNTER=COUNTER+1
done

echo "All load loops started"
docker ps

exit 0
