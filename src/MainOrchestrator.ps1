# MainOrchestrator.ps1
# Main orchestrator for DNS-Update program
# Author: Mark Oldham
# Version: 0.0.1

# Import required modules
. "$PSScriptRoot\ConfigurationManager.ps1"
. "$PSScriptRoot\SpreadsheetManager.ps1"
. "$PSScriptRoot\DnsValidator.ps1"
. "$PSScriptRoot\DnsUpdater.ps1"
. "$PSScriptRoot\BackupManager.ps1"
. "$PSScriptRoot\Logger.ps1"
. "$PSScriptRoot\ProgressDisplay.ps1"

class MainOrchestrator {
    [ConfigurationManager] $Config
    [SpreadsheetManager] $Spreadsheet
    [DnsValidator] $Validator
    [DnsUpdater] $Updater
    [BackupManager] $Backup
    [Logger] $Log
    [ProgressDisplay] $Progress
    [string] $SpreadsheetPath
    [array] $FixCommands
    
    MainOrchestrator() {
        $this.FixCommands = @()
    }
    
    # Initialize the orchestrator with command line arguments
    # Requirements: 4.7, 4.8, 4.9, 4.10
    [void] Initialize([string[]] $args) {
        # Parse command line arguments for spreadsheet filename
        $spreadsheetFilename = $null
        
        for ($i = 0; $i -lt $args.Count; $i++) {
            if ($args[$i] -eq "-SpreadsheetPath" -and ($i + 1) -lt $args.Count) {
                $spreadsheetFilename = $args[$i + 1]
                $i++
            }
        }
        
        # Load configuration
        $configPath = "config/DNS-Update.ini"
        $this.Config = [ConfigurationManager]::new($configPath)
        
        # Initialize logger
        $this.Log = [Logger]::new()
        $this.Log.Initialize($this.Config.GetLogDirectory())
        $this.Log.LogInfo("DNS-Update program started, version 0.0.1")
        $this.Log.LogInfo("Configuration loaded from $configPath")
        
        # Determine spreadsheet path
        if ($null -ne $spreadsheetFilename) {
            $this.SpreadsheetPath = $spreadsheetFilename
            $this.Log.LogInfo("Using spreadsheet from command line: $spreadsheetFilename")
        } else {
            $this.SpreadsheetPath = $this.Config.GetDefaultSpreadsheetFilename()
            $this.Log.LogInfo("Using default spreadsheet: $($this.SpreadsheetPath)")
        }
        
        # Initialize components
        $this.Spreadsheet = [SpreadsheetManager]::new()
        $this.Validator = [DnsValidator]::new($this.Config.GetDnsServer(), $this.Config.GetDomainSuffix())
        $this.Updater = [DnsUpdater]::new($this.Config.GetDnsServer(), $this.Config.GetUpdateLimit(), $this.Config.GetReadOnlyMode())
        $this.Backup = [BackupManager]::new($this.Config.GetLogDirectory())
        $this.Progress = [ProgressDisplay]::new()
        
        $this.Log.LogInfo("All components initialized successfully")
    }
    
    # Validate prerequisites (PowerShell modules and DNS connectivity)
    # Requirements: 4.7, 4.8, 4.9, 4.10
    [void] ValidatePrerequisites() {
        $this.Log.LogInfo("Validating prerequisites...")
        
        # Check for DnsServer module
        $dnsServerModule = Get-Module -ListAvailable -Name DnsServer
        if ($null -eq $dnsServerModule) {
            $errorMsg = "DnsServer PowerShell module is not available. Please install it using: Install-Module -Name DnsServer"
            $this.Log.LogError($errorMsg)
            throw $errorMsg
        }
        $this.Log.LogInfo("DnsServer module is available")
        
        # Check for ImportExcel module
        $importExcelModule = Get-Module -ListAvailable -Name ImportExcel
        if ($null -eq $importExcelModule) {
            $errorMsg = "ImportExcel PowerShell module is not available. Please install it using: Install-Module -Name ImportExcel"
            $this.Log.LogError($errorMsg)
            throw $errorMsg
        }
        $this.Log.LogInfo("ImportExcel module is available")
        
        # Test DNS connectivity
        $this.Log.LogInfo("Testing DNS connectivity to $($this.Config.GetDnsServer())...")
        $dnsConnectivity = $this.Validator.TestDnsConnectivity()
        
        if (-not $dnsConnectivity) {
            $errorMsg = "DNS connectivity validation failed. Cannot connect to DNS server: $($this.Config.GetDnsServer())"
            $this.Log.LogError($errorMsg)
            throw $errorMsg
        }
        
        $this.Log.LogInfo("DNS connectivity validated successfully")
    }
    
