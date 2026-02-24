# Unit Tests for Configuration Manager
# Author: Mark Oldham

# Import the Configuration Manager
. "$PSScriptRoot/../src/ConfigurationManager.ps1"

function Test-ConfigurationManagerDefaults {
    Write-Host "`n=== Test: Configuration Manager Defaults ===" -ForegroundColor Cyan
    
    $testIniPath = "$PSScriptRoot/test-config.ini"
    
    # Clean up any existing test file
    if (Test-Path $testIniPath) {
        Remove-Item $testIniPath -Force
    }
    
    try {
        # Create configuration manager (should create default INI)
        $config = [ConfigurationManager]::new($testIniPath)
        
        # Verify file was created
        if (-not (Test-Path $testIniPath)) {
            Write-Host "[FAIL] Configuration file was not created" -ForegroundColor Red
            return $false
        }
        Write-Host "[OK] Configuration file created" -ForegroundColor Green
        
        # Verify default values
        $tests = @(
            @{ Name = "DnsServer"; Expected = "eit-priaddc00"; Actual = $config.GetDnsServer() }
            @{ Name = "DomainSuffix"; Expected = ".tgna.tegna.com"; Actual = $config.GetDomainSuffix() }
            @{ Name = "LogDirectory"; Expected = "./logs"; Actual = $config.GetLogDirectory() }
            @{ Name = "UpdateLimit"; Expected = 5; Actual = $config.GetUpdateLimit() }
            @{ Name = "DefaultSpreadsheetFilename"; Expected = "DNS_Validation.xlsx"; Actual = $config.GetDefaultSpreadsheetFilename() }
            @{ Name = "ReadOnlyMode"; Expected = $true; Actual = $config.GetReadOnlyMode() }
        )
        
        $allPassed = $true
        foreach ($test in $tests) {
            if ($test.Expected -eq $test.Actual) {
                Write-Host "[OK] $($test.Name) = $($test.Actual)" -ForegroundColor Green
            } else {
                Write-Host "[FAIL] $($test.Name): Expected '$($test.Expected)', Got '$($test.Actual)'" -ForegroundColor Red
                $allPassed = $false
            }
        }
        
        # Verify ReadOnlyMode defaults to true
        $content = Get-Content $testIniPath -Raw
        if ($content -match "ReadOnlyMode=true") {
            Write-Host "[OK] ReadOnlyMode defaults to true in INI file" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] ReadOnlyMode does not default to true in INI file" -ForegroundColor Red
            $allPassed = $false
        }
        
        return $allPassed
    } finally {
        # Clean up
        if (Test-Path $testIniPath) {
            Remove-Item $testIniPath -Force
        }
    }
}

function Test-ConfigurationManagerCustomValues {
    Write-Host "`n=== Test: Configuration Manager Custom Values ===" -ForegroundColor Cyan
    
    $testIniPath = "$PSScriptRoot/test-config-custom.ini"
    
    # Create custom INI file
    $customConfig = @"
[DNS]
Server=custom-dns-server
DomainSuffix=.custom.domain

[Files]
DefaultSpreadsheet=Custom.xlsx
LogDirectory=./custom-logs

[Limits]
UpdateLimit=10

[Safety]
ReadOnlyMode=false
"@
    
    try {
        Set-Content -Path $testIniPath -Value $customConfig
        
        # Load configuration
        $config = [ConfigurationManager]::new($testIniPath)
        
        # Verify custom values
        $tests = @(
            @{ Name = "DnsServer"; Expected = "custom-dns-server"; Actual = $config.GetDnsServer() }
            @{ Name = "DomainSuffix"; Expected = ".custom.domain"; Actual = $config.GetDomainSuffix() }
            @{ Name = "LogDirectory"; Expected = "./custom-logs"; Actual = $config.GetLogDirectory() }
            @{ Name = "UpdateLimit"; Expected = 10; Actual = $config.GetUpdateLimit() }
            @{ Name = "DefaultSpreadsheetFilename"; Expected = "Custom.xlsx"; Actual = $config.GetDefaultSpreadsheetFilename() }
            @{ Name = "ReadOnlyMode"; Expected = $false; Actual = $config.GetReadOnlyMode() }
        )
        
        $allPassed = $true
        foreach ($test in $tests) {
            if ($test.Expected -eq $test.Actual) {
                Write-Host "[OK] $($test.Name) = $($test.Actual)" -ForegroundColor Green
            } else {
                Write-Host "[FAIL] $($test.Name): Expected '$($test.Expected)', Got '$($test.Actual)'" -ForegroundColor Red
                $allPassed = $false
            }
        }
        
        return $allPassed
    } finally {
        # Clean up
        if (Test-Path $testIniPath) {
            Remove-Item $testIniPath -Force
        }
    }
}

function Test-ConfigurationManagerMissingKeys {
    Write-Host "`n=== Test: Configuration Manager Missing Keys ===" -ForegroundColor Cyan
    
    $testIniPath = "$PSScriptRoot/test-config-partial.ini"
    
    # Create partial INI file (missing some keys)
    $partialConfig = @"
[DNS]
Server=partial-server

[Limits]
UpdateLimit=3
"@
    
    try {
        Set-Content -Path $testIniPath -Value $partialConfig
        
        # Load configuration
        $config = [ConfigurationManager]::new($testIniPath)
        
        # Verify that missing keys use defaults
        $tests = @(
            @{ Name = "DnsServer (custom)"; Expected = "partial-server"; Actual = $config.GetDnsServer() }
            @{ Name = "DomainSuffix (default)"; Expected = ".tgna.tegna.com"; Actual = $config.GetDomainSuffix() }
            @{ Name = "UpdateLimit (custom)"; Expected = 3; Actual = $config.GetUpdateLimit() }
            @{ Name = "ReadOnlyMode (default)"; Expected = $true; Actual = $config.GetReadOnlyMode() }
        )
        
        $allPassed = $true
        foreach ($test in $tests) {
            if ($test.Expected -eq $test.Actual) {
                Write-Host "[OK] $($test.Name) = $($test.Actual)" -ForegroundColor Green
            } else {
                Write-Host "[FAIL] $($test.Name): Expected '$($test.Expected)', Got '$($test.Actual)'" -ForegroundColor Red
                $allPassed = $false
            }
        }
        
        return $allPassed
    } finally {
        # Clean up
        if (Test-Path $testIniPath) {
            Remove-Item $testIniPath -Force
        }
    }
}

# Run all tests
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "Configuration Manager Unit Tests" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow

$results = @()
$results += Test-ConfigurationManagerDefaults
$results += Test-ConfigurationManagerCustomValues
$results += Test-ConfigurationManagerMissingKeys

Write-Host "`n==================================================" -ForegroundColor Yellow
Write-Host "Test Summary" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow

$passed = ($results | Where-Object { $_ -eq $true }).Count
$failed = ($results | Where-Object { $_ -eq $false }).Count

Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

if ($failed -eq 0) {
    Write-Host "`nAll tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome tests failed!" -ForegroundColor Red
    exit 1
}
