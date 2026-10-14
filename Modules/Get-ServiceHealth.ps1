function Get-ServiceHealth {
    [CmdletBinding()]
    param (
        [string[]]$ServiceName = @(
            "wuauserv",
            "WinDefend",
            "Dnscache",
            "Dhcp",
            "EventLog"
        )
    )

    foreach ($name in $ServiceName) {
        try {
            $service = Get-Service -Name $name -ErrorAction Stop

            [PSCustomObject]@{
                ServiceName = $service.Name
                DisplayName = $service.DisplayName
                Status      = $service.Status.ToString()
                StartType   = $service.StartType.ToString()
                Health      = if ($service.Status -eq "Running") {
                    "Healthy"
                }
                else {
                    "Attention"
                }
            }
        }
        catch {
            [PSCustomObject]@{
                ServiceName = $name
                DisplayName = "Not found"
                Status      = "Unknown"
                StartType   = "Unknown"
                Health      = "Not Found"
            }
        }
    }
}