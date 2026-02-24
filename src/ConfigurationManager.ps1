# Configuration Manager for DNS-Update
# Author: Mark Oldham
# Version: 0.0.1

class ConfigurationManager {
    [string] $DnsServer
    [string] $DomainSuffix
    [string] $LogDirectory
    [int] $UpdateLimit
    [string] $DefaultSpreadsheetFilename
    [bool] $ReadOnlyMode
    [string] $ConfigFilePath

    ConfigurationManager([string] $iniFilePath) {
        $this.ConfigFilePath = $iniFilePath
        
        # Set defaults
        $this.DnsServer = "eit-priaddc00"
        $this.DomainSuffix = ".tgna.tegna.com"
        $this.LogDirectory = "./logs"
        $this.UpdateLimit = 5
        $this.DefaultSpreadsheetFilename = "DNS_Validation.xlsx"
        $this.ReadOnlyMode = $true
        
        # Load configuration if file exists, otherwise create it
        if (Test-Path $iniFilePath) {
            $this.LoadConfiguration($iniFilePath)
        } else {
            $this.CreateDefaultConfiguration($iniFilePath)
        }
    }

    [void] LoadConfiguration([string] $iniFilePath) {
        try {
            $content = Get-Content $iniFilePath -ErrorAction Stop
            $currentSection = ""
            
            foreach ($line in $content) {
                # Skip empty lines and comments
                if ([string]::IsNullOrWhiteSpace($line) -or $line.Trim().StartsWith("#")) {
                    continue
                }
                
                # Check for section headers
                if ($line -match '^\[(.+)\]$') {
                    $currentSection = $matches[1]
                    continue
                }
                
                # Parse key=value pairs
                if ($line -match '^([^=]+)=(.*)$') {
                    $key = $matches[1].Trim()
                    $value = $matches[2].Trim()
                    
                    switch ($currentSection) {
                        "DNS" {
                            if ($key -eq "Server") { $this.DnsServer = $value }
                            if ($key -eq "DomainSuffix") { $this.DomainSuffix = $value }
                        }
                        "Files" {
                            if ($key -eq "DefaultSpreadsheet") { $this.DefaultSpreadsheetFilename = $value }
                            if ($key -eq "LogDirectory") { $this.LogDirectory = $value }
                        }
                        "Limits" {
                            if ($key -eq "UpdateLimit") { $this.UpdateLimit = [int]$value }
                        }
                        "Safety" {
                            if ($key -eq "ReadOnlyMode") { 
                                $this.ReadOnlyMode = ($value -eq "true" -or $value -eq "True" -or $value -eq "TRUE")
                            }
                        }
                    }
                }
            }
        } catch {
            Write-Warning "Error loading configuration from $iniFilePath : $_"
            Write-Warning "Using default values"
        }
    }

    [void] CreateDefaultConfiguration([string] $iniFilePath) {
        $defaultConfig = @"
[DNS]
# DNS server to query and update
Server=eit-priaddc00

# Default domain suffix for short hostnames
DomainSuffix=.tgna.tegna.com

[Files]
# Default spreadsheet filename
DefaultSpreadsheet=DNS_Validation.xlsx

# Log file directory
LogDirectory=./logs

[Limits]
# Maximum number of DNS updates per run
UpdateLimit=5

[Safety]
# Set to true to prevent all DNS updates (read-only mode for testing)
# When true, program will validate and show what would be updated but skip actual DNS changes
ReadOnlyMode=true

# Commented out non-default options:
# [Advanced]
# TimeoutSeconds=30
# RetryAttempts=3
"@
        
        try {
            # Ensure directory exists
            $directory = Split-Path $iniFilePath -Parent
            if ($directory -and -not (Test-Path $directory)) {
                New-Item -ItemType Directory -Path $directory -Force | Out-Null
            }
            
            Set-Content -Path $iniFilePath -Value $defaultConfig -ErrorAction Stop
            Write-Host "Created default configuration file: $iniFilePath"
        } catch {
            Write-Error "Failed to create configuration file: $_"
        }
    }

    [string] GetDnsServer() {
        return $this.DnsServer
    }

    [string] GetDomainSuffix() {
        return $this.DomainSuffix
    }

    [string] GetLogDirectory() {
        return $this.LogDirectory
    }

    [int] GetUpdateLimit() {
        return $this.UpdateLimit
    }

    [string] GetDefaultSpreadsheetFilename() {
        return $this.DefaultSpreadsheetFilename
    }

    [bool] GetReadOnlyMode() {
        return $this.ReadOnlyMode
    }
}
