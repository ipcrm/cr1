#!/bin/bash
# This script will update the Build status

# Push the release to Distelli with the Distelli CLI
echo -e "\n\nPushing the Distelli release\n"
DISTELLI_USERNAME=ipcrm
DISTELLI_API_URL="https://api.distelli.com/$DISTELLI_USERNAME"
DISTELLI_APP_NAME="cr1"
DISTELLI_TMP_RELEASE="DISTELLIrelease.$BUILD_NUMBER.tmp"
DISTELLI_RESPONSE=$(distelli push -save-release "$DISTELLI_TMP_RELEASE")
DISTELLI_RELEASE_VERSION=$(cat "$DISTELLI_TMP_RELEASE")
DISTELLI_RESPONSE=$(rm "$DISTELLI_TMP_RELEASE")
echo -e "Distelli Release Version: $DISTELLI_RELEASE_VERSION\n"

# Setting global Distelli Env Variables
echo -e "\nSetting global Distelli environment variables\n"
DISTELLI_CI_PROVIDER="jenkins"
DISTELLI_BUILD_STATUS="Success"

# Preparing to update the build event with "Success" and build end time
echo -e "\nPreparing to update build event in Distelli\n"
DISTELLI_NOW=$(date -u +%Y-%m-%dT%H:%M:%S.0Z)
DISTELLI_TMP_FILENAME="DISTELLI.$BUILD_NUMBER.tmp"
DISTELLI_BUILD_EVENT_ID=$(cat "$DISTELLI_TMP_FILENAME")
DISTELLI_RESPONSE=$(rm "$DISTELLI_TMP_FILENAME")

echo -e "Updating build event in Distelli\n"
# Updating build event with "Success" and build end time
API_JSON=$(printf '{"build_status":%s, "build_end":%s, "release_version":%s}' \
  "$(jq -R . <<<"$DISTELLI_BUILD_STATUS")" \
  "$(jq -R . <<<"$DISTELLI_NOW")" \
  "$(jq -R . <<<"$DISTELLI_RELEASE_VERSION")")
  
DISTELLI_RESPONSE=$(curl -s -k -H "Content-Type: application/json" \
  -X POST "$DISTELLI_API_URL/apps/$DISTELLI_APP_NAME/events/$DISTELLI_BUILD_EVENT_ID?apiToken=$DISTELLI_API_TOKEN" \
  -d "$API_JSON")
  
echo -e "Distelli Build Update Response:\n $DISTELLI_RESPONSE\n\n"
