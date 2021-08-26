#!/bin/bash
LoadBalancer_frontend=$1
flag=0
timeout_counter=0
timeout_limit=10
# Check whether MPS endpoint is ready
# This involves all of the following in working condition:
#       * http target proxy load balancer
#       * active MPS nodes
#       * backend managed instance group
#       * frontend for loadbalancer
#       * health check for managed instance group 
 
while [ $flag -ne 1 ] && [ $timeout_counter -le $timeout_limit ]
do
result=$(curl --silent -H "Accept: application/json" "http://${LoadBalancer_frontend}/api/health" | jq -r '.status')
if [ "$result" = "ok" ]; then
    printf "\nFinished building MPS nodes"
    flag=1
else
    if [[ "$result" == "" ]]; then 
        printf "\nStill building MPS nodes\n"
        flag=0
        sleep 1m
    else
        printf "\nHealth check status reported:\n\n %s" "$result"
        flag=1
    fi
fi
timeout_counter=$((timeout_counter+1))
done

if ! [ $timeout_counter -le $timeout_limit ]; then
    printf "\n"
    echo "Health check for deployment has timed out. Check Google Cloud Logs for Compute instances to find more."
    printf "\n"
fi

# (c) 2021 MathWorks, Inc.
