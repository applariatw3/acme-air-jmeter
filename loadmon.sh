#!/bin/bash
DEPLOYMENT=$1

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


#function to update smart config
update_sm_config(){
    cat > sm_config.json << EOL
{"data":{"desired_load":$2}}
EOL

  curl -Ss  -H "$1" -H "Content-Type:application/json" -X POST --data @./sm_config.json $API_URL/analytics/$3/config | jq '.'
}

#Main Loop

#Load conf file
echo making sure conf file is present
[ -f ./loadmon.conf ] || { echo "[!] ERROR: Missing apl.conf config file. Aborting."; exit 1; }

echo conf file found, importing conf file...
source ./loadmon.conf
get_status

echo "Running loadmon for appLariat Deployment $DEPLOYMENT at $API_URL"

#Pull deployment information
deployment_rec=$(get_deployment "$API_KEY" "$DEPLOYMENT")
get_status
#echo $deployment_rec

DID=$(echo $deployment_rec | jq -r '.id')
CFG_LOAD=$(echo $deployment_rec | jq -r '.analytics.load')
ACME_WEB_HOST=$(echo $deployment_rec | jq -r '.status.summary.http_links."node-service"[0].ip')

#echo $DID
#echo $CFG_LOAD
#echo $ACME_WEB_HOST

while true; do

#check load on server
chk_conn=$( curl -Ss http://${ACME_WEB_HOST}/rest/api/checkstatus )
cur_load=$( echo $chk_conn | cut -d " " -f 3 )

echo "Load at ${ACME_WEB_HOST} is $cur_load connections"

#compare if current load is greater then CFG_LOAD
if [ $cur_load -gt $CFG_LOAD ]; then
    #Update smart config in apl
    echo "Updating smart config for $DEPLOYMENT ..."
    echo
    NEW_LOAD=$(($CFG_LOAD + $LOAD_STEP))
    echo $NEW_LOAD
    smc_result=$(update_sm_config "$API_KEY" $NEW_LOAD $DID)
    get_status
    echo "Result:" $smc_result
    echo
else
    echo "Current Load less then configured load"
fi

#sleep till next cycle
sleep 30

done