    # Process the spreadsheet: load, validate columns, add status column, and validate all rows
    # Requirements: 1.1, 1.2, 1.3, 1.4, 1.6, 1.8, 1.10
    [void] ProcessSpreadsheet() {
        $this.Log.LogInfo("Processing spreadsheet: $($this.SpreadsheetPath)")
        
        # Check if spreadsheet exists, create sample if not
        if (-not $this.Spreadsheet.FileExists($this.SpreadsheetPath)) {
            $this.Log.LogInfo("Spreadsheet file does not exist, creating sample spreadsheet")
            Write-Host "Spreadsheet file not found. Creating sample spreadsheet: $($this.SpreadsheetPath)" -ForegroundColor Yellow
            
            $this.Spreadsheet.CreateSampleSpreadsheet($this.SpreadsheetPath)
            $this.Log.LogInfo("Sample spreadsheet created successfully")
            Write-Host "Sample spreadsheet created with local host information." -ForegroundColor Green
        }
        
        # Load spreadsheet
        try {
            $this.Spreadsheet.LoadSpreadsheet($this.SpreadsheetPath)
            $this.Log.LogInfo("Spreadsheet loaded successfully")
        }
        catch {
            $errorMsg = "Failed to load spreadsheet: $_"
            $this.Log.LogError($errorMsg)
            throw $errorMsg
        }
        
        # Validate required columns exist (MapColumns already validates this)
        # MapColumns is called automatically by LoadSpreadsheet
        $this.Log.LogInfo("Required columns validated successfully")
        
        # Add Status column if missing
        $this.Spreadsheet.AddStatusColumn()
        $this.Log.LogInfo("Status column added/verified")
        
        # Get all rows
        $rows = $this.Spreadsheet.GetRows()
        $totalRows = $rows.Count
        $this.Log.LogInfo("Processing $totalRows rows")
        
        # Initialize progress display
        $this.Progress.Initialize($totalRows)
        
        # Loop through all rows and validate each
        for ($i = 0; $i -lt $totalRows; $i++) {
            # Update progress display
            $this.Progress.UpdateProgress($i + 1)
            
            # Validate the row
            $this.ValidateRow($i)
        }
        
        # Complete progress display
        if ($totalRows -gt 10) {
            Write-Progress -Activity "Processing DNS Records" -Completed
        }
        
        $this.Log.LogInfo("Spreadsheet processing complete")
    }
    
    # Validate a single row (stub for task 10.3)
    # Requirements: 1.9, 2.15, 2.16, 2.17
    [void] ValidateRow([int] $rowIndex) {
        # TODO: Implement in task 10.3
        # This method will:
        # - Check for empty Hostname or IP Address, skip if empty and mark "Skipped"
        # - Check if validation cells are empty or contain "FIX"
        # - Call DnsValidator methods for forward and reverse DNS
        # - Write validation results to spreadsheet cells
        # - Collect FIX commands for later execution
        
        $this.Log.LogInfo("ValidateRow stub called for row $rowIndex")
    }
    
    # Collect FIX commands from validated rows (stub for task 10.5)
    # Requirements: 3.1, 3.2, 3.7, 3.10, 3.11
    [array] CollectFixCommands() {
        # TODO: Implement in task 10.5
        # This method will:
        # - Scan all rows for "FIX" in validation cells (case insensitive)
        # - Create FixCommand objects with row number, record type, hostname, IP, zone
        # - Detect zone for each FIX command
        # - Check for multiple records, mark as "MULTIPLE" if found
        # - Return array of FixCommand objects
        
        $this.Log.LogInfo("CollectFixCommands stub called")
        return @()
    }
    
    # Execute FIX commands (stub for task 10.6)
    # Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 3.8, 3.9
    [void] ExecuteFixCommands([array] $fixCommands) {
        # TODO: Implement in task 10.6
        # This method will:
        # - Create backups before any updates
        # - Display confirmation prompt with all FIX commands
        # - If user responds "N", skip updates and return
        # - If user responds "Y", proceed with updates
        # - Loop through FIX commands up to update limit
        # - Call DnsUpdater methods for each FIX command
        # - Write update results to Status column
        # - Log all update operations
        
        $this.Log.LogInfo("ExecuteFixCommands stub called with $($fixCommands.Count) commands")
    }
    
    # Run the complete workflow (stub for task 10.7)
    # Requirements: All
    [void] Run([string[]] $args) {
        # TODO: Implement in task 10.7
        # This method will:
        # - Call Initialize
        # - Call ValidatePrerequisites
        # - Call ProcessSpreadsheet
        # - Call CollectFixCommands
        # - Call ExecuteFixCommands if FIX commands exist
        # - Save spreadsheet with all results
        # - Log completion summary
        
        $this.Log.LogInfo("Run stub called")
    }
}
