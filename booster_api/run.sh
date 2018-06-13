#!/bin/bash

export SERVER_ADDRESS="https://openshift.io"
export FORGE_API="https://forge.api.openshift.io"

# Example of OSO API endpoint:
# https://api.starter-us-east-2.openshift.com:443/oapi/v1/namespaces/jsmith/builds'
export OSO_CLUSTER_ADDRESS="https://api.starter-us-east-2.openshift.com:443"

# Substring of staged app URL
export STAGE_SERVER="stage.8a09.starter-us-east-2.openshiftapps.com"

# Login config
## Openshift.io user's name
##export OSIO_USERNAME=""

## Openshift.io user's password
##export OSIO_PASSWORD=""

## OpenShift Online user's name
##export OSO_USERNAME=""

## OpenShift Online token
##export OSO_TOKEN=""

## OpenShift.io pipeline release strategy
export PIPELINE="maven-releaseandstage"

## github repo name
export GIT_REPO="test123"

## OpenShift.io project name
export PROJECT_NAME="test123"

## URI of the Openshift.io's Auth server 
export AUTH_SERVER_ADDRESS="https://auth.openshift.io"

## A default client_id for the OAuth2 protocol used for user login
## (See https://github.com/fabric8-services/fabric8-auth/blob/d39e42ac2094b67eeaec9fc69ca7ebadb0458cea/controller/authorize.go#L42)
export AUTH_CLIENT_ID="740650a2-9c44-4db5-b067-a3d1b2cd2d01"

behave -v --no-capture --no-capture-stderr @features_list.txt
