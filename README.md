# Azure Pipelines Agent Docker Container

[![Downloads from Docker Hub](https://img.shields.io/docker/pulls/czon/azdo-agent.svg)](https://hub.docker.com/r/czon/azdo-agent)
[![Stars on Docker Hub](https://img.shields.io/docker/stars/czon/azdo-agent.svg)](https://hub.docker.com/r/czon/azdo-agent)
[![](https://images.microbadger.com/badges/image/czon/azdo-agent.svg)](https://microbadger.com/images/czon/azdo-agent)
[![](https://images.microbadger.com/badges/version/czon/azdo-agent.svg)](https://microbadger.com/images/czon/azdo-agent)
[![Build Status](https://dev.azure.com/czon/Docker%20Azure%20Pipelines%20Agent/_apis/build/status/codez-one.docker-azure-pipelines-agent?branchName=master)](https://dev.azure.com/czon/Docker%20Azure%20Pipelines%20Agent/_build/latest?definitionId=2&branchName=master)


This is a Docker based project for automatically generating docker images for Azure DevOps Pipelines Agents with specified Versions. The resulting Docker images should be used as a base for project specific agents that are customized to the needs for the pipeline in your project.

> **Info**: The Windows images are not maintained at the moment.

## How to use these images
Azure Pipelines agents must be started with account connection information, which is provided through environment variables listet below.

To run the default Azure Pipelines agent image for a specific Azure DevOps account:

```
docker run \
  -e AZDO_URL=<url> \
  -e AZDO_TOKEN=<pat> \
  -it czon/azdo-agent
```

A more secure option for passing the personal access token is supported by mounting a file that contains the token into the container and specifying the location of this file with the `AZDO_TOKEN_FILE` environment variable. For instance:

```
docker run \
  -v /path/to/my/token:/azdo-token \
  -e AZDO_URL=<url> \
  -e AZDO_TOKEN_FILE=/azdo-token \
  -it czon/azdo-agent
```

The same applies for the usage of the `AZDO_PASSWORD` environment variable. It is better to use `AZDO_PASSWORD_FILE`.

Agents can be further configured with additional environment variables:

- `AZDO_AGENT`: the name of the agent (default: `"$(hostname)"`)
- `AZDO_POOL`: the name of the agent pool (default: `"Default"`)
- `AZDO_WORK`: the agent work folder (default: `"_work"`)

The `AZDO_AGENT` and `AZDO_WORK` values are evaluated inside the container as an expression so they can use shell expansions. The `AZDO_AGENT` value is evaluated first, so the `AZDO_WORK` value may reference the expanded `AZDO_AGENT` value.

To run a Azure DevOps agent on Ubuntu 18.04 for a specific account with a custom agent name, pool and a volume mapped agent work folder:

```
docker run \
  -e AZDO_URL=<url> \
  -e AZDO_TOKEN=<pat> \
  -e AZDO_AGENT='$(hostname)-agent' \
  -e AZDO_POOL=mypool \
  -e AZDO_WORK='/var/azdo/$AZDO_AGENT' \
  -v /var/azdo:/var/azdo \
  -it czon/azdo-agent:ubuntu-18.04
```

## Configuration

All the variables below will be ignored by the agent by default and will not be visible as capabilities of the agent

### Required

`AZDO_URL`

The complete url of the Azure DevOps account (e.g. "https://dev.azure.com/czon/" or "https://tfs.company.com/tfs/").

#### Authentification with Token (recommended)

`AZDO_TOKEN`

A personal access token (PAT) for the Azure DevOps account that has been given at least the **Agent Pools (read, manage)** scope.

`AZDO_TOKEN_FILE`

A path to a simple File with only the token in it.

> **Caution** Be aware of that this file can be accessed inside a job running on the agent.

#### Authentification with User and Password

This option is **not recommended** becouse the values can not be stored safely and if someone get acces to it he can login to AzDO as this user.

`AZDO_USER`

`AZDO_PASSWORD`

`AZDO_PASSWORD_FILE`

A path to a simple File with only the password in it.

> **Caution** Be aware of that this file can be accessed inside a job running on the agent.

### Optional

#### Environment

`AZDO_AGENT`

The Name of the Agent as it will appear in the agent pool view of AzDO

`AZDO_WORK`

If you want the agent to use an other forlder for his jobs you can specify it here. The default is: `/azdo/agent/_work/`

`AZDO_ENV_IGNORE`

This is a `,` seperated list of environment variables which will be ignored by the agent while scanning for capabilities. This may be usefull if you have avariable used in your dokerfile but do not want it to show up in the capabilities list-

`AZDO_ENV_EXCLUDE`

This is a `,` seperated list of environment variables which will be excludes from the environment the agent is running in. This is usefull for variables with secrets that are not necessary at the runtime of the agent.

`AZDO_ENV_INCLUDE`

This is a `,` seperated list of environment variables which will be added to the environment the agent is running in. For example you can add something like that: `"Agent.Project=Sample Project"`. With this you can use this value in the demands of your job.

#### Behaviour

`AZDO_AGENT_DISPOSE`

The agent will take only one job and than shut down and deregister itself.

## Development

### Getting Started
> Notice: The preferred Development Environment is Windows with the integrated WSL Bash.

1. [Download and Install Docker](https://docs.docker.com/docker-for-windows/install/) 
2. If you are on Windows install the Ubuntu Bash ([Windows-Store](https://www.microsoft.com/en-us/p/ubuntu/9nblggh4msv6))
3. Happy Coding!

### Build

The `update.sh` script generates Dockerfiles from  `*.templates` files.  
In order to build your Dockerimages from the Dockerfiles run `build.sh`.

### Run
To run a container and register it in Azure DevOps run `run.sh`.

Example:

```
./run.sh czon/azdo-agent:ubuntu-18.04-2.155.1 -s https://dev.azure.com/czon/ -n TestAgent01 -p DockerSamples -c -d -i
```

### Contribute

Build your own DockerFiles/Images based on Linux or Windows: 
 1. Add a Template File for your variation. In order to do so create a dockerfile.template and a versions file.
 2. Register your Template in `update.sh`, run it in order to generate a Dockerfile
 3. Run `build.sh` to build a dockerimage from all dockerfiles.

## Authors

-   **Kirsten Kluge** - _Initial work_ - [kirkone](https://github.com/kirkone)

See also the list of [contributors](https://github.com/codez-one/docker-azure-pipelines-agent/graphs/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Acknowledgments

Based on this:
- [microsoft/vsts-agent-docker](https://github.com/microsoft/vsts-agent-docker)
- [Microsoft Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops)
