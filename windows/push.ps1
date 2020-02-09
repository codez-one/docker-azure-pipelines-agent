param (
    [string]$registry = "czon",
    [string]$name = "azdo-agent"
)

Write-Output "`n------------------------------------------------------`n"

foreach ($dir in .\dirs.ps1) {
    Write-Output "Push Docker Image for:`n    $dir"
    docker push $registry/$($name):windows-$(($dir -replace '\\','-').ToLower() )
    Write-Output "`n------------------------------------------------------`n"
}

# Push latest tagged image if available
if (docker images -f reference="$registry/$name:latest" -q) {
    docker push "$registry/$($name):latest"
}
