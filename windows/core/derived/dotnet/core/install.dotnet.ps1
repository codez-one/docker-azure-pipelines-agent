Param(
  [string]$DOTNET_CORE_SDK_VERSION,
  [string]$DOTNET_CORE_CHANNEL
)

cd C:\Setup\; 
.\dotnet-install.ps1 -Version "$DOTNET_CORE_SDK_VERSION" -Architecture "x64" -Channel "$DOTNET_CORE_CHANNEL" -InstallDir C:\dotnet -Verbose;
#because semicolon and backslash will start a new command we convert the ascii number to the symbol(("C:" + ([char]92).ToString() + "dotnet" + ([char]59).ToString()) + $env:PATH)
[Environment]::SetEnvironmentVariable("PATH", $env:PATH, [System.EnvironmentVariableTarget]::Machine); 