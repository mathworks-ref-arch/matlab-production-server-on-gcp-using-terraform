#!/bin/bash
MPS_HOST=$1
flag=0
timeout_counter=0
timeout_limit=20
exit_code=0
# Test mps instance health to check if the following is complete:
# - VM is created
# - MATLAB Runtime is installed
# - MPS is installed
# - MPS configured and setup for testing and image creation

while [ $flag -ne 1 ] && [ $timeout_counter -le $timeout_limit ]
do
 result=$(curl --silent -X GET --header "Accept: */*" "http://${MPS_HOST}:9910/api/health" | jq -r '.status')
 
 if [ "$result" = "ok" ]; then
     printf "\nFinished building MPS nodes"
     flag=1
     exit_code=0
 else
    if [[ "$result" == "" ]]; then 
        printf "\nStill building MPS node\n"
        flag=0
        sleep 1m
    else
        printf "\nStatus reported:\n\n %s" "$result"
        flag=1
        exit_code=1
    fi
fi
timeout_counter=$((timeout_counter+1))
done

if ! [ $timeout_counter -le $timeout_limit ]; then
    printf "\n"
    echo "Health check for deployment has timed out at $timeout_limit minutes. Check Google Cloud Logs for Compute instances to find more or re-configure the timeout value."
    printf "\n"
    exit_code=1
fi

exit $exit_code

# (c) 2021 MathWorks, Inc.
