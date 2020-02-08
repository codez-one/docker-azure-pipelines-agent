Param(

)

Begin {
    Set-Location "C:\TFS\Agent"

    if (!$env:AZDO_URL) {
        Write-Error "error: missing AZDO_URL environment variable"
        exit 1
    }

    if ((!$env:AZDO_USER) -and (!$env:AZDO_TOKEN)) {
        Write-Error "error: missing AZDO_USER environment variable"
        exit 1
    }

    if ((!$env:AZDO_PASSWORD) -and (!$env:AZDO_TOKEN)) {
        Write-Error "error: missing AZDO_PASSWORD environment variable"
        exit 1
    }

    if ((!$env:AZDO_USER) -and (!$env:AZDO_PASSWORD) -and (!$env:AZDO_TOKEN)) {
        Write-Error "error: missing AZDO_TOKEN environment variable"
        exit 1
    }

    if (!$env:AZDO_AGENT) {
        $env:AZDO_AGENT = "Windows_$(hostname)"
    }

    if (!$env:AZDO_WORK) {
        $env:AZDO_WORK = "_work"
    }

    $argpool = ""
    if ($env:AZDO_DEPLOYMENT_POOL) {
        if ($env:AZDO_POOL) {
            Write-Error "error: cannot set AZDO_DEPLOYMENT_POOL and AZDO_POOL environment variables"
            exit 1
        }

        $argpool = "--deploymentpool --deploymentpoolname `"$env:AZDO_DEPLOYMENT_POOL`""
    }
    else {
        if (!$env:AZDO_POOL) {
            $env:AZDO_POOL = "Default"
        }

        $argpool = "--pool `"$env:AZDO_POOL`""
    }
    
    $argagentauth = ""
    if (($env:AZDO_USER) -and ($env:AZDO_PASSWORD)) {
        $argagentauth = "--auth negotiate --username `"$env:AZDO_USER`" --password `"$env:AZDO_PASSWORD`""
    }
    else {
        $argagentauth = "--auth PAT --token $env:AZDO_TOKEN"
    }

    $argagentonce = ""
    if ($env:AZDO_AGENT_DISPOSE) {
        $argagentonce = "--once"
    }

    function Cleanup () {
        if (Test-Path ".\config.cmd") {
            Invoke-Expression "& .\config.cmd remove --unattended $argagentauth"
        }    
    }    

    $env:VSO_AGENT_IGNORE = "MAIL,OLDPWD,PATH,PWD,VSO_AGENT_IGNORE,AZDO_AGENT,AZDO_URL,AZDO_USER,AZDO_PASSWORD,AZDO_POOL,AZDO_DEPLOYMENT_POOL,AZDO_WORK,AZDO_AGENT_DISPOSE,DOTNET_CLI_TELEMETRY_OPTOUT"
}    

Process {
    Write-Output "Configure Agent ..."

    $addcommand = "& .\config.cmd --unattended --url `"$env:AZDO_URL`" --agent `"$env:AZDO_AGENT`" --work `"$env:AZDO_WORK`" --replace $argagentauth $argpool $argagentonce"
    Write-Output $addcommand

    try {
        Invoke-Expression $addcommand
        Invoke-Expression "& .\run.cmd"
    }
    finally {
        Cleanup;
    }
}

End {
    
}