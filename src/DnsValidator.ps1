# DnsValidator.ps1
# Validates forward and reverse DNS records against DNS server
# Author: Mark Oldham
# Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.8, 2.9, 2.10, 2.11, 2.13, 2.14, 2.15, 2.16, 2.17

class DnsValidator {
    [string] $DnsServer
    [string] $DomainSuffix
    
    DnsValidator([string] $dnsServer, [string] $domainSuffix) {
        $this.DnsServer = $dnsServer
        $this.DomainSuffix = $domainSuffix
    }
    
    # Normalize hostname by appending domain suffix to short names
    # Requirements: 2.3
    [string] NormalizeHostname([string] $hostname) {
        if ([string]::IsNullOrWhiteSpace($hostname)) {
            return $hostname
        }
        
        # Check if hostname already contains a dot (indicating FQDN)
        if ($hostname.Contains('.')) {
            return $hostname
        }
        
        # Append domain suffix to short name
        return $hostname + $this.DomainSuffix
    }
    
    # Validate forward DNS (hostname to IP address)
    # Requirements: 2.1, 2.4, 2.5, 2.6, 2.8, 2.9, 2.16
    [hashtable] ValidateForwardDns([string] $hostname, [string] $expectedIp) {
        $result = @{
            Success = "FAIL"
            ResolvedValue = ""
        }
        
        if ([string]::IsNullOrWhiteSpace($hostname) -or [string]::IsNullOrWhiteSpace($expectedIp)) {
            return $result
        }
        
        try {
            # Normalize hostname (append domain suffix if short name)
            $fqdn = $this.NormalizeHostname($hostname)
            
            # Detect the DNS zone for this hostname
            $zone = $this.DetectZone($fqdn)
            
            if ([string]::IsNullOrWhiteSpace($zone)) {
                $result.Success = "FAIL"
                return $result
            }
            
            # Query DNS server for A records
            $dnsRecords = Get-DnsServerResourceRecord -ComputerName $this.DnsServer -ZoneName $zone -Name ($fqdn -replace "\.$zone$", "") -RRType A -ErrorAction Stop
            
            if ($null -eq $dnsRecords -or $dnsRecords.Count -eq 0) {
                $result.Success = "NO"
                return $result
            }
            
            # Extract IP addresses from DNS records
            $resolvedIps = @()
            foreach ($record in $dnsRecords) {
                $ipAddress = $record.RecordData.IPv4Address.IPAddressToString
                $resolvedIps += $ipAddress
            }
            
            # Store the first resolved IP (or all if multiple)
            if ($resolvedIps.Count -eq 1) {
                $result.ResolvedValue = $resolvedIps[0]
            } else {
                $result.ResolvedValue = $resolvedIps -join ', '
            }
            
            # Check if any resolved IP matches the expected IP (case-insensitive comparison)
            $matchFound = $false
            foreach ($resolvedIp in $resolvedIps) {
                if ($resolvedIp -eq $expectedIp) {
                    $matchFound = $true
                    break
                }
            }
            
            if ($matchFound) {
                $result.Success = "YES"
            } elseif ($resolvedIps.Count -gt 1) {
                $result.Success = "MULTIPLE"
            } else {
                $result.Success = "NO"
            }
            
        }
        catch {
            # DNS query failed (zone not found or other error)
            $result.Success = "FAIL"
            $result.ResolvedValue = ""
        }
        
        return $result
    }
    
    # Validate reverse DNS (IP address to hostname)
    # Requirements: 2.2, 2.4, 2.10, 2.11, 2.13, 2.14, 2.17
    [hashtable] ValidateReverseDns([string] $ipAddress, [string] $expectedHostname) {
        $result = @{
            Success = "FAIL"
            ResolvedValue = ""
        }
        
        if ([string]::IsNullOrWhiteSpace($ipAddress) -or [string]::IsNullOrWhiteSpace($expectedHostname)) {
            return $result
        }
        
        try {
            # Normalize expected hostname (append domain suffix if short name)
            $expectedFqdn = $this.NormalizeHostname($expectedHostname)
            
            # Detect the reverse DNS zone for this IP address
            $zone = $this.DetectZone($ipAddress)
            
            if ([string]::IsNullOrWhiteSpace($zone)) {
                $result.Success = "FAIL"
                return $result
            }
            
            # Convert IP address to reverse DNS format (e.g., 10.1.2.3 -> 3.2.1.10.in-addr.arpa)
            $octets = $ipAddress.Split('.')
            [array]::Reverse($octets)
            $reverseName = $octets[0]  # Just the last octet for the record name
            
            # Query DNS server for PTR records
            $dnsRecords = Get-DnsServerResourceRecord -ComputerName $this.DnsServer -ZoneName $zone -Name $reverseName -RRType PTR -ErrorAction Stop
            
            if ($null -eq $dnsRecords -or $dnsRecords.Count -eq 0) {
                $result.Success = "NO"
                return $result
            }
            
            # Extract hostnames from DNS records
            $resolvedHostnames = @()
            foreach ($record in $dnsRecords) {
                $hostname = $record.RecordData.PtrDomainName
                # Remove trailing dot if present
                if ($hostname.EndsWith('.')) {
                    $hostname = $hostname.TrimEnd('.')
                }
                $resolvedHostnames += $hostname
            }
            
            # Store the first resolved hostname (or all if multiple)
            if ($resolvedHostnames.Count -eq 1) {
                $result.ResolvedValue = $resolvedHostnames[0]
            } else {
                $result.ResolvedValue = $resolvedHostnames -join ', '
            }
            
            # Check if any resolved hostname matches the expected hostname (case-insensitive comparison)
            $matchFound = $false
            foreach ($resolvedHostname in $resolvedHostnames) {
                if ($resolvedHostname -eq $expectedFqdn) {
                    $matchFound = $true
                    break
                }
            }
            
            if ($matchFound) {
                $result.Success = "YES"
            } elseif ($resolvedHostnames.Count -gt 1) {
                $result.Success = "MULTIPLE"
            } else {
                $result.Success = "NO"
            }
            
        }
        catch {
            # DNS query failed (zone not found or other error)
            $result.Success = "FAIL"
            $result.ResolvedValue = ""
        }
        
        return $result
    }
    
