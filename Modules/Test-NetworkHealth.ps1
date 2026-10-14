function Test-NetworkHealth {
    [CmdletBinding()]
    param (
        [string]$InternetTarget = "1.1.1.1",
        [string]$DnsTestHost = "www.microsoft.com"
    )

    try {
        # Get active network configuration
        $config = Get-NetIPConfiguration |
            Where-Object {
                $_.IPv4Address -and
                $_.NetAdapter.Status -eq "Up" -and
                $_.IPv4DefaultGateway
            } |
            Select-Object -First 1

        if (-not $config) {
            throw "No active network adapter with an IPv4 default gateway was found."
        }

        $adapterName = $config.InterfaceAlias
        $ipv4Address = $config.IPv4Address.IPAddress
        $gateway = $config.IPv4DefaultGateway.NextHop
        $dnsServers = $config.DNSServer.ServerAddresses |
            Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' }

        # Gateway connectivity
        $gatewayReachable = Test-Connection `
            -ComputerName $gateway `
            -Count 1 `
            -Quiet `
            -ErrorAction SilentlyContinue

        # Internet connectivity without relying on DNS
        $internetReachable = Test-Connection `
            -ComputerName $InternetTarget `
            -Count 1 `
            -Quiet `
            -ErrorAction SilentlyContinue

        # DNS resolution
        $dnsWorking = $false

        try {
            $null = Resolve-DnsName `
                -Name $DnsTestHost `
                -ErrorAction Stop

            $dnsWorking = $true
        }
        catch {
            $dnsWorking = $false
        }

        # Overall status
        $status = if (
            $gatewayReachable -and
            $internetReachable -and
            $dnsWorking
        ) {
            "Healthy"
        }
        elseif ($gatewayReachable) {
            "Warning"
        }
        else {
            "Critical"
        }

        [PSCustomObject]@{
            Adapter           = $adapterName
            IPv4Address       = $ipv4Address
            Gateway           = $gateway
            DNSServers        = ($dnsServers -join ", ")
            GatewayReachable  = $gatewayReachable
            InternetReachable = $internetReachable
            DNSWorking        = $dnsWorking
            Status            = $status
        }
    }
    catch {
        Write-Error "Network health check failed: $($_.Exception.Message)"
    }
}