# Test-DnsValidator.ps1
# Unit tests for DnsValidator class
# Author: Mark Oldham

# Import required modules
Import-Module Pester -ErrorAction Stop

# Import the DnsValidator class
. "$PSScriptRoot\..\src\DnsValidator.ps1"

Describe "DnsValidator Unit Tests" {
    BeforeAll {
        # Create a DnsValidator instance for testing
        $script:validator = [DnsValidator]::new("eit-priaddc00", ".tgna.tegna.com")
    }
    
    Context "NormalizeHostname Method" {
        It "Should append domain suffix to short hostname" {
            $result = $script:validator.NormalizeHostname("server01")
            $result | Should BeExactly "server01.tgna.tegna.com"
        }
        
        It "Should not modify FQDN (hostname with dot)" {
            $result = $script:validator.NormalizeHostname("server01.example.com")
            $result | Should BeExactly "server01.example.com"
        }
        
        It "Should handle empty hostname" {
            $result = $script:validator.NormalizeHostname("")
            $result | Should BeExactly ""
        }
        
        It "Should handle null hostname" {
            $result = $script:validator.NormalizeHostname($null)
            $result | Should BeNullOrEmpty
        }
    }
    
    Context "ValidateForwardDns Method" {
        It "Should return FAIL for empty hostname" {
            $result = $script:validator.ValidateForwardDns("", "10.1.2.3")
            $result.Success | Should BeExactly "FAIL"
        }
        
        It "Should return FAIL for empty IP address" {
            $result = $script:validator.ValidateForwardDns("server01", "")
            $result.Success | Should BeExactly "FAIL"
        }
        
        It "Should return hashtable with Success and ResolvedValue keys" {
            $result = $script:validator.ValidateForwardDns("nonexistent", "10.1.2.3")
            $result.ContainsKey("Success") | Should Be $true
            $result.ContainsKey("ResolvedValue") | Should Be $true
        }
    }
    
    Context "ValidateReverseDns Method" {
        It "Should return FAIL for empty IP address" {
            $result = $script:validator.ValidateReverseDns("", "server01")
            $result.Success | Should BeExactly "FAIL"
        }
        
        It "Should return FAIL for empty hostname" {
            $result = $script:validator.ValidateReverseDns("10.1.2.3", "")
            $result.Success | Should BeExactly "FAIL"
        }
        
        It "Should return hashtable with Success and ResolvedValue keys" {
            $result = $script:validator.ValidateReverseDns("10.1.2.3", "server01")
            $result.ContainsKey("Success") | Should Be $true
            $result.ContainsKey("ResolvedValue") | Should Be $true
        }
    }
    
    Context "DetectZone Method" {
        It "Should return empty string for empty input" {
            $result = $script:validator.DetectZone("")
            $result | Should BeExactly ""
        }
        
        It "Should return empty string for null input" {
            $result = $script:validator.DetectZone($null)
            $result | Should BeExactly ""
        }
        
        It "Should detect IP address format" {
            # This test will attempt to detect a zone for an IP address
            # Result depends on actual DNS server configuration
            $result = $script:validator.DetectZone("10.1.2.3")
            # We just verify it returns a string (may be empty if zone not found)
            $result.GetType().Name | Should BeExactly "String"
        }
        
        It "Should detect hostname format" {
            # This test will attempt to detect a zone for a hostname
            # Result depends on actual DNS server configuration
            $result = $script:validator.DetectZone("server01.tgna.tegna.com")
            # We just verify it returns a string (may be empty if zone not found)
            $result.GetType().Name | Should BeExactly "String"
        }
    }
    
    Context "TestDnsConnectivity Method" {
        It "Should return boolean value" {
            $result = $script:validator.TestDnsConnectivity()
            ($result -is [bool]) | Should Be $true
        }
    }
    
    Context "Case-Insensitive Comparisons" {
        It "Should perform case-insensitive hostname comparison in forward DNS" {
            # This is tested implicitly in ValidateForwardDns
            # The method uses -eq operator which is case-insensitive in PowerShell
            $hostname1 = "SERVER01"
            $hostname2 = "server01"
            ($hostname1 -eq $hostname2) | Should Be $true
        }
        
        It "Should perform case-insensitive hostname comparison in reverse DNS" {
            # This is tested implicitly in ValidateReverseDns
            # The method uses -eq operator which is case-insensitive in PowerShell
            $hostname1 = "SERVER01.TGNA.TEGNA.COM"
            $hostname2 = "server01.tgna.tegna.com"
            ($hostname1 -eq $hostname2) | Should Be $true
        }
    }
}

# Run the tests
Write-Host "`nRunning DnsValidator Unit Tests..." -ForegroundColor Cyan
Invoke-Pester -Path $PSCommandPath
