.\update.ps1

Write-Output "`n------------------------------------------------------`n"

# Arguments can be done with:
# --build-arg http_proxy="http://proxy.company.com:8080" \
# this must be done in the line before ".\Output\$dir" because the image name has to be the last parameter


foreach($dir in .\dirs.ps1){
    Write-Output "Build Docker Image for:`n    $dir"
    docker build --compress `
    -t czon/azdo-agent:windows-$(($dir -replace '\\','-').ToLower() ) `
    -m 6GB `
    ".\Output\$dir"
    Write-Output "`n------------------------------------------------------`n"
}
