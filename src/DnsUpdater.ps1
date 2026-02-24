# DnsUpdater.ps1
# Creates and updates DNS records on the DNS server
# Author: Mark Oldham
# Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.11, 5.8, 5.9, 5.10

class DnsUpdater {
    [string] $DnsServer
    [int] $UpdateLimit
    [int] $UpdateCount
    [bool] $ReadOnlyMode
    
    DnsUpdater([string] $dnsServer, [int] $updateLimit, [bool] $readOnlyMode) {
        $this.DnsServer = $dnsServer
        $this.UpdateLimit = $updateLimit
        $this.UpdateCount = 0
        $this.ReadOnlyMode = $readOnlyMode
    }
    
    # Check if a DNS record exists
    # Requirements: 3.3, 3.5
    [bool] RecordExists([string] $recordName, [string] $zone, [string] $recordType) {
        if ([string]::IsNullOrWhiteSpace($recordName) -or [string]::IsNullOrWhiteSpace($zone)) {
            return $false
        }
        
        try {
            $records = Get-DnsServerResourceRecord -ComputerName $this.DnsServer -ZoneName $zone -Name $recordName -RRType $recordType -ErrorAction Stop
            return ($null -ne $records -and $records.Count -gt 0)
        }
        catch {
            return $false
        }
    }
    
    # Check if multiple DNS records exist for the same name
    # Requirements: 3.7
    [bool] HasMultipleRecords([string] $recordName, [string] $zone, [string] $recordType) {
        if ([string]::IsNullOrWhiteSpace($recordName) -or [string]::IsNullOrWhiteSpace($zone)) {
            return $false
        }
        
        try {
            $records = Get-DnsServerResourceRecord -ComputerName $this.DnsServer -ZoneName $zone -Name $recordName -RRType $recordType -ErrorAction Stop
            return ($null -ne $records -and $records.Count -gt 1)
        }
        catch {
            return $false
        }
    }
    
    # Update or create an A record
    # Requirements: 3.1, 3.3, 3.4, 5.8, 5.9, 5.10
    [hashtable] UpdateARecord([string] $hostname, [string] $ipAddress, [string] $zone) {
        $result = @{
            Success = $false
            Status = "Failed"
        }
        
        if ([string]::IsNullOrWhiteSpace($hostname) -or [string]::IsNullOrWhiteSpace($ipAddress) -or [string]::IsNullOrWhiteSpace($zone)) {
            return $result
        }
        
        # Check if we're in read-only mode
        if ($this.ReadOnlyMode) {
            $result.Success = $true
            $result.Status = "ReadOnly"
            return $result
        }
        
        try {
            # Extract the record name (remove zone suffix from hostname)
            $recordName = $hostname -replace "\.$zone$", ""
            
            # Check if multiple records exist
            if ($this.HasMultipleRecords($recordName, $zone, "A")) {
                $result.Status = "MULTIPLE"
                return $result
            }
            
            # Check if record exists
            if ($this.RecordExists($recordName, $zone, "A")) {
                # Update existing record
                $oldRecord = Get-DnsServerResourceRecord -ComputerName $this.DnsServer -ZoneName $zone -Name $recordName -RRType A -ErrorAction Stop
                $newRecord = $oldRecord.Clone()
                $newRecord.RecordData.IPv4Address = [System.Net.IPAddress]::Parse($ipAddress)
                
                Set-DnsServerResourceRecord -ComputerName $this.DnsServer -ZoneName $zone -OldInputObject $oldRecord -NewInputObject $newRecord -ErrorAction Stop
                
                $result.Success = $true
                $result.Status = "Updated"
            }
            else {
                # Create new record
                Add-DnsServerResourceRecordA -ComputerName $this.DnsServer -ZoneName $zone -Name $recordName -IPv4Address $ipAddress -ErrorAction Stop
                
                $result.Success = $true
                $result.Status = "Updated"
            }
        }
        catch {
            $result.Success = $false
            $result.Status = "Failed"
        }
        
        return $result
    }
    
    # Update or create a PTR record
    # Requirements: 3.2, 3.5, 3.6, 5.8, 5.9, 5.10
    [hashtable] UpdatePtrRecord([string] $ipAddress, [string] $hostname, [string] $zone) {
        $result = @{
            Success = $false
            Status = "Failed"
        }
        
        if ([string]::IsNullOrWhiteSpace($ipAddress) -or [string]::IsNullOrWhiteSpace($hostname) -or [string]::IsNullOrWhiteSpace($zone)) {
            return $result
        }
        
        # Check if we're in read-only mode
        if ($this.ReadOnlyMode) {
            $result.Success = $true
            $result.Status = "ReadOnly"
            return $result
        }
        
        try {
            # Convert IP address to reverse DNS format
            $octets = $ipAddress.Split('.')
            [array]::Reverse($octets)
            $recordName = $octets[0]  # Just the last octet for the record name
            
            # Ensure hostname ends with a dot for PTR records
            $ptrHostname = $hostname
            if (-not $ptrHostname.EndsWith('.')) {
                $ptrHostname = $ptrHostname + '.'
            }
            
            # Check if multiple records exist
            if ($this.HasMultipleRecords($recordName, $zone, "PTR")) {
                $result.Status = "MULTIPLE"
                return $result
            }
            
            # Check if record exists
            if ($this.RecordExists($recordName, $zone, "PTR")) {
                # Update existing record
                $oldRecord = Get-DnsServerResourceRecord -ComputerName $this.DnsServer -ZoneName $zone -Name $recordName -RRType PTR -ErrorAction Stop
                $newRecord = $oldRecord.Clone()
                $newRecord.RecordData.PtrDomainName = $ptrHostname
                
                Set-DnsServerResourceRecord -ComputerName $this.DnsServer -ZoneName $zone -OldInputObject $oldRecord -NewInputObject $newRecord -ErrorAction Stop
                
                $result.Success = $true
                $result.Status = "Updated"
            }
            else {
                # Create new record
                Add-DnsServerResourceRecordPtr -ComputerName $this.DnsServer -ZoneName $zone -Name $recordName -PtrDomainName $ptrHostname -ErrorAction Stop
                
                $result.Success = $true
                $result.Status = "Updated"
            }
        }
        catch {
            $result.Success = $false
            $result.Status = "Failed"
        }
        
        return $result
    }
    
    # Check if we can perform more updates (within limit)
    # Requirements: 3.8
    [bool] CanUpdate() {
        return $this.UpdateCount -lt $this.UpdateLimit
    }
    
    # Increment the update counter
    # Requirements: 3.8
    [void] IncrementUpdateCount() {
        $this.UpdateCount++
    }
}
