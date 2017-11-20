#!/bin/bash
# This script creates a PUSH event in Distelli for the commit
# This script also creates a BUILD event setting the build as "Running"

# Install JQ
[[ -d bin ]] || mkdir bin
[[ -f bin/jq ]] || curl -Lo bin/jq 'https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64'
chmod +x bin/jq
export PATH=$PATH:bin

# Setting global Distelli Env Variables
echo -e "\nSetting global Distelli environment variables\n"
DISTELLI_USERNAME=ipcrm
DISTELLI_API_URL="https://api.distelli.com/$DISTELLI_USERNAME"
DISTELLI_APP_NAME="cr1"
DISTELLI_CI_PROVIDER="jenkins"
DISTELLI_BUILD_STATUS="Running"
DISTELLI_BUILD_ID=$BUILD_NUMBER
DISTELLI_BUILD_URL=$BUILD_URL
DISTELLI_CHANGE_URL=$GIT_URL
DISTELLI_CHANGE_AUTHOR=$GIT_AUTHOR_NAME
DISTELLI_CHANGE_AUTHOR_DISPLAY_NAME=$GIT_AUTHOR_NAME
DISTELLI_CHANGE_TITLE="NoChangeMessage"
DISTELLI_CHANGE_ID=$GIT_COMMIT
DISTELLI_BRANCH_NAME=$GIT_BRANCH
DISTELLI_CHANGE_TARGET=$GIT_URL

# Creating Distelli PUSH event
echo -e "\nCreating Distelli PUSH Event\n"

API_JSON=$(printf '{"commit_url":%s, "author_username":%s, "author_name":%s, "commit_msg":%s, "commit_id":%s, "branch":%s, "repo_url":%s}' \
  "$(jq -R . <<<"$DISTELLI_CHANGE_URL")" \
  "$(jq -R . <<<"$DISTELLI_CHANGE_AUTHOR")" \
  "$(jq -R . <<<"$DISTELLI_CHANGE_AUTHOR_DISPLAY_NAME")" \
  "$(jq -R . <<<"$DISTELLI_CHANGE_TITLE")" \
  "$(jq -R . <<<"$DISTELLI_CHANGE_ID")" \
  "$(jq -R . <<<"$DISTELLI_BRANCH_NAME")" \
  "$(jq -R . <<<"$DISTELLI_CHANGE_TARGET")")

DISTELLI_RESPONSE=$(curl -s -k -X PUT -H "Content-Type: application/json" "$DISTELLI_API_URL/apps/$DISTELLI_APP_NAME/events/pushEvent?apiToken=$DISTELLI_API_TOKEN" -d "$API_JSON")
DISTELLI_PUSH_EVENT_ID=$(echo $DISTELLI_RESPONSE | jq .event_id | tr -d '"')
echo -e "push_event_id: $DISTELLI_PUSH_EVENT_ID\n"

# Creating Distelli BUILD event
echo -e "\nCreating Distelli BUILD Event\n"

DISTELLI_NOW=$(date -u +%Y-%m-%dT%H:%M:%S.0Z)
API_JSON=$(printf '{"build_status":%s, "build_start":%s, "build_id":%s, "build_provider":%s, "build_url":%s, "repo_url":%s, "commit_url":%s, "author_username":%s, "author_name":%s, "commit_msg":%s, "commit_id":%s, "branch":%s, "parent_event_id":%s}' \
  "$(jq -R . <<<"$DISTELLI_BUILD_STATUS")" \
  "$(jq -R . <<<"$DISTELLI_NOW")" \
  "$(jq -R . <<<"$DISTELLI_BUILD_ID")" \
  "$(jq -R . <<<"$DISTELLI_CI_PROVIDER")" \
  "$(jq -R . <<<"$DISTELLI_BUILD_URL")" \
  "$(jq -R . <<<"$DISTELLI_CHANGE_TARGET")" \
  "$(jq -R . <<<"$DISTELLI_CHANGE_URL")" \
  "$(jq -R . <<<"$DISTELLI_CHANGE_AUTHOR")" \
  "$(jq -R . <<<"$DISTELLI_CHANGE_AUTHOR_DISPLAY_NAME")" \
  "$(jq -R . <<<"$DISTELLI_CHANGE_TITLE")" \
  "$(jq -R . <<<"$DISTELLI_CHANGE_ID")" \
  "$(jq -R . <<<"$DISTELLI_BRANCH_NAME")" \
  "$(jq -R . <<<"$DISTELLI_PUSH_EVENT_ID")")


DISTELLI_RESPONSE=$(curl -s -k -H "Content-Type: application/json" \
  -X PUT "$DISTELLI_API_URL/apps/$DISTELLI_APP_NAME/events/buildEvent?apiToken=$DISTELLI_API_TOKEN" \
  -d "$API_JSON")

DISTELLI_BUILD_EVENT_ID=$(echo $DISTELLI_RESPONSE | jq .event_id | tr -d '"')
echo -e "build_event_id: $DISTELLI_BUILD_EVENT_ID\n\n"

# Saving build event id
DISTELLI_TMP_FILENAME="DISTELLI.$JOB_NAME.$BUILD_NUMBER.tmp"
echo "$DISTELLI_BUILD_EVENT_ID" > "$DISTELLI_TMP_FILENAME"
