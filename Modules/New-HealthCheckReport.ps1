function New-HealthCheckReport {
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

    $fileName = "IT-Health-Check_$($HealthCheck.ComputerName)_$timestamp.html"

    $reportFile = Join-Path $OutputPath $fileName

    $statusClass = switch ($HealthCheck.OverallStatus) {
        "Healthy"  { "healthy" }
        "Warning"  { "warning" }
        "Critical" { "critical" }
        default    { "unknown" }
    }

    $diskRows = foreach ($disk in $HealthCheck.DiskHealth) {

    $diskStatusClass = switch ($disk.Status) {
        "Healthy"  { "healthy" }
        "Warning"  { "warning" }
        "Critical" { "critical" }
        default    { "unknown" }
    }

    "<tr>
        <td><strong>$($disk.Drive)</strong></td>
        <td>$($disk.SizeGB) GB</td>
        <td>$($disk.FreeSpaceGB) GB</td>
        <td>
            <div class='progress'>
                <div class='progress-bar $diskStatusClass'
                     style='width: $($disk.FreePercent)%'>
                </div>
            </div>
            <span class='progress-text'>$($disk.FreePercent)% free</span>
        </td>
        <td>
            <span class='status $diskStatusClass'>
                $($disk.Status)
            </span>
        </td>
    </tr>"
}

    $serviceRows = foreach ($service in $HealthCheck.ServiceHealth) {

    $serviceHealthClass = switch ($service.Health) {
        "Healthy"   { "healthy" }
        "Attention" { "warning" }
        "Warning"   { "warning" }
        "Critical"  { "critical" }
        default     { "unknown" }
    }

    $serviceStatusClass = switch ($service.Status) {
        "Running" { "healthy" }
        "Stopped" { "warning" }
        default   { "unknown" }
    }

    "<tr>
        <td><strong>$($service.ServiceName)</strong></td>
        <td>$($service.DisplayName)</td>
        <td>
            <span class='status-small $serviceStatusClass'>
                $($service.Status)
            </span>
        </td>
        <td>$($service.StartType)</td>
        <td>
            <span class='status $serviceHealthClass'>
                $($service.Health)
            </span>
        </td>
    </tr>"
}
$gatewayClass = if ($HealthCheck.NetworkHealth.GatewayReachable) {
    "healthy"
} else {
    "critical"
}

$gatewayText = if ($HealthCheck.NetworkHealth.GatewayReachable) {
    "Reachable"
} else {
    "Unreachable"
}

$internetClass = if ($HealthCheck.NetworkHealth.InternetReachable) {
    "healthy"
} else {
    "critical"
}

$internetText = if ($HealthCheck.NetworkHealth.InternetReachable) {
    "Connected"
} else {
    "Unavailable"
}

$dnsClass = if ($HealthCheck.NetworkHealth.DNSWorking) {
    "healthy"
} else {
    "critical"
}

$dnsText = if ($HealthCheck.NetworkHealth.DNSWorking) {
    "Working"
} else {
    "Failed"
}

    $portRows = foreach ($port in $HealthCheck.PortHealth) {

    $portStatusClass = if ($port.Reachable -or $port.Status -eq "Open") {
        "healthy"
    } else {
        "critical"
    }

    "<tr>
        <td><strong>$($port.ComputerName)</strong></td>
        <td>$($port.Port)</td>
        <td>$($port.Protocol)</td>
        <td>
            <span class='status $portStatusClass'>
                $($port.Status)
            </span>
        </td>
        <td>$($port.ResponseTimeMs) ms</td>
    </tr>"
}

 $issueItems = @()

# Disk issues
foreach ($disk in $HealthCheck.DiskHealth) {

    if ($disk.Status -eq "Critical") {

        $issueItems += "
        <div class='issue-card issue-critical'>
            <div class='issue-title'>
                Critical - Disk $($disk.Drive)
            </div>
            <div class='issue-description'>
                Only $($disk.FreePercent)% free space remaining
                ($($disk.FreeSpaceGB) GB free of $($disk.SizeGB) GB).
                Free up disk space to prevent performance and system stability issues.
            </div>
        </div>"
    }
    elseif ($disk.Status -eq "Warning") {

        $issueItems += "
        <div class='issue-card issue-warning'>
            <div class='issue-title'>
                Warning - Disk $($disk.Drive)
            </div>
            <div class='issue-description'>
                Disk space is running low with $($disk.FreePercent)% remaining
                ($($disk.FreeSpaceGB) GB free).
            </div>
        </div>"
    }
}

# Service issues
foreach ($service in $HealthCheck.ServiceHealth) {

    if ($service.Health -eq "Critical") {

        $issueItems += "
        <div class='issue-card issue-critical'>
            <div class='issue-title'>
                Critical - $($service.DisplayName)
            </div>
            <div class='issue-description'>
                Service '$($service.ServiceName)' is currently $($service.Status)
                and requires immediate attention.
            </div>
        </div>"
    }
    elseif (
        $service.Health -eq "Attention" -or
        $service.Health -eq "Warning"
    ) {

        $issueItems += "
        <div class='issue-card issue-warning'>
            <div class='issue-title'>
                Attention - $($service.DisplayName)
            </div>
            <div class='issue-description'>
                Service '$($service.ServiceName)' is currently $($service.Status).
                Startup type: $($service.StartType).
            </div>
        </div>"
    }
}

# Network issues
if (-not $HealthCheck.NetworkHealth.GatewayReachable) {

    $issueItems += "
    <div class='issue-card issue-critical'>
        <div class='issue-title'>
            Critical - Default Gateway
        </div>
        <div class='issue-description'>
            The configured default gateway could not be reached.
        </div>
    </div>"
}

if (-not $HealthCheck.NetworkHealth.InternetReachable) {

    $issueItems += "
    <div class='issue-card issue-critical'>
        <div class='issue-title'>
            Critical - Internet Connectivity
        </div>
        <div class='issue-description'>
            Internet connectivity test failed.
        </div>
    </div>"
}

if (-not $HealthCheck.NetworkHealth.DNSWorking) {

    $issueItems += "
    <div class='issue-card issue-warning'>
        <div class='issue-title'>
            Attention - DNS Resolution
        </div>
        <div class='issue-description'>
            DNS resolution test failed. Verify DNS server configuration and connectivity.
        </div>
    </div>"
}

# No detected issues
if ($issueItems.Count -eq 0) {

    $issueItems += "
    <div class='issue-card issue-healthy'>
        <div class='issue-title'>
            No issues detected
        </div>
        <div class='issue-description'>
            All monitored health checks completed successfully.
        </div>
    </div>"
}

    $issueCount = @($HealthCheck.Issues).Count

$criticalDiskCount = @(
    $HealthCheck.DiskHealth | Where-Object { $_.Status -eq "Critical" }
).Count


$networkStatus = if (
    $HealthCheck.NetworkHealth.GatewayReachable -and
    $HealthCheck.NetworkHealth.InternetReachable -and
    $HealthCheck.NetworkHealth.DNSWorking
) {
    "Healthy"
} else {
    "Attention"
}

$networkSummaryClass = if ($networkStatus -eq "Healthy") {
    "healthy"
} else {
    "warning"
}

    $html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">

<title>IT Health Check Report</title>

<style>

body {
    font-family: Segoe UI, Arial, sans-serif;
    background: #f4f6f8;
    margin: 0;
    padding: 40px;
    color: #1f2937;
}

.container {
    max-width: 1100px;
    margin: auto;
}

.header {
    background: #111827;
    color: white;
    padding: 30px;
    border-radius: 12px;
}

.header h1 {
    margin: 0;
}

.summary-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 15px;
    margin-top: 20px;
}

.summary-card {
    background: white;
    padding: 20px;
    border-radius: 12px;
    box-shadow: 0 2px 8px rgba(0,0,0,.08);
}

.summary-label {
    color: #6b7280;
    font-size: 12px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: .5px;
}

.summary-value {
    font-size: 24px;
    font-weight: 700;
    margin-top: 8px;
}

.summary-value.healthy {
    color: #16a34a;
}

.summary-value.warning {
    color: #d97706;
}

.summary-value.critical {
    color: #dc2626;
}

@media (max-width: 800px) {
    .summary-grid {
        grid-template-columns: repeat(2, 1fr);
    }
}

.card {
    background: white;
    margin-top: 20px;
    padding: 24px;
    border-radius: 12px;
    box-shadow: 0 2px 8px rgba(0,0,0,.08);
}

.status {
    display: inline-block;
    padding: 8px 14px;
    border-radius: 20px;
    font-weight: bold;
}
    .status-small {
    display: inline-block;
    padding: 4px 8px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: 600;
}

.status-small.healthy {
    background: #dcfce7;
    color: #166534;
}

.status-small.warning {
    background: #fef3c7;
    color: #92400e;
}

.status-small.critical {
    background: #fee2e2;
    color: #991b1b;
}

.status-small.unknown {
    background: #e5e7eb;
    color: #374151;
}

.healthy {
    background: #dcfce7;
    color: #166534;
}

.warning {
    background: #fef3c7;
    color: #92400e;
}

.critical {
    background: #fee2e2;
    color: #991b1b;
}

.unknown {
    background: #e5e7eb;
    color: #374151;
}
    .progress {
    width: 140px;
    height: 8px;
    background: #e5e7eb;
    border-radius: 10px;
    overflow: hidden;
    margin-bottom: 5px;
}

.progress-bar {
    height: 100%;
    border-radius: 10px;
}

.progress-bar.healthy {
    background: #22c55e;
}

.progress-bar.warning {
    background: #f59e0b;
}

.progress-bar.critical {
    background: #ef4444;
}

.progress-bar.unknown {
    background: #9ca3af;
}

.progress-text {
    font-size: 12px;
    color: #6b7280;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 15px;
}

th {
    background: #f3f4f6;
    text-align: left;
}

th, td {
    padding: 10px;
    border-bottom: 1px solid #e5e7eb;
}

.issue-card {
    margin-top: 12px;
    padding: 16px 18px;
    border-radius: 8px;
    border-left: 5px solid;
}

.issue-critical {
    background: #fef2f2;
    border-left-color: #dc2626;
}

.issue-warning {
    background: #fffbeb;
    border-left-color: #f59e0b;
}

.issue-healthy {
    background: #f0fdf4;
    border-left-color: #22c55e;
}

.issue-title {
    font-weight: 700;
    font-size: 14px;
    margin-bottom: 5px;
}

.issue-critical .issue-title {
    color: #991b1b;
}

.issue-warning .issue-title {
    color: #92400e;
}

.issue-healthy .issue-title {
    color: #166534;
}

.issue-description {
    color: #4b5563;
    font-size: 13px;
    line-height: 1.5;
}

.footer {
    text-align: center;
    margin-top: 30px;
    color: #6b7280;
    font-size: 13px;
}

</style>
</head>

<body>

<div class="container">

<div class="header">

<h1>IT Health Check Report</h1>

<p>
Computer: <strong>$($HealthCheck.ComputerName)</strong>
</p>

<p>
Generated: $($HealthCheck.GeneratedAt)
</p>

<span class="status $statusClass">
$($HealthCheck.OverallStatus)
</span>

</div>

<div class="card">

<div class="summary-grid">

    <div class="summary-card">
        <div class="summary-label">Overall Status</div>
        <div class="summary-value $statusClass">
            $($HealthCheck.OverallStatus)
        </div>
    </div>

    <div class="summary-card">
        <div class="summary-label">Issues Found</div>
        <div class="summary-value">
            $issueCount
        </div>
    </div>

    <div class="summary-card">
        <div class="summary-label">Critical Disks</div>
        <div class="summary-value $(if ($criticalDiskCount -gt 0) { 'critical' } else { 'healthy' })">
            $criticalDiskCount
        </div>
    </div>

    <div class="summary-card">
        <div class="summary-label">Network</div>
        <div class="summary-value $networkSummaryClass">
            $networkStatus
        </div>
    </div>

</div>

<h2>System Information</h2>

<p><strong>Computer Name:</strong>
$($HealthCheck.ComputerName)
</p>

<p><strong>Manufacturer:</strong>
$($HealthCheck.Inventory.Manufacturer)
</p>

<p><strong>Model:</strong>
$($HealthCheck.Inventory.Model)
</p>

<p><strong>Serial Number:</strong>
$($HealthCheck.Inventory.SerialNumber)
</p>

<p><strong>Logged-on User:</strong>
$($HealthCheck.Inventory.LoggedOnUser)
</p>

<p><strong>Domain:</strong>
$($HealthCheck.Inventory.Domain)
</p>

<p><strong>Operating System:</strong>
$($HealthCheck.Inventory.OperatingSystem)
</p>

<p><strong>Windows Build:</strong>
$($HealthCheck.Inventory.WindowsBuild)
</p>

<p><strong>CPU:</strong>
$($HealthCheck.Inventory.CPU)
</p>

<p><strong>RAM:</strong>
$($HealthCheck.Inventory.RAM_GB) GB
</p>

<p><strong>Uptime:</strong>
$($HealthCheck.Inventory.Uptime)
</p>

</div>

<div class="card">

<h2>Disk Health</h2>

<table>

<tr>
<th>Drive</th>
<th>Size</th>
<th>Free Space</th>
<th>Free %</th>
<th>Status</th>
</tr>

$($diskRows -join "`n")

</table>

</div>

<div class="card">

<h2>Service Health</h2>

<table>

<tr>
<th>Service</th>
<th>Display Name</th>
<th>Status</th>
<th>Start Type</th>
<th>Health</th>
</tr>

$($serviceRows -join "`n")

</table>

</div>

<div class="card">

<h2>Network Health</h2>

<p><strong>Adapter:</strong>
$($HealthCheck.NetworkHealth.Adapter)
</p>

<p><strong>IPv4:</strong>
$($HealthCheck.NetworkHealth.IPv4Address)
</p>

<p><strong>Gateway:</strong>
$($HealthCheck.NetworkHealth.Gateway)
</p>

<p><strong>DNS:</strong>
$($HealthCheck.NetworkHealth.DNSServers)
</p>

<p>
<strong>Gateway:</strong>
<span class="status $gatewayClass">$gatewayText</span>
</p>

<p>
<strong>Internet:</strong>
<span class="status $internetClass">$internetText</span>
</p>

<p>
<strong>DNS Resolution:</strong>
<span class="status $dnsClass">$dnsText</span>
</p>

</div>

<div class="card">

<h2>Port Connectivity</h2>

<table>

<tr>
<th>Target</th>
<th>Port</th>
<th>Protocol</th>
<th>Status</th>
<th>Response Time</th>
</tr>

$($portRows -join "`n")

</table>

</div>

<div class="card">

<h2>Detected Issues</h2>

$($issueItems -join "`n")

</div>

<div class="footer">
PowerShell IT Administration & Troubleshooting Toolkit
</div>

</div>

</body>
</html>
"@

    $html | Out-File `
        -FilePath $reportFile `
        -Encoding UTF8

    return $reportFile
}