# Start-SteelSeriesGG.ps1
# This script starts the SteelSeriesGG application and minimizes its client windows.
# Disable the option in the SteelSeriesGG application to run SteelSeriesGG at startup and use this script instead to launch at startup or login.
# You may want to remove the SteelSeriesGG shortcuts in the Windows start menu ss another precaution to stop multiple instances from running. 

# Add necessary types for interop with Windows API
# This allows us to manipulate window states such as minimizing.
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

# Enumerate any existing SteelSeriesGG processes to avoid launching multiple instances
$ggProcesses = Get-Process -Name "SteelSeriesGG" -ErrorAction SilentlyContinue
if ($ggProcesses.count -eq 0) { 
    # No existing process found, start a new instance and wait a bit for it to initialize
    Start-Process 'C:\Program Files\SteelSeries\GG\SteelSeriesGG.exe' -ArgumentList '-dbEnv=production', '-dataPath="C:\ProgramData\SteelSeries\GG"' -WorkingDirectory 'C:\Program Files\SteelSeries\GG'

    # SteelSeriesGG launches 6 StelSeriesGGClient processes so wait until they are all running
    $clientProcesses = 0
    while ($clientProcesses.Count -lt 6) {
        $clientProcesses = Get-Process -Name "SteelSeriesGGClient" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    # Minimize and close all running SteelSeriesGGClient windows
    foreach ($clientProcess in $clientProcesses) {
        $hwnd = $clientProcess.MainWindowHandle
        if ($hwnd -ne 0) {
            # Minimize the window (SW_MINIMIZE = 6)
            [void][Win32]::ShowWindow($hwnd, 6)
        }
        $clientProcess.CloseMainWindow() | Out-Null
    }
}