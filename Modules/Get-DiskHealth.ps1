function Get-DiskHealth {
    [CmdletBinding()]
    param (
        [int]$WarningThreshold = 20,
        [int]$CriticalThreshold = 10
    )

    try {
        $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"

        foreach ($disk in $disks) {

            $sizeGB = [math]::Round($disk.Size / 1GB, 2)
            $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)

            if ($disk.Size -gt 0) {
                $freePercent = [math]::Round(
                    ($disk.FreeSpace / $disk.Size) * 100,
                    1
                )
            }
            else {
                $freePercent = 0
            }

            $status = if ($freePercent -lt $CriticalThreshold) {
                "Critical"
            }
            elseif ($freePercent -lt $WarningThreshold) {
                "Warning"
            }
            else {
                "Healthy"
            }

            [PSCustomObject]@{
                Drive        = $disk.DeviceID
                SizeGB       = $sizeGB
                FreeSpaceGB  = $freeSpaceGB
                FreePercent  = $freePercent
                Status       = $status
            }
        }
    }
    catch {
        Write-Error "Failed to check disk health: $($_.Exception.Message)"
    }
}