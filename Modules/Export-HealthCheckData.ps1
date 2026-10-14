function Export-HealthCheckData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$HealthCheck,

        [string]$OutputPath = ".\Reports"
    )

    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $baseName = "IT-Health-Check_$($HealthCheck.ComputerName)_$timestamp"

    # ------------------------------------------------------------
    # JSON export - complete health check dataset
    # ------------------------------------------------------------

    $jsonFile = Join-Path $OutputPath "$baseName.json"

    $HealthCheck |
        ConvertTo-Json -Depth 10 |
        Out-File -FilePath $jsonFile -Encoding UTF8

    # ------------------------------------------------------------
    # CSV export - summary suitable for Excel / reporting
    # ------------------------------------------------------------

    $csvFile = Join-Path $OutputPath "$baseName.csv"

    $summary = [PSCustomObject]@{
        GeneratedAt       = $HealthCheck.GeneratedAt
        ComputerName      = $HealthCheck.ComputerName
        OverallStatus     = $HealthCheck.OverallStatus
        IssueCount        = $HealthCheck.IssueCount
        OperatingSystem   = $HealthCheck.Inventory.OperatingSystem
        WindowsBuild      = $HealthCheck.Inventory.WindowsBuild
        CPU               = $HealthCheck.Inventory.CPU
        RAM_GB            = $HealthCheck.Inventory.RAM_GB
        NetworkStatus     = $HealthCheck.NetworkHealth.Status
        IPv4Address       = $HealthCheck.NetworkHealth.IPv4Address
        Gateway           = $HealthCheck.NetworkHealth.Gateway
        InternetReachable = $HealthCheck.NetworkHealth.InternetReachable
        DNSWorking        = $HealthCheck.NetworkHealth.DNSWorking
    }

    $summary |
        Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8

    return [PSCustomObject]@{
        JsonFile = $jsonFile
        CsvFile  = $csvFile
    }
}