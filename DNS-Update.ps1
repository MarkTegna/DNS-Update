# DNS-Update.ps1
# Main entry point for DNS-Update program
# Author: Mark Oldham
# Version: 0.1.2
# Requirements: 1.1, 1.2, 7.6, 7.7

<#
.SYNOPSIS
    DNS-Update - Validates and updates DNS entries from an Excel spreadsheet

.DESCRIPTION
    DNS-Update is a PowerShell-based tool that validates and updates DNS entries by reading 
    an Excel spreadsheet, checking forward and reverse DNS records against Microsoft DNS servers, 
    and updating DNS when requested. The program runs iteratively on the same spreadsheet until 
    all entries are validated as correct.

.PARAMETER SpreadsheetPath
    Path to the Excel spreadsheet containing DNS entries. 
    Default: DNS_Validation.xlsx

.PARAMETER MaxRows
    Maximum number of rows to process per run, overriding the default of 50.

.PARAMETER Help
    Display this help information

.EXAMPLE
    .\DNS-Update.ps1
    Process the default spreadsheet (DNS_Validation.xlsx)

.EXAMPLE
    .\DNS-Update.ps1 -SpreadsheetPath "MyDNS.xlsx"
    Process a custom spreadsheet

.EXAMPLE
    .\DNS-Update.ps1 -MaxRows 100
    Process up to 100 rows instead of the default 50

.EXAMPLE
    .\DNS-Update.ps1 -Help
    Display help information

.NOTES
    Author: Mark Oldham
    Version: 0.1.2
    Compile Date: 2026-03-18
    
    Requirements:
    - PowerShell 5.1 or later
    - DnsServer module (Install-Module -Name DnsServer)
    - ImportExcel module (Install-Module -Name ImportExcel)
    - Windows Server with DNS role
    - Domain member with DNS update rights
    
    Configuration:
    - Configuration file: config/DNS-Update.ini
    - Log directory: ./logs
    - Default spreadsheet: DNS_Validation.xlsx
    - Read-only mode: true (default for safety)
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$SpreadsheetPath,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxRows = 0,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

# Display help if requested
if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

# Import required source files
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath/src/ConfigurationManager.ps1"
. "$scriptPath/src/Logger.ps1"
. "$scriptPath/src/SpreadsheetManager.ps1"
. "$scriptPath/src/DnsValidator.ps1"
. "$scriptPath/src/DnsUpdater.ps1"
. "$scriptPath/src/BackupManager.ps1"
. "$scriptPath/src/ProgressDisplay.ps1"
. "$scriptPath/src/MainOrchestrator.ps1"

# Display program header
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DNS-Update v0.1.2" -ForegroundColor Cyan
Write-Host "Author: Mark Oldham" -ForegroundColor Cyan
Write-Host "Compile Date: 2026-03-18" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Build arguments array
$arguments = @()
if ($SpreadsheetPath) {
    $arguments += "-SpreadsheetPath"
    $arguments += $SpreadsheetPath
}
if ($MaxRows -gt 0) {
    $arguments += "-MaxRows"
    $arguments += $MaxRows.ToString()
}

# Create and run the main orchestrator
try {
    $orchestrator = [MainOrchestrator]::new()
    $orchestrator.Run($arguments)}
catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "ERROR: Program terminated with error" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack Trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    exit 1
}

exit 0
