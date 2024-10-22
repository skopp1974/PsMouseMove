
# Define the number of times to launch the executable
$InstanceCount = 5
# Define the interval between launches in seconds
$launchInterval = 5

# If using ISE
if ($psISE) {
    $RootPath = Split-Path -Parent $psISE.CurrentFile.FullPath
}
elseif ($PSVersionTable.PSVersion.Major -gt 3) {
    $RootPath = $PSScriptRoot
}
else {
    $RootPath = Split-Path -Parent $MyInvocation.MyCommand.Path
}
Set-Location $RootPath

$exePath = Join-Path $RootPath "mmove.ps1"

Write-Host "Starting parallel execution of $exePath, launching $InstanceCount instances with $launchInterval second intervals."
Write-Host "Press CTRL + X to terminate all jobs."

if (-Not (Test-Path $exePath)) {
    Write-Host "Error: The specified file does not exist at $exePath." -ForegroundColor Red
    exit 1
}

# Start jobs in parallel
$jobs = @()
for ($i = 1; $i -le $InstanceCount; $i++) {
    Write-Output "Launching instance [$i] of [$exePath]."
    $job = Start-Job -ScriptBlock {
        param ($exePath)
        try {
            & $exePath
            Write-Output "Successfully launched $exePath in Job $($using:i)."
        }
        catch {
            Write-Output "Error occurred in Job $($using:i): $($_.Exception.Message)" -ForegroundColor Red
        }
    } -ArgumentList $exePath

    $jobs += $job
    Start-Sleep -Seconds $launchInterval
}

function Find-X {
    Write-Host "Press 'x' to exit" -ForegroundColor Yellow
    while ($true) {
        if ($Host.UI.RawUI.KeyAvailable) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            if ($key.VirtualKeyCode -eq 88) {
                Write-Host "Received X"
                return $true
            }
        }
        Start-Sleep -Milliseconds 100
    }
}

Find-X

# Cleanup
foreach ($job in $jobs) {
    Stop-Job -Job $job
    Remove-Job -Job $job -Force
}

Write-Host "All jobs terminated."
