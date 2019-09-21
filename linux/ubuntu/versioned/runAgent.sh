#!/bin/bash
set -e

env_exclude=( "AZDO_USER" "AZDO_PASSWORD" "AZDO_TOKEN" "AZDO_ENV_EXCLUDE" "AZDO_ENV_INCLUDE" "AZDO_ENV_IGNORE" )
env_include=( )

originalIFS=$IFS
IFS=','
if [ -n "$AZDO_ENV_EXCLUDE" ]; then
  read -a external_exclude <<< ${AZDO_ENV_EXCLUDE%','}
  env_exclude+=( ${external_exclude[@]} )
fi
if [ -n "$AZDO_ENV_INCLUDE" ]; then
  read -a external_include <<< ${AZDO_ENV_INCLUDE%','}
  env_include+=( ${external_include[@]} )
fi
IFS=$originalIFS


if [ -z "$AZDO_URL" ]; then
  echo 1>&2 error: missing AZDO_URL environment variable
  exit 1
fi

if [ -z "$AZDO_USER" ] && [ -z "$AZDO_TOKEN" ]; then
  echo 1>&2 error: missing AZDO_USER environment variable
  exit 1
fi

if [ -z "$AZDO_PASSWORD" ] && [ -z "$AZDO_TOKEN" ]; then
  echo 1>&2 error: missing AZDO_PASSWORD environment variable
  exit 1
fi

if [ -z "$AZDO_USER" ] && [  -z "$AZDO_PASSWORD" ] && [ -z "$AZDO_TOKEN" ]; then
  echo 1>&2 error: missing AZDO_TOKEN environment variable
  exit 1
fi

if [ -n "$AZDO_AGENT" ]; then
  AZDO_AGENT="$(eval echo "$AZDO_AGENT")"
  export AZDO_AGENT
fi

if [ -n "$AZDO_WORK" ]; then
  AZDO_WORK="$(eval echo "$AZDO_WORK")"
  export AZDO_WORK=
  mkdir -p "$AZDO_WORK"
fi

arg_agent_auth=
if [ "$AZDO_USER" ] && [ "$AZDO_PASSWORD" ]; then
  arg_agent_auth="--auth negotiate --username $AZDO_USER --password $AZDO_PASSWORD"
else
  arg_agent_auth="--auth PAT --token $AZDO_TOKEN"
fi

arg_agent_once=
if [ "$AZDO_AGENT_DISPOSE" = true ]; then
  env_include+=( "Agent.RunOnce=true" )
  arg_agent_once="--once"
fi

cd /azdo/agent

cleanup() {
  trap '' EXIT # some shells will call EXIT after the INT handler
  ./bin/Agent.Listener remove --unattended \
    $arg_agent_auth
}

print_message() {
  lightcyan='\033[1;36m'
  nocolor='\033[0m'
  echo -e "${lightcyan}$1${nocolor}"
}

if [ -e .agent ]; then
  echo "Removing existing AZDO agent configuration..."
  cleanup
fi

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
trap 'cleanup; exit 0' EXIT

VSO_AGENT_IGNORE=_,MAIL,OLDPWD,PATH,PWD,VSO_AGENT_IGNORE,AZDO_AGENT,AZDO_URL,AZDO_USER,AZDO_PASSWORD,AZDO_POOL,AZDO_WORK,AZDO_AGENT_DISPOSE,AZDO_ENV_IGNORE,DOTNET_CLI_TELEMETRY_OPTOUT,AGENT_ALLOW_RUNASROOT,DEBIAN_FRONTEND

if [ -n "$AZDO_ENV_IGNORE" ]; then
  VSO_AGENT_IGNORE+=",$AZDO_ENV_IGNORE"
fi

export VSO_AGENT_IGNORE
export AGENT_ALLOW_RUNASROOT="1"

source ./env.sh

print_message "Configure Agent ..."

./bin/Agent.Listener configure --unattended --acceptTeeEula \
  --agent "${AZDO_AGENT:-Agent_$(hostname)}" \
  --url "$AZDO_URL" \
  $arg_agent_auth \
  --pool "${AZDO_POOL:-Default}" \
  --work "${AZDO_WORK:-_work}" \
  --replace & wait $!

print_message "    Done."

print_message "Starting Agent ..."

# echo "Exclude: ${env_exclude[@]/#/--unset=}"
# echo "Include: ${env_include[@]}"

env ${env_exclude[@]/#/--unset=} "${env_include[@]}" ./run.sh $arg_agent_once & wait $!
