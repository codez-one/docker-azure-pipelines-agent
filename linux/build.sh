#!/bin/bash

die() {
    printf '%s\n' "$1" >&2
    exit 1
}

# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.
cleanup=
registry=czon
name=azdo-agent
count=0
start=$(date +%s)

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -c|--cleanup)
            cleanup=true
            echo "Cleanup after build "
            ;;
        -r|--registry)
            if [ "$2" ]; then
                registry=$2
                echo "Registry: '$registry'"
                shift
            else
                die 'ERROR: "--registry" requires a non-empty option argument.'
            fi
            ;;
        -n|--name)
            if [ "$2" ]; then
                name=$2
                echo "Name: '$name'"
                shift
            else
                die 'ERROR: "--name" requires a non-empty option argument.'
            fi
            ;;
        --)                     # End of all options.
            shift
            break
            ;;
        *)                      # unknown option
            POSITIONAL+=("$1")  # save it in an array for later
            shift               # past argument
            ;;    esac

    shift
done
set -- "${POSITIONAL[@]}"       # restore positional parameters

# Run update to make sure to build the latest dockerfiles
./update.sh --registry=$registry --name=$name

devider(){
  echo ""
  echo "------------------------------------------------------"
  echo ""
}

devider

set -e
cd "$(dirname $0)"

while read dir; do
  echo "Build Docker Image for:"
  echo -e "\033[1;32m$dir\033[0m"
  echo ""

  # Arguments can be done with:
  # --build-arg http_proxy="http://proxy.company.com:8080" \
  # this must be done in the line before "output/$dir" because the image name has to be the last parameter

  docker build \
    --compress \
    -t $registry/$name:${dir//\//-} \
    output/$dir
  
  _=$((count+=1))
  
  devider
done< <(./dirs.sh)

# Set the 'latest' tag to the image set in 'latest.tag' file
LATEST_TAG=$(cat latest.tag)
if [ -n "$(docker images -f reference=$registry/$name:$LATEST_TAG -q)" ]; then
  echo "Apply 'latest' tag to: $registry/$name:$LATEST_TAG"
  docker tag $registry/$name:$LATEST_TAG $registry/$name

  devider
fi

end=$(date +%s)
((seconds=end-start))
if (( $seconds > 3600 )) ; then
    ((hours=seconds/3600))
    ((minutes=(seconds%3600)/60))
    ((seconds=(seconds%3600)%60))
    echo "Built $count images in $hours hour(s), $minutes minute(s) and $seconds second(s)" 
elif (( $seconds > 60 )) ; then
    ((minutes=(seconds%3600)/60))
    ((seconds=(seconds%3600)%60))
    echo "Built $count images in $minutes minute(s) and $seconds second(s)"
else
    echo "Built $count images in $seconds seconds"
fi

devider

if [ "$cleanup" = true ]; then
  echo "Cleanup all unused images..."
  docker image prune -f

  devider
fi
