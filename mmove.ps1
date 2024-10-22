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
