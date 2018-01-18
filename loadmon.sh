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
[ -f ./loader.conf ] || { echo "[!] ERROR: Missing loader.conf config file. Aborting."; exit 1; }

echo conf file found, importing conf file...
source ./loader.conf
get_status

echo "Running loadmon for appLariat Deployment $DEPLOYMENT at $API_URL"

#Pull deployment information
deployment_rec=$(get_deployment "$API_KEY" "$DEPLOYMENT")
get_status
#echo $deployment_rec

DID=$(echo $deployment_rec | jq -r '.id')
ACME_WEB_HOST=$(echo $deployment_rec | jq -r '.status.summary.http_links."node-service"[0].ip')

#echo $DID
#echo $ACME_WEB_HOST

while true; do

CFG_LOAD=$(echo $deployment_rec | jq -r '.analytics.load')
CFG_INST=$(echo $deployment_rec | jq -r '.status.components[] | select(.name == "node") | .instances')

if [ $CFG_LOAD = "null" ]; then
    echo "Deployment not setup for analytics"
    UPDATE_CFG=0
    #exit
else
    echo "Smart Config setup for $CFG_LOAD connections, tracking config"
    UPDATE_CFG=1
fi

#check load on server
chk_conn=$( curl -Ss http://${ACME_WEB_HOST}/rest/api/checkstatus )
if [ $? -eq 0 ]; then
    cur_load=$( echo $chk_conn | cut -d " " -f 3 )
else
    echo "Unable to determine load"
    curr_load=1
fi

cur_load=$(($cur_load * $CFG_INST))


echo "Load at ${ACME_WEB_HOST} is $cur_load connections"

if [ $UPDATE_CFG -eq 1 ]; then

    #compare if current load is greater then CFG_LOAD
    if [ $cur_load -gt $CFG_LOAD ]; then
        #Update smart config in apl
        echo "Updating smart config for $DEPLOYMENT ..."
        echo
        NEW_LOAD=$(($CFG_LOAD + $LOAD_STEP))
        echo $NEW_LOAD
        smc_result=$(update_sm_config "$API_KEY" $NEW_LOAD $DID)
        get_status
        if [[ $(echo $smc_result | jq -r '. | has("data")') == "true" ]]; then
            #echo "Result:" $smc_result
            echo "Smart Config Update Job Submitted"
        fi
        echo
    else
        echo "Current Load less then configured load, nothing to do"
    fi
fi

#sleep till next cycle
sleep 60

#repull the deployment info
deployment_rec=$(get_deployment "$API_KEY" "$DEPLOYMENT")
get_status

done


