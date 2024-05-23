#!/bin/bash
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_USER_PASS="admin123"
JENKINS_CRUMB=$(curl -u "$JENKINS_USER:$JENKINS_USER_PASS" -s --cookie-jar /tmp/cookies $JENKINS_URL'/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
curl -u "$JENKINS_USER:$JENKINS_USER_PASS" -H "$JENKINS_CRUMB" -s \
                    --cookie /tmp/cookies $JENKINS_URL'/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken' \
                    --data 'newTokenName=GlobalToken' > /tmp/jenkins_api_token
