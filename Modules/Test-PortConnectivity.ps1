function Test-PortConnectivity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 65535)]
        [int[]]$Port
    )

    foreach ($currentPort in $Port) {

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient

            $connection = $tcpClient.BeginConnect(
                $ComputerName,
                $currentPort,
                $null,
                $null
            )

            $success = $connection.AsyncWaitHandle.WaitOne(2000, $false)

            if ($success -and $tcpClient.Connected) {
                $tcpClient.EndConnect($connection)
                $status = "Open"
                $reachable = $true
            }
            else {
                $status = "Closed/Filtered"
                $reachable = $false
            }
        }
        catch {
            $status = "Error"
            $reachable = $false
        }
        finally {
            $stopwatch.Stop()

            if ($tcpClient) {
                $tcpClient.Close()
                $tcpClient.Dispose()
            }
        }

        [PSCustomObject]@{
            ComputerName   = $ComputerName
            Port           = $currentPort
            Protocol       = "TCP"
            Reachable      = $reachable
            Status         = $status
            ResponseTimeMs = $stopwatch.ElapsedMilliseconds
        }
    }
}