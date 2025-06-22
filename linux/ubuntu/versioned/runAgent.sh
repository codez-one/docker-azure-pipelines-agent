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

# Check if token is present
if [ -z "$AZDO_TOKEN" -a -z "$AZDO_TOKEN_FILE" ]; then
  # No token found
  # Check if User was given
  if [ -z "$AZDO_USER" ]; then
    # No User found
    echo 1>&2 error: missing AZDO_USER environment variable
    exit 1
  fi

  # Check if Password was given
  if [ -z "$AZDO_PASSWORD" -a -z "$AZDO_PASSWORD_FILE" ]; then
    # No Password found
    echo 1>&2 error: missing AZDO_PASSWORD or AZDO_PASSWORD_FILE environment variable
    exit 1
  fi

  # Token must be used when no User and Password was given
  if [ -z "$AZDO_USER" ] && [ -z "$AZDO_PASSWORD" -a -z "$AZDO_PASSWORD_FILE" ]; then
    echo 1>&2 error: missing AZDO_TOKEN or AZDO_TOKEN_FILE environment variable
    exit 1
  fi
fi

if [ -n "$AZDO_AGENT" ]; then
  AZDO_AGENT="$(eval echo "$AZDO_AGENT")"
  export AZDO_AGENT
fi

if [ -n "$AZDO_WORK" ]; then
  AZDO_WORK="$(eval echo "$AZDO_WORK")"
  export AZDO_WORK
  mkdir -p "$AZDO_WORK"
fi

arg_agent_auth=
# When user and either a password or a password file is present
if [ -n "$AZDO_USER" ] && [ -n "$AZDO_PASSWORD" -o -n "$AZDO_PASSWORD_FILE" ]; then
  # When no password file was given write the password to a file in the default location
  if [ -z "$AZDO_PASSWORD_FILE" ]; then
    AZDO_PASSWORD_FILE=/azdo/.password
    echo -n $AZDO_PASSWORD > "$AZDO_PASSWORD_FILE"
  fi
  # Clear the password from the container
  unset AZDO_PASSWORD
  arg_agent_auth="--auth negotiate --username $AZDO_USER --password $(cat "$AZDO_PASSWORD_FILE")"
else
  # When no token file was given write the token to a file in the default location
  if [ -z "$AZDO_TOKEN_FILE" ]; then
    AZDO_TOKEN_FILE=/azdo/.token
    echo -n $AZDO_TOKEN > "$AZDO_TOKEN_FILE"
  fi
  # Clear the token from the container
  unset AZDO_TOKEN
  arg_agent_auth="--auth PAT --token $(cat "$AZDO_TOKEN_FILE")"
fi

arg_pool_params=
# When a deploment pool is given
if [ -n "$AZDO_DEPLOYMENT_POOL" ]; then
  if [ -n "$AZDO_POOL" ]; then
    echo 1>&2 error: cannot set AZDO_DEPLOYMENT_POOL and AZDO_POOL environment variables
    exit 1
  fi

  arg_pool_params=(--deploymentpool --deploymentpoolname "$AZDO_DEPLOYMENT_POOL")
else
  arg_pool_params=(--pool "$AZDO_POOL")
fi

arg_agent_once=
if [ "$AZDO_AGENT_DISPOSE" = true ]; then
  env_include+=( "Agent.RunOnce=true" )
  arg_agent_once="--once"
fi

cd /azdo/agent

cleanup() {
  # some shells will call EXIT after the INT handler
  trap '' EXIT
  ./bin/Agent.Listener remove --unattended \
    $arg_agent_auth
}

print_message() {
  lightcyan='\033[1;36m'
  nocolor='\033[0m'
  echo -e "${lightcyan}$1${nocolor}"
}

# When there is a old configuration perform a cleanup
if [ -e .agent ]; then
  echo "Removing existing AZDO agent configuration..."
  cleanup
fi

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
trap 'cleanup; exit 0' EXIT

VSO_AGENT_IGNORE=_,MAIL,OLDPWD,PATH,PWD,VSO_AGENT_IGNORE,AZDO_AGENT,AZDO_URL,AZDO_USER,AZDO_PASSWORD,AZDO_TOKEN_FILE,AZDO_PASSWORD_FILE,AZDO_POOL,AZDO_DEPLOYMENT_POOL,AZDO_WORK,AZDO_AGENT_DISPOSE,AZDO_ENV_IGNORE,DOTNET_CLI_TELEMETRY_OPTOUT,AGENT_ALLOW_RUNASROOT,DEBIAN_FRONTEND

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
  "${arg_pool_params[@]}" \
  --work "${AZDO_WORK:-_work}" \
  --replace & wait $!

print_message "    Done."

print_message "Starting Agent ..."

# echo "Exclude: ${env_exclude[@]/#/--unset=}"
# echo "Include: ${env_include[@]}"

env ${env_exclude[@]/#/--unset=} "${env_include[@]}" ./run.sh $arg_agent_once & wait $!
