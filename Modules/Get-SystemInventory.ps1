<#
.SYNOPSIS
    Collects basic hardware, operating system, user and network information.

.DESCRIPTION
    Get-SystemInventory collects useful system information from a Windows
    computer for IT administration, troubleshooting and documentation.

.NOTES
    Project: PowerShell IT Administration & Troubleshooting Toolkit
#>

function Get-SystemInventory {

    [CmdletBinding()]
    param()

    try {
        # Operating System
        $os = Get-CimInstance -ClassName Win32_OperatingSystem

        # Computer System
        $computer = Get-CimInstance -ClassName Win32_ComputerSystem

        # BIOS
        $bios = Get-CimInstance -ClassName Win32_BIOS

        # CPU
        $cpu = Get-CimInstance -ClassName Win32_Processor |
            Select-Object -First 1

        # Physical disks
        $disks = Get-CimInstance -ClassName Win32_LogicalDisk `
            -Filter "DriveType = 3"

        # Active network adapters
        $networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration |
            Where-Object { $_.IPEnabled -eq $true }

        # Calculate uptime
        $uptime = (Get-Date) - $os.LastBootUpTime

        # Convert RAM to GB
        $totalRAMGB = [math]::Round(
            $computer.TotalPhysicalMemory / 1GB,
            2
        )

        # Network information
        $networkInfo = foreach ($adapter in $networkAdapters) {

            $ipv4 = $adapter.IPAddress |
                Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' }

            [PSCustomObject]@{
                Description = $adapter.Description
                IPv4Address = ($ipv4 -join ', ')
                MACAddress  = $adapter.MACAddress
                DHCPEnabled = $adapter.DHCPEnabled
                Gateway     = ($adapter.DefaultIPGateway -join ', ')
                DNSServers  = ($adapter.DNSServerSearchOrder -join ', ')
            }
        }

        # Disk information
        $diskInfo = foreach ($disk in $disks) {

            $sizeGB = [math]::Round($disk.Size / 1GB, 2)
            $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)

            if ($disk.Size -gt 0) {
                $freePercent = [math]::Round(
                    ($disk.FreeSpace / $disk.Size) * 100,
                    1
                )
            }
            else {
                $freePercent = 0
            }

            [PSCustomObject]@{
                Drive       = $disk.DeviceID
                SizeGB      = $sizeGB
                FreeSpaceGB = $freeGB
                FreePercent = $freePercent
            }
        }

        # Main inventory object
        [PSCustomObject]@{

            ComputerName = $env:COMPUTERNAME

            Manufacturer = $computer.Manufacturer
            Model        = $computer.Model

            SerialNumber = $bios.SerialNumber

            LoggedOnUser = $computer.UserName

            Domain       = $computer.Domain

            OperatingSystem = $os.Caption
            WindowsVersion  = $os.Version
            WindowsBuild    = $os.BuildNumber

            Architecture = $os.OSArchitecture

            CPU = $cpu.Name

            RAM_GB = $totalRAMGB

            LastBootTime = $os.LastBootUpTime

            Uptime = "{0} days, {1} hours, {2} minutes" -f `
                $uptime.Days,
                $uptime.Hours,
                $uptime.Minutes

            Disks = $diskInfo

            NetworkAdapters = $networkInfo
        }
    }
    catch {
        Write-Error "Failed to collect system inventory: $($_.Exception.Message)"
    }
}