[CmdletBinding()]
param (
    [string]$PortTestTarget = "google.com",

    [int[]]$Ports = @(80, 443),

    [string]$ReportPath = ".\Reports",

    [switch]$Demo
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# PowerShell IT Administration & Troubleshooting Toolkit
# Main Health Check
# ------------------------------------------------------------

$modulePath = Join-Path $PSScriptRoot "Modules"

$modules = @(
    "Get-SystemInventory.ps1",
    "Get-DiskHealth.ps1",
    "Get-ServiceHealth.ps1",
    "Test-NetworkHealth.ps1",
    "Test-PortConnectivity.ps1",
    "New-HealthCheckReport.ps1",
    "Export-HealthCheckData.ps1"
)

Write-Host ""
Write-Host "============================================="
Write-Host "   PowerShell IT Health Check"
Write-Host "============================================="
Write-Host ""

# Load modules
foreach ($module in $modules) {

    $fullPath = Join-Path $modulePath $module

    if (-not (Test-Path $fullPath)) {
        throw "Required module not found: $fullPath"
    }

    . $fullPath
}

Write-Host "[1/5] Collecting system inventory..."
$inventory = Get-SystemInventory

Write-Host "[2/5] Checking disk health..."
$diskHealth = @(Get-DiskHealth)

Write-Host "[3/5] Checking Windows services..."
$serviceHealth = @(Get-ServiceHealth)

Write-Host "[4/5] Testing network health..."
$networkHealth = Test-NetworkHealth

Write-Host "[5/5] Testing TCP connectivity..."
$portHealth = @(
    Test-PortConnectivity `
        -ComputerName $PortTestTarget `
        -Port $Ports
)

# ------------------------------------------------------------
# Determine overall health
# ------------------------------------------------------------

$issues = @()

foreach ($disk in $diskHealth) {
    if ($disk.Status -ne "Healthy") {
        $issues += "Disk $($disk.Drive) is $($disk.Status)"
    }
}

foreach ($service in $serviceHealth) {
    if ($service.Health -ne "Healthy") {
        $issues += "Service $($service.ServiceName): $($service.Health)"
    }
}

if ($networkHealth.Status -ne "Healthy") {
    $issues += "Network status: $($networkHealth.Status)"
}

foreach ($port in $portHealth) {
    if (-not $port.Reachable) {
        $issues += "TCP port $($port.Port) on $($port.ComputerName) is $($port.Status)"
    }
}

$overallStatus = if ($issues.Count -eq 0) {
    "Healthy"
}
elseif (
    $diskHealth.Status -contains "Critical" -or
    $networkHealth.Status -eq "Critical"
) {
    "Critical"
}
else {
    "Warning"
}

$result = [PSCustomObject]@{
    GeneratedAt   = Get-Date
    ComputerName  = $env:COMPUTERNAME
    OverallStatus = $overallStatus
    IssueCount    = $issues.Count
    Inventory     = $inventory
    DiskHealth    = $diskHealth
    ServiceHealth = $serviceHealth
    NetworkHealth = $networkHealth
    PortHealth    = $portHealth
    Issues        = $issues
}

# ------------------------------------------------------------
# Portfolio demo / sanitized output
# ------------------------------------------------------------

if ($Demo) {

    Write-Host ""
    Write-Host "Demo mode enabled - sanitizing system information..."

    # Computer identity
    $result.ComputerName = "WS-FINANCE-023"

    $result.Inventory.ComputerName = "WS-FINANCE-023"
    $result.Inventory.SerialNumber = "DEMO-SERIAL-001"
    $result.Inventory.LoggedOnUser = "CONTOSO\j.smith"
    $result.Inventory.Domain = "CONTOSO"

    # Primary network health information
    $result.NetworkHealth.IPv4Address = "192.168.10.25"
    $result.NetworkHealth.Gateway = "192.168.10.1"
    $result.NetworkHealth.DNSServers = "192.168.10.10"

    # Sanitize network adapter inventory
    $adapterIndex = 1

    foreach ($adapter in $result.Inventory.NetworkAdapters) {

        $adapter.IPv4Address = "192.168.10.$(24 + $adapterIndex)"
        $adapter.MACAddress = "00:11:22:33:44:$('{0:X2}' -f $adapterIndex)"

        if ($adapter.DHCPEnabled) {
            $adapter.Gateway = "192.168.10.1"
            $adapter.DNSServers = "192.168.10.10"
        }
        else {
            $adapter.Gateway = $null
            $adapter.DNSServers = $null
        }

        $adapterIndex++
    }
}

Write-Host ""
Write-Host "============================================="
Write-Host "   Health Check Complete"
Write-Host "============================================="
Write-Host ""

Write-Host "Computer:       $($result.ComputerName)"
Write-Host "Overall Status: $($result.OverallStatus)"
Write-Host "Issues Found:   $($result.IssueCount)"
Write-Host ""

if ($issues.Count -gt 0) {

    Write-Host "Detected issues:"

    foreach ($issue in $issues) {
        Write-Host " - $issue"
    }
}

Write-Host ""

# ------------------------------------------------------------
# Generate HTML report
# ------------------------------------------------------------

Write-Host "Generating HTML report..."

$reportFile = New-HealthCheckReport `
    -HealthCheck $result `
    -OutputPath $ReportPath

Write-Host "Report created:"
Write-Host $reportFile
Write-Host ""

# ------------------------------------------------------------
# Export JSON and CSV data
# ------------------------------------------------------------

Write-Host "Exporting JSON and CSV data..."

$exportFiles = Export-HealthCheckData `
    -HealthCheck $result `
    -OutputPath $ReportPath

Write-Host "JSON created:"
Write-Host $exportFiles.JsonFile

Write-Host "CSV created:"
Write-Host $exportFiles.CsvFile
Write-Host ""

# Open report in the default browser
Start-Process $reportFile

return $result