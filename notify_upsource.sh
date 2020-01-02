#!/usr/bin/env bash

# Send a build status notification to Upsource
#
# References:
#
# - https://www.jetbrains.com/help/upsource/ci-server-integration.html#OtherCIservers
# - https://wiki.jenkins.io/display/JENKINS/Building+a+software+project#Buildingasoftwareproject-belowJenkinsSetEnvironmentVariables
#
# Note: $UPSOURCE_* are set using environment in Jenkinsfile
# buildURL = env.BUILD_URL
# def newBuildURL = buildURL.replace("job/${env.JOB_NAME}", "blue/organizations/jenkins/${env.JOB_NAME}")
# newBuildURL = newBuildURL.replace("job/${env.BRANCH_NAME}", "detail/${env.BRANCH_NAME}")

if [[ -z "${UPSOURCE_AUTH}" ]]; then
    echo "Upsource authentication token not set."
    exit 1
fi

echo "{
    \"key\" : \"${BUILD_TAG}\",
    \"name\": \"#${BUILD_NUMBER}\",
    \"state\": \"${1}\",
    \"url\": \"${RUN_DISPLAY_URL}\",
    \"project\": \"${UPSOURCE_PROJECT}\",
    \"revision\": \"${GIT_COMMIT}\"
}" | \
curl -X POST \
     --data @- \
     "${UPSOURCE_URL}/~buildStatus/" \
     --header "Content-Type: application/json; charset=UTF-8" \
     --header "Authorization: Basic ${UPSOURCE_AUTH}"

if [ $? == 0 ] ; then
    echo "Notified Upsource of ${1}"
fi