    # Test DNS connectivity by validating local hostname forward and reverse lookup
    # Requirements: 4.7, 8.3
    [bool] TestDnsConnectivity() {
        try {
            # Get local hostname
            $localHostname = hostname
            
            # Get local IP address (first non-loopback IPv4 address)
            $localIp = ""
            $netIpAddresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
                $_.IPAddress -ne '127.0.0.1' -and $_.PrefixOrigin -ne 'WellKnown' 
            }
            
            if ($netIpAddresses -and $netIpAddresses.Count -gt 0) {
                $localIp = $netIpAddresses[0].IPAddress
            } else {
                return $false
            }
            
            # Test forward DNS lookup
            $forwardResult = $this.ValidateForwardDns($localHostname, $localIp)
            if ($forwardResult.Success -eq "FAIL") {
                return $false
            }
            
            # Test reverse DNS lookup
            $reverseResult = $this.ValidateReverseDns($localIp, $localHostname)
            if ($reverseResult.Success -eq "FAIL") {
                return $false
            }
            
            return $true
        }
        catch {
            return $false
        }
    }
    
    # Detect DNS zone for a hostname or IP address
    # Requirements: 3.10
    [string] DetectZone([string] $hostnameOrIp) {
        if ([string]::IsNullOrWhiteSpace($hostnameOrIp)) {
            return ""
        }
        
        try {
            # Get all zones from DNS server
            $zones = Get-DnsServerZone -ComputerName $this.DnsServer -ErrorAction Stop
            
            # Check if input is an IP address
            if ($hostnameOrIp -match '^\d+\.\d+\.\d+\.\d+$') {
                # IP address - find reverse lookup zone
                $octets = $hostnameOrIp.Split('.')
                $reverseZones = $zones | Where-Object { $_.IsReverseLookupZone -eq $true }
                
                # Try to match /24, /16, /8 networks
                # Format: X.Y.Z.in-addr.arpa for /24
                foreach ($zone in $reverseZones) {
                    # Check for /24 match (e.g., 2.1.10.in-addr.arpa for 10.1.2.x)
                    if ($zone.ZoneName -match "^$($octets[2])\.$($octets[1])\.$($octets[0])\.in-addr\.arpa$") {
                        return $zone.ZoneName
                    }
                }
                
                # Check for /16 match (e.g., 1.10.in-addr.arpa for 10.1.x.x)
                foreach ($zone in $reverseZones) {
                    if ($zone.ZoneName -match "^$($octets[1])\.$($octets[0])\.in-addr\.arpa$") {
                        return $zone.ZoneName
                    }
                }
                
                # Check for /8 match (e.g., 10.in-addr.arpa for 10.x.x.x)
                foreach ($zone in $reverseZones) {
                    if ($zone.ZoneName -match "^$($octets[0])\.in-addr\.arpa$") {
                        return $zone.ZoneName
                    }
                }
            } else {
                # Hostname - find longest matching forward lookup zone
                $forwardZones = $zones | Where-Object { $_.IsReverseLookupZone -eq $false }
                $matchingZones = @()
                
                foreach ($zone in $forwardZones) {
                    if ($hostnameOrIp -like "*.$($zone.ZoneName)" -or $hostnameOrIp -eq $zone.ZoneName) {
                        $matchingZones += $zone
                    }
                }
                
                # Sort by zone name length (longest first) to get most specific match
                if ($matchingZones.Count -gt 0) {
                    $sortedZones = $matchingZones | Sort-Object { $_.ZoneName.Length } -Descending
                    return $sortedZones[0].ZoneName
                }
            }
            
            return ""
        }
        catch {
            return ""
        }
    }
}
