#!/bin/bash

# Do not reveal secrets
set +x

# Do not exit on failure so that artifacts can be archived
set +e

# Source environment variables of the jenkins slave
# that might interest this worker.
if [ -e "../jenkins-env" ]; then
  cat ../jenkins-env \
    | grep -E "(JENKINS_URL|\
    |GIT_BRANCH|\
    |GIT_COMMIT|\
    |JOB_NAME|\
    |BUILD_NUMBER|\
    |ghprbSourceBranch|\
    |ghprbActualCommit|\
    |BUILD_URL|\
    |ghprbPullId|\
    |SCENARIO|\
    |SERVER_ADDRESS|\
    |FORGE_API|\
    |WIT_API|\
    |AUTH_API|\
    |OSO_CLUSTER_ADDRESS|\
    |OSO_USERNAME|\
    |OSIO_USERNAME|\
    |OSIO_PASSWORD|\
    |GITHUB_USERNAME|\
    |OSIO_DANGER_ZONE|\
    |PIPELINE|\
    |BOOSTER_MISSION|\
    |BOOSTER_RUNTIME|\
    |BLANK_BOOSTER|\
    |GIT_REPO|\
    |PROJECT_NAME|\
    |AUTH_CLIENT_ID|\
    |REPORT_DIR|\
    |UI_HEADLESS)=" \
    | sed 's/^/export /g' \
    > /tmp/jenkins-env
  source /tmp/jenkins-env
fi

# Assign default values if not defined in Jenkins job

# Endpoints
## Main URI
export SERVER_ADDRESS="${SERVER_ADDRESS:-https://openshift.io}"

## URI of the Openshift.io's forge server
export FORGE_API="${FORGE_API:-https://forge.api.openshift.io}"

## URI of the Openshift.io's API server
export WIT_API="${WIT_API:-https://api.openshift.io}"

## URI of the Openshift.io's Auth server
export AUTH_API="${AUTH_API:-https://auth.openshift.io}"

## OSO API server
# Example of OSO API endpoint:
# https://api.starter-us-east-2.openshift.com:443/oapi/v1/namespaces/jsmith/builds'
export OSO_CLUSTER_ADDRESS="${OSO_CLUSTER_ADDRESS:-https://api.starter-us-east-2.openshift.com:443}"

export GITHUB_USERNAME=${GITHUB_USERNAME:-"osiotestmachine"}

## Enable/disable danger zone - features tagged as @osio.danger-zone (e.g. reset user's environment).
## (default value is "false")
export OSIO_DANGER_ZONE="${OSIO_DANGER_ZONE:-false}"

### A behave tag to enable/disable features tagged as @osio.danger-zone (e.g. reset user's environment).
if [ "$OSIO_DANGER_ZONE" == "true" ]; then
        export BEHAVE_DANGER_TAG="@osio.danger-zone"
else
        export BEHAVE_DANGER_TAG="~@osio.danger-zone"
fi

## OpenShift.io booster mission
export BOOSTER_MISSION="${BOOSTER_MISSION:-rest-http}"

## OpenShift.io booster runtime
export BOOSTER_RUNTIME="${BOOSTER_RUNTIME:-vert.x}"

## true for the blank booster
export BLANK_BOOSTER="${BLANK_BOOSTER:-false}"

## OpenShift.io pipeline release strategy
export PIPELINE="${PIPELINE:-maven-releasestageapproveandpromote}"

## github repo name
export GIT_REPO="${GIT_REPO:-test123}"

## OpenShift.io project name
export PROJECT_NAME="${PROJECT_NAME:-test123}"

## A default client_id for the OAuth2 protocol used for user login
## (See https://github.com/fabric8-services/fabric8-auth/blob/d39e42ac2094b67eeaec9fc69ca7ebadb0458cea/controller/authorize.go#L42)
export AUTH_CLIENT_ID="${AUTH_CLIENT_ID:-740650a2-9c44-4db5-b067-a3d1b2cd2d01}"

## An output directory where the reports will be stored
export REPORT_DIR=${REPORT_DIR:-target}

## 'true' if the UI parts of the test suite are to be run in headless mode (default value is 'true')
export UI_HEADLESS=${UI_HEADLESS:-true}

export OSO_USERNAME=$OSIO_USERNAME


# If target did exist, remove artifacts from previous run
mkdir -p dist target
rm -rf target/screenshots

# We need to disable selinux for now
/usr/sbin/setenforce 0
yum -y install docker 
service docker start

# Shutdown container if running
if [ -n "$(docker ps -q -f name=fabric8-booster-test)" ]; then
    docker rm -f fabric8-booster-test
fi

# Build builder image
cp /tmp/jenkins-env .
docker build -t fabric8-booster-test:latest -f Dockerfile.builder .

# Run and setup Docker image
docker run -it --shm-size=256m --detach=true --name=fabric8-booster-test --cap-add=SYS_ADMIN \
          -e SCENARIO \
          -e SERVER_ADDRESS \
          -e FORGE_API \
          -e WIT_API \
          -e AUTH_API \
          -e OSO_CLUSTER_ADDRESS \
          -e OSIO_USERNAME \
          -e OSIO_PASSWORD \
          -e OSO_USERNAME \
          -e OSO_TOKEN \
          -e GITHUB_USERNAME \
          -e OSIO_DANGER_ZONE \
          -e PIPELINE \
          -e BOOSTER_MISSION \
          -e BOOSTER_RUNTIME \
          -e BLANK_BOOSTER \
          -e GIT_REPO \
          -e PROJECT_NAME \
          -e AUTH_CLIENT_ID \
          -e REPORT_DIR \
          -e UI_HEADLESS \
          -t -v "$(pwd)"/dist:/dist:Z -v /etc/localtime:/etc/localtime:ro fabric8-booster-test:latest /bin/bash

# Start Xvfb
docker exec fabric8-booster-test /usr/bin/Xvfb :99 -screen 0 1024x768x24 &

# Exec booster tests
docker exec fabric8-booster-test ./run.sh 2>&1 | tee target/test.log

# Test results to archive
docker cp fabric8-booster-test:/opt/fabric8-test/target/. target

# Shutdown container if running
if [ -n "$(docker ps -q -f name=fabric8-booster-test)" ]; then
    docker rm -f fabric8-booster-test
fi

