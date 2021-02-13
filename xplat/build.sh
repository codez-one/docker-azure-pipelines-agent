#!/bin/bash
set -e

# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.

registry=czon
name=azdo-agent

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
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
            ;;
    esac

    shift
done
set -- "${POSITIONAL[@]}"       # restore positional parameters

cd "$(dirname "$0")"
tag=$( tail -n 1 ../latest-agent-version )
ubuntu=$( tail -n 1 ../linux/ubuntu/versions )
windowscore=$( tail -n 1 ../windows/core/versions )

docker manifest create "$registry/$name:$tag" \
    "$registry/$name:windows-core-$windowscore-$tag" \
    "$registry/$name:ubuntu-$ubuntu-$tag"
