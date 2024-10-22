
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

# Load necessary .NET assemblies for mouse movement
Add-Type -AssemblyName System.Windows.Forms

# Define the necessary Windows API methods for setting cursor position and sending keystrokes
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class WinAPI
    {
        [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
        public static extern void SetCursorPos(int x, int y);

        [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
        public static extern void mouse_event(int flags, int dx, int dy, int buttons, int extraInfo);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

        public const int KEYEVENTF_KEYDOWN = 0x0000;
        public const int KEYEVENTF_KEYUP = 0x0002;
        public const byte VK_CAPITAL = 0x14; // Caps Lock key
    }
"@

# Function to move the mouse to a random position on the screen
function Move-MouseRandom {
    $screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
    $screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

    # Generate random coordinates within the screen's width and height
    $randomX = Get-Random -Minimum 0 -Maximum $screenWidth
    $randomY = Get-Random -Minimum 0 -Maximum $screenHeight

    Write-Host "($randomX, $randomY)"

    # Move the mouse to the random coordinates
    [WinAPI]::SetCursorPos($randomX, $randomY)
}

# Function to simulate a key press (Caps Lock in this case)
function Send-KeyPress {
    # Press the Caps Lock key down
    [WinAPI]::keybd_event([WinAPI]::VK_CAPITAL, 0, [WinAPI]::KEYEVENTF_KEYDOWN, [UIntPtr]::Zero)
    Start-Sleep -Seconds 1
    # Release the Caps Lock key
    [WinAPI]::keybd_event([WinAPI]::VK_CAPITAL, 0, [WinAPI]::KEYEVENTF_KEYUP, [UIntPtr]::Zero)
}

# Run indefinitely every 20 seconds
while ($true) {
    Move-MouseRandom   # Move the mouse to a random position
    Send-KeyPress      # Simulate a key press
    Start-Sleep -Seconds 20   # Wait for 20 seconds
}
    }

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
