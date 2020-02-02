#!/bin/bash

die() {
    printf '%s\n' "$1" >&2
    exit 1
}

# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.
run=
name=
pool=AZDO-Agent-Test
deploymentpool=
server=https://dev.azure.com/czon/
continuous=
dispose=
interactive=
userauth=

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -r|--run)
            if [ "$2" ]; then
                run=$2
                echo "Command to run: '$run'"
                shift
            else
                die 'ERROR: "--run" requires a non-empty option argument.'
            fi
            ;;
        -n|--name)
            if [ "$2" ]; then
                name=$2
                echo "Agent Name: '$name'"
                shift
            else
                die 'ERROR: "--name" requires a non-empty option argument.'
            fi
            ;;
        -p|--pool)
            if [ "$2" ]; then
                pool=$2
                echo "Agent Pool: '$pool'"
                shift
            else
                die 'ERROR: "--pool" requires a non-empty option argument.'
            fi
            ;;
        --deploymentpool)
            if [ "$2" ]; then
                deploymentpool=$2
                echo "Deployment Pool: '$deploymentpool'"
                shift
            else
                die 'ERROR: "--deploymentpool" requires a non-empty option argument.'
            fi
            ;;
        -s|--server)
            if [ "$2" ]; then
                server=$2
                echo "AZDO URI: '$server'"
                shift
            else
                die 'ERROR: "--server" requires a non-empty option argument.'
            fi
            ;;
        -c|--continuous)
            continuous=true
            echo "Running continuous"
            ;;
        -d|--dispose)
            dispose=true
            echo "Dispose after use"
            ;;
        -i|--interactive)
            interactive=true
            echo "Run interactive"
            ;;
        -u|--userauth)
            userauth=true
            echo "Using user and password"
            ;;
        --)                     # End of all options.
            shift
            break
            ;;
        *)                      # unknown option
            POSITIONAL+=("$1")  # save it in an array for later
            shift               # past argument
            ;;
    esac

    shift
done
set -- "${POSITIONAL[@]}"       # restore positional parameters

getpassword() {
  local  __resultvar=$2
  local  password=
  local prompt=$1
  while IFS= read -p "$prompt" -r -s -n 1 char 
  do
    if [[ $char == $'\0' ]];     then
      break
    fi
    if [[ $char == $'\177' ]];  then
      prompt=$'\b \b'
      password="${password%?}"
    else
      prompt='*'
      password+="$char"
    fi
  done
  eval $__resultvar="'$password'"
}

if [ -z "$1" ]; then
    die 'ERROR: No image name found!'
fi
arg_docker_image=$1

arg_agent_auth=
if [ "$userauth" ]; then
  user=
  password=
  getpassword "Enter username for AZDO User:$(echo $'\n> ')" user
  echo $''
  getpassword "Enter password for AZDO User:$(echo $'\n> ')" password
  echo $''
  arg_agent_auth="-e AZDO_USER=$user -e AZDO_PASSWORD=$password "
else
  token=
  getpassword "Enter token for AZDO User:$(echo $'\n> ')" token
  echo $''
  arg_agent_auth="-e AZDO_TOKEN=$token"
fi

arg_azdo_agent=
if [ "$name" ]; then
  arg_azdo_agent="-e AZDO_AGENT=$name"
fi

arg_azdo_agent_dispose=
if [ "$dispose" = true ]; then
  arg_azdo_agent_dispose="-e AZDO_AGENT_DISPOSE=true"
fi

arg_docker_restart=
if [ "$continuous" = true ]; then
  arg_docker_restart="--restart unless-stopped"
fi

arg_docker_interactive=
if [ "$interactive" = true ]; then
  arg_docker_interactive="-it"
else
  arg_docker_interactive="-d"
fi

arg_pool=
if [ -n "$deploymentpool" ]; then
  arg_pool="-e AZDO_DEPLOYMENT_POOL=$deploymentpool"
else
  arg_pool="-e AZDO_POOL=$pool"
fi

docker run \
  -e AZDO_URL="$server" \
  $arg_agent_auth \
  $arg_pool \
  -e AZDO_ENV_INCLUDE='Agent.Project=My Awesome Project,Agent.Test=blubb' \
  $arg_azdo_agent \
  $arg_azdo_agent_dispose \
  $arg_docker_restart \
  $arg_docker_interactive \
  "$arg_docker_image" $run
