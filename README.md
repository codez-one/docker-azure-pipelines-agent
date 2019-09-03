# Azure Pipelines Agent Docker Container

This is a Docker based project for automatically generating docker images for Azure DevOps Pipelines Agents with specified Versions.

> **Caution**: This is work in progress and not ready for production use jet!

> **Info**: The Windows images are not maintained at the moment.

## Goal 
This project should be the basement for automated Build Agent Pools. In order to accomplish the following goals:
 - Each project can build its own Tool and Version specific Build Machine, based on a docker image, without intevening other Project builds. 
 - The Docker Images (Build Machines) are versioned, this allows easy rollback mechanisms, if an update of a Tool failed.
 - The scalability of Agents improves significantly (The number of Agents can be increased according to load)

## How to use these images
Azure Pipelines agents must be started with account connection information, which is provided through two environment variables:

- `AZDO_ACCOUNT`: the name of the Visual Studio account
- `AZDO_TOKEN`: a personal access token (PAT) for the Visual Studio account that has been given at least the **Agent Pools (read, manage)** scope.

To run the default Azure Pipelines agent image for a specific Azure DevOps account:

```
docker run \
  -e AZDO_ACCOUNT=<name> \
  -e AZDO_TOKEN=<pat> \
  -it czon/azdo-agent
```

When using an image that targets a specific TFS version, the connection information is instead supplied through one of the following environment variables:

- `TFS_HOST`: the hostname of the Team Foundation Server
- `TFS_URL`: the full URL of the Team Foundation Server
- `AZDO_TOKEN`: a personal access token (PAT) for the Team Foundation Server account that has been given at least the **Agent Pools (read, manage)** scope.

If `TFS_HOST` is provided, the TFS URL is set to `https://$TFS_HOST/tfs`. If `TFS_URL` is provided, any `TFS_HOST` environment variable is ignored.

To run a VSTS agent image for TFS 2018 that identifies the server at `https://mytfs/tfs`:

```
docker run \
  -e TFS_HOST=mytfs \
  -e AZDO_TOKEN=<pat> \
  -it microsoft/vsts-agent:ubuntu-16.04-tfs-2018
```

A more secure option for passing the personal access token is supported by mounting a file that contains the token into the container and specifying the location of this file with the `AZDO_TOKEN_FILE` environment variable. For instance:

```
docker run \
  -v /path/to/my/token:/vsts-token \
  -e AZDO_ACCOUNT=<name> \
  -e AZDO_TOKEN_FILE=/vsts-token \
  -it microsoft/vsts-agent
```

Whether targeting VSTS or TFS, agents can be further configured with additional environment variables:

- `AZDO_AGENT`: the name of the agent (default: `"$(hostname)"`)
- `AZDO_POOL`: the name of the agent pool (default: `"Default"`)
- `AZDO_WORK`: the agent work folder (default: `"_work"`)

The `AZDO_AGENT` and `AZDO_WORK` values are evaluated inside the container as an expression so they can use shell expansions. The `AZDO_AGENT` value is evaluated first, so the `AZDO_WORK` value may reference the expanded `AZDO_AGENT` value.

To run a VSTS agent on Ubuntu 18.04 for a specific account with a custom agent name, pool and a volume mapped agent work folder:

```
docker run \
  -e AZDO_ACCOUNT=<name> \
  -e AZDO_TOKEN=<pat> \
  -e AZDO_AGENT='$(hostname)-agent' \
  -e AZDO_POOL=mypool \
  -e AZDO_WORK='/var/vsts/$AZDO_AGENT' \
  -v /var/vsts:/var/vsts \
  -it microsoft/vsts-agent:ubuntu-18.04
```

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
./run.sh czon/azdo-agent:ubuntu-stretch-slim-2.155.1 -s https://dev.azure.com/czon/ -n TestAgent01 -p DockerSamples -c -d -i
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
