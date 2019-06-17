#!/bin/bash
# Split on "/" to get last part of URL, ref: http://stackoverflow.com/a/5257398/689223
URL_SPLIT=(${TRAVIS_REPO_SLUG//\// })
USERNAME=$(printf %s\\n "${URL_SPLIT[@]:(0)}")
REPONAME=$(printf %s\\n "${URL_SPLIT[@]:(1)}")
PR_NUM=${TRAVIS_PULL_REQUEST}
echo "1${USERNAME}2${REPONAME}3${PR_NUM}"
# Domain names follow the RFC1123 spec [a-Z] [0-9] [-] limited to 253 characters
# https://en.wikipedia.org/wiki/Domain_Name_System#Domain_name_syntax
# So, just replace "/" or "." with "-"
DEPLOY_SUBDOMAIN=`echo "${PR_NUM}-pr-${REPONAME}-${USERNAME}" | tr '[\/|\.]' '-' | cut -c1-253`
DEPLOY_DOMAIN="https://${DEPLOY_SUBDOMAIN}.surge.sh"
ALREADY_DEPLOYED=`yarn run surge list | grep ${DEPLOY_SUBDOMAIN}`

yarn run surge --project .public --domain $DEPLOY_DOMAIN;

if [ -z "$ALREADY_DEPLOYED" ]
then
  # Using the Issues api instead of the PR api
  # Done so because every PR is an issue, and the issues api allows to post general comments,
  # while the PR api requires that comments are made to specific files and specific commits
  GITHUB_PR_COMMENTS="https://api.github.com/repos/${USERNAME}/${REPONAME}/issues/${PR_NUM}/comments"
  echo "Adding github PR comment ${GITHUB_PR_COMMENTS}"
  curl -H "Authorization: token ${GH_PR_TOKEN}" --request POST ${GITHUB_PR_COMMENTS} --data '{"body":"PatternFly-React preview: '${DEPLOY_DOMAIN}'"}'
else
  echo "Already deployed ${DEPLOY_DOMAIN}"
fi