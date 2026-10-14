# PowerShell IT Administration & Troubleshooting Toolkit

A practical PowerShell toolkit for Windows system administration, health monitoring, troubleshooting, and automated reporting.

The toolkit collects system information, checks disk and Windows service health, performs network diagnostics, tests TCP port connectivity, and automatically generates professional HTML, JSON, and CSV reports.

It is designed as a lightweight troubleshooting and system assessment tool for IT support technicians and system administrators.

---

## Features

### System Inventory

Collects useful Windows workstation information including:

- Computer name
- Manufacturer and model
- Serial number
- Logged-on user
- Domain
- Operating system
- Windows build
- CPU
- Installed RAM
- System uptime
- Disk information
- Network adapter information

### Disk Health

Analyzes local disks and reports:

- Total disk size
- Available free space
- Free space percentage
- Health status
- Configurable warning and critical thresholds

Possible states:

- Healthy
- Warning
- Critical

### Windows Service Health

Checks important Windows services and reports:

- Service name
- Display name
- Current status
- Startup type
- Health status

The default checks include services such as:

- Windows Update
- Microsoft Defender Antivirus
- DNS Client
- DHCP Client
- Windows Event Log

### Network Diagnostics

Performs basic network health checks including:

- Active network adapter
- IPv4 address
- Default gateway
- DNS server
- Gateway connectivity
- Internet connectivity
- DNS resolution

### TCP Port Connectivity

Tests TCP connectivity to a configurable target and list of ports.

Default test:

```text
Target: google.com
Ports: 80, 443
Protocol: TCP
```

The report includes port status and response time.

### Automated Reporting

Every health check can generate three report formats:

- **HTML** — visual health-check dashboard
- **JSON** — complete machine-readable health-check dataset
- **CSV** — simplified summary suitable for Excel and further reporting

The HTML report is automatically opened in the default browser after the health check completes.

---

## Demo Mode

The toolkit includes a sanitized demo mode intended for portfolio demonstrations and sample reports.

Demo mode replaces identifying system and network information with sample values while preserving the health-check workflow and results.

Example:

```text
Computer: WS-FINANCE-023
Domain: CONTOSO
User: CONTOSO\j.smith
IPv4: 192.168.10.25
Gateway: 192.168.10.1
DNS: 192.168.10.10
```

Run the toolkit in demo mode:

```powershell
.\Invoke-ITHealthCheck.ps1 -Demo
```

---

## Usage

### Standard Health Check

Run:

```powershell
.\Invoke-ITHealthCheck.ps1
```

The toolkit will:

1. Collect system inventory
2. Analyze disk health
3. Check Windows services
4. Test network health
5. Test TCP connectivity
6. Determine the overall system status
7. Generate HTML, JSON, and CSV reports
8. Open the HTML report in the default browser

### Demo / Portfolio Mode

```powershell
.\Invoke-ITHealthCheck.ps1 -Demo
```

This performs the same health check but sanitizes identifying information before reports are generated.

### Custom Port Test

A different target and ports can be supplied:

```powershell
.\Invoke-ITHealthCheck.ps1 -PortTestTarget "server01.contoso.local" -Ports 80,443,3389
```

### Custom Report Location

```powershell
.\Invoke-ITHealthCheck.ps1 -ReportPath "C:\ITReports"
```

---

## Project Structure

```text
PowerShell-IT-Toolkit
|
|-- Modules
|   |-- Get-SystemInventory.ps1
|   |-- Get-DiskHealth.ps1
|   |-- Get-ServiceHealth.ps1
|   |-- Test-NetworkHealth.ps1
|   |-- Test-PortConnectivity.ps1
|   |-- New-HealthCheckReport.ps1
|   `-- Export-HealthCheckData.ps1
|
|-- Reports
|   |-- IT-Health-Check_<Computer>_<Timestamp>.html
|   |-- IT-Health-Check_<Computer>_<Timestamp>.json
|   `-- IT-Health-Check_<Computer>_<Timestamp>.csv
|
|-- Sample
|
|-- Invoke-ITHealthCheck.ps1
`-- README.md
```

---

## Example Health Check

Example console output:

```text
=============================================
   PowerShell IT Health Check
=============================================

[1/5] Collecting system inventory...
[2/5] Checking disk health...
[3/5] Checking Windows services...
[4/5] Testing network health...
[5/5] Testing TCP connectivity...

=============================================
   Health Check Complete
=============================================

Computer:       WS-FINANCE-023
Overall Status: Critical
Issues Found:   2

Detected issues:
 - Disk C: is Critical
 - Service wuauserv: Attention

Generating HTML report...
Exporting JSON and CSV data...
```

---

## HTML Dashboard

The generated HTML dashboard provides a visual overview of:

- Overall system status
- Number of detected issues
- Critical disk status
- Network health
- System information
- Disk utilization
- Windows service health
- Network diagnostics
- TCP port connectivity
- Detailed detected issues

Status indicators make it easy to identify healthy, warning, and critical conditions.

---

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 or PowerShell 7+
- Standard Windows management interfaces
- Network connectivity for Internet and external TCP tests

No third-party PowerShell modules are required.

---

## Output

Reports are stored in the `Reports` directory by default.

Example:

```text
Reports\
    IT-Health-Check_WS-FINANCE-023_2026-09-22_21-30-00.html
    IT-Health-Check_WS-FINANCE-023_2026-09-22_21-30-00.json
    IT-Health-Check_WS-FINANCE-023_2026-09-22_21-30-00.csv
```

The JSON output contains the complete health-check dataset and can be used for additional automation or integration.

The CSV output provides a simplified system summary suitable for Excel, inventory tracking, or reporting.

---

## Use Cases

This toolkit can be used for:

- Windows workstation health checks
- IT help desk troubleshooting
- System administration
- Disk space monitoring
- Windows service diagnostics
- Network troubleshooting
- TCP connectivity testing
- Basic workstation auditing
- Automated IT reporting

---

## Security and Privacy

The toolkit performs read-only system health and diagnostic checks.

Demo mode is provided to sanitize identifying workstation and network information before generating portfolio or demonstration reports.

Always review generated reports before sharing system information outside your organization.

---

## Author

Developed as a PowerShell automation and Windows system administration portfolio project.

Focus areas:

**Windows Administration | IT Support | PowerShell Automation | Troubleshooting | Networking**