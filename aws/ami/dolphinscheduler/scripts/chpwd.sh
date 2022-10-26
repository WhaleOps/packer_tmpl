#!/bin/bash

# Log file location
CURRENT_LOG=/tmp/cron_chpwd

# Get EC2 instance id
EC2_ID=$(ec2metadata --instance-id)
echo "$(date): Get EC2 instance id ${EC2_ID}." >> "${CURRENT_LOG}"

while true; do
    echo "$(date): Start trying change password." >> "${CURRENT_LOG}"

    # Wait until API service is available, if not sleep 5 seconds.
    if [[ $(curl -s -X GET 'http://127.0.0.1:12345/dolphinscheduler/actuator/health' | jq .status) != *"UP"* ]]; then
        echo "$(date): API server not ready, sleep for 5s." >> "${CURRENT_LOG}"
        sleep 5
        continue
    fi

    echo "$(date): API server is ready, run command to change password." >> "${CURRENT_LOG}"

    session_id=$(curl -s --compressed -X POST 'http:/127.0.0.1:12345/dolphinscheduler/login' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Accept: application/json, text/plain, */*' \
    -H 'Accept-Encoding: gzip, deflate' \
    --data 'userName=admin&userPassword=dolphinscheduler123' | jq -r '.data.sessionId')

    echo "$(date): Get login session Id ${session_id}, will use it change password." >> "${CURRENT_LOG}"

    curl -s -X POST 'http://127.0.0.1:12345/dolphinscheduler/users/update' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Accept: application/json, text/plain, */*' \
    -H 'Accept-Encoding: gzip, deflate' \
    -H "sessionId: ${session_id}" \
    --data "id=1&userName=user&tenantId=1&email=dolphinscheduler%40gmail.com&queue=default&phone=&state=1&userPassword=${EC2_ID}"

    if [[ $? == 23 ]]; then
        echo "$(date): Success change password." >> "${CURRENT_LOG}"
    else
        echo "$(date): ERROR change password." >> "${CURRENT_LOG}"
    fi

    break
done
