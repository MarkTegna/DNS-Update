# MainOrchestrator.ps1
# Main orchestrator for DNS-Update program
# Author: Mark Oldham
# Version: 0.0.1a

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
        $this.Log.LogInfo("DNS-Update program started, version 0.0.1a")
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
    # Requirements: 1.1, 1.2, 1.3, 1.4, 1.6, 1.8, 1.10, 1.11
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
        
        # Track processed (non-skipped) rows
        $processedCount = 0
        $maxProcessed = 50
        
        # Loop through all rows and validate each
        for ($i = 0; $i -lt $totalRows; $i++) {
            # Update progress display
            $this.Progress.UpdateProgress($i + 1)
            
            # Check if we've reached the processing limit
            if ($processedCount -ge $maxProcessed) {
                $this.Log.LogInfo("Reached processing limit of $maxProcessed non-skipped rows. Stopping at row $($i + 1).")
                Write-Host "Processing limit reached ($maxProcessed rows). Remaining rows will be processed on next run." -ForegroundColor Yellow
                break
            }
            
            # Check if row should be skipped (Validated without FIX)
            $status = $this.Spreadsheet.GetCellValue($i, 'Status')
            $forwardDnsSuccess = $this.Spreadsheet.GetCellValue($i, 'Forward DNS Success')
            $reverseDnsSuccess = $this.Spreadsheet.GetCellValue($i, 'Reverse DNS Success')
            
            # Skip if Status is "Validated" and neither validation column contains "FIX"
            if ($status -eq 'Validated' -and 
                $forwardDnsSuccess -notmatch '(?i)FIX' -and 
                $reverseDnsSuccess -notmatch '(?i)FIX') {
                $this.Log.LogAction("Row $($i + 1) skipped", "Already validated without FIX commands")
                continue
            }
            
            # Validate the row
            $this.ValidateRow($i)
            
            # Increment processed count (row was not skipped)
            $processedCount++
        }
        
        # Complete progress display
        if ($totalRows -gt 10) {
            Write-Progress -Activity "Processing DNS Records" -Completed
        }
        
        $this.Log.LogInfo("Spreadsheet processing complete. Processed $processedCount non-skipped rows.")
    }
    
    # Validate a single row
    # Requirements: 1.9, 2.15, 2.16, 2.17
    [void] ValidateRow([int] $rowIndex) {
        # Get hostname and IP address from the row
        $hostname = $this.Spreadsheet.GetCellValue($rowIndex, 'Hostname')
        $ipAddress = $this.Spreadsheet.GetCellValue($rowIndex, 'IP Address')
        
        # Check for empty Hostname or IP Address - skip if empty and mark "Skipped"
        if ([string]::IsNullOrWhiteSpace($hostname) -or [string]::IsNullOrWhiteSpace($ipAddress)) {
            $this.Spreadsheet.UpdateCell($rowIndex, 'Status', 'Skipped')
            $this.Log.LogAction("Row $($rowIndex + 1) skipped", "Empty hostname or IP address")
            return
        }
        
        # Get current validation cell values
        $forwardDnsSuccess = $this.Spreadsheet.GetCellValue($rowIndex, 'Forward DNS Success')
        $reverseDnsSuccess = $this.Spreadsheet.GetCellValue($rowIndex, 'Reverse DNS Success')
        
        # Check if validation cells are empty (but NOT containing "FIX")
        # If user manually entered "FIX", we should NOT overwrite it with validation results
        # Only validate if cell is empty AND does not contain "FIX" (case-insensitive)
        $shouldValidateForward = [string]::IsNullOrWhiteSpace($forwardDnsSuccess) -and ($forwardDnsSuccess -notmatch '(?i)^FIX$')
        $shouldValidateReverse = [string]::IsNullOrWhiteSpace($reverseDnsSuccess) -and ($reverseDnsSuccess -notmatch '(?i)^FIX$')
        
        # Validate Forward DNS if needed
        if ($shouldValidateForward) {
            $forwardResult = $this.Validator.ValidateForwardDns($hostname, $ipAddress)
            $this.Spreadsheet.UpdateCell($rowIndex, 'Forward DNS Success', $forwardResult.Success)
            $this.Spreadsheet.UpdateCell($rowIndex, 'Forward DNS Resolved IP', $forwardResult.ResolvedValue)
            $this.Log.LogQuery("Forward DNS", "$hostname -> $ipAddress", $forwardResult.Success)
        }
        
        # Validate Reverse DNS if needed
        if ($shouldValidateReverse) {
            $reverseResult = $this.Validator.ValidateReverseDns($ipAddress, $hostname)
            $this.Spreadsheet.UpdateCell($rowIndex, 'Reverse DNS Success', $reverseResult.Success)
            $this.Spreadsheet.UpdateCell($rowIndex, 'Reverse DNS Hostname', $reverseResult.ResolvedValue)
            $this.Log.LogQuery("Reverse DNS", "$ipAddress -> $hostname", $reverseResult.Success)
        }
        
        # Collect FIX commands for later execution (case-insensitive)
        $forwardDnsSuccess = $this.Spreadsheet.GetCellValue($rowIndex, 'Forward DNS Success')
        $reverseDnsSuccess = $this.Spreadsheet.GetCellValue($rowIndex, 'Reverse DNS Success')
        
        if ($forwardDnsSuccess -match '(?i)^FIX$') {
            $fixCommand = @{
                RowNumber = $rowIndex
                RecordType = 'A'
                Hostname = $hostname
                IpAddress = $ipAddress
            }
            $this.FixCommands += $fixCommand
        }
        
        if ($reverseDnsSuccess -match '(?i)^FIX$') {
            $fixCommand = @{
                RowNumber = $rowIndex
                RecordType = 'PTR'
                Hostname = $hostname
                IpAddress = $ipAddress
            }
            $this.FixCommands += $fixCommand
        }
        
        # Update status to "Validated" if no FIX commands (case-insensitive)
        if ($forwardDnsSuccess -notmatch '(?i)^FIX$' -and $reverseDnsSuccess -notmatch '(?i)^FIX$') {
            $this.Spreadsheet.UpdateCell($rowIndex, 'Status', 'Validated')
        }
    }
    
    # Collect FIX commands from validated rows
    # Requirements: 3.1, 3.2, 3.7, 3.10, 3.11
    [array] CollectFixCommands() {
        $this.Log.LogInfo("Collecting FIX commands from spreadsheet")
        
        # Return the FixCommands array that was populated during ValidateRow
        # The FixCommands array is already populated with hashtables containing:
        # - RowNumber, RecordType, Hostname, IpAddress
        
        # Now we need to detect zones and check for multiple records
        $processedCommands = @()
        
        foreach ($fixCommand in $this.FixCommands) {
            $hostname = $fixCommand.Hostname
            $ipAddress = $fixCommand.IpAddress
            $recordType = $fixCommand.RecordType
            $rowNumber = $fixCommand.RowNumber
            
            # Detect the appropriate DNS zone
            if ($recordType -eq 'A') {
                # For A records, detect zone based on hostname
                $fqdn = $this.Validator.NormalizeHostname($hostname)
                $zone = $this.Validator.DetectZone($fqdn)
            } else {
                # For PTR records, detect zone based on IP address
                $zone = $this.Validator.DetectZone($ipAddress)
            }
            
            # Check if zone was found
            if ([string]::IsNullOrWhiteSpace($zone)) {
                $this.Spreadsheet.UpdateCell($rowNumber, 'Status', 'FAIL')
                $this.Log.LogError("Zone not found for $recordType record: $hostname / $ipAddress")
                continue
            }
            
            # Check for multiple records
            $hasMultiple = $false
            if ($recordType -eq 'A') {
                $fqdn = $this.Validator.NormalizeHostname($hostname)
                $recordName = $fqdn -replace "\.$zone$", ""
                $hasMultiple = $this.Updater.HasMultipleRecords($recordName, $zone, 'A')
            } else {
                $octets = $ipAddress.Split('.')
                [array]::Reverse($octets)
                $recordName = $octets[0]
                $hasMultiple = $this.Updater.HasMultipleRecords($recordName, $zone, 'PTR')
            }
            
            # If multiple records exist, mark as MULTIPLE and skip
            if ($hasMultiple) {
                $this.Spreadsheet.UpdateCell($rowNumber, 'Status', 'MULTIPLE')
                $this.Log.LogAction("Multiple records found", "$recordType record for $hostname / $ipAddress")
                continue
            }
            
            # Add zone to the fix command and add to processed list
            $fixCommand.Zone = $zone
            $processedCommands += $fixCommand
        }
        
        $this.Log.LogInfo("Collected $($processedCommands.Count) FIX commands")
        return $processedCommands
    }
    
    # Execute FIX commands
    # Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 3.8, 3.9
    [void] ExecuteFixCommands([array] $fixCommands) {
        if ($fixCommands.Count -eq 0) {
            $this.Log.LogInfo("No FIX commands to execute")
            return
        }
        
        $this.Log.LogInfo("Executing $($fixCommands.Count) FIX commands")
        
        # Create backups before any updates
        try {
            $this.Log.LogInfo("Creating backups before DNS updates")
            $this.Backup.CreateBackups($this.Spreadsheet.WorksheetData, $this.Config.GetDnsServer())
        }
        catch {
            $errorMsg = "Failed to create backups: $_"
            $this.Log.LogError($errorMsg)
            Write-Host $errorMsg -ForegroundColor Red
            return
        }
        
        # Display confirmation prompt with all FIX commands
        Write-Host ""
        Write-Host "The following DNS records will be updated:" -ForegroundColor Yellow
        Write-Host ""
        
        foreach ($cmd in $fixCommands) {
            $rowNum = $cmd.RowNumber + 1
            Write-Host "  Row ${rowNum}: $($cmd.RecordType) record - $($cmd.Hostname) -> $($cmd.IpAddress) (Zone: $($cmd.Zone))" -ForegroundColor Cyan
        }
        
        Write-Host ""
        
        # Get user confirmation
        $userConfirmed = $this.Progress.GetUserConfirmation()
        
        if (-not $userConfirmed) {
            $this.Log.LogAction("User declined DNS updates", "Skipping all FIX commands")
            Write-Host "DNS updates cancelled by user" -ForegroundColor Yellow
            return
        }
        
        $this.Log.LogAction("User confirmed DNS updates", "Proceeding with FIX commands")
        
        # Loop through FIX commands up to update limit
        $updateCount = 0
        foreach ($fixCommand in $fixCommands) {
            # Check if we've reached the update limit
            if (-not $this.Updater.CanUpdate()) {
                $this.Log.LogAction("Update limit reached", "Skipping remaining FIX commands")
                Write-Host "Update limit reached ($($this.Config.GetUpdateLimit())). Remaining FIX commands skipped." -ForegroundColor Yellow
                break
            }
            
            $rowNumber = $fixCommand.RowNumber
            $recordType = $fixCommand.RecordType
            $hostname = $fixCommand.Hostname
            $ipAddress = $fixCommand.IpAddress
            $zone = $fixCommand.Zone
            
            # Call appropriate DnsUpdater method based on record type
            if ($recordType -eq 'A') {
                $fqdn = $this.Validator.NormalizeHostname($hostname)
                $result = $this.Updater.UpdateARecord($fqdn, $ipAddress, $zone)
            } else {
                $fqdn = $this.Validator.NormalizeHostname($hostname)
                $result = $this.Updater.UpdatePtrRecord($ipAddress, $fqdn, $zone)
            }
            
            # Write update results to Status column
            if ($result.Success) {
                $this.Spreadsheet.UpdateCell($rowNumber, 'Status', $result.Status)
                $this.Log.LogUpdate($recordType, "$hostname / $ipAddress", $result.Status)
                
                if ($result.Status -eq 'Updated') {
                    $this.Updater.IncrementUpdateCount()
                    $updateCount++
                    Write-Host "Updated $recordType record: $hostname -> $ipAddress" -ForegroundColor Green
                    
                    # Validate the fix to confirm it worked
                    if ($recordType -eq 'A') {
                        $validateResult = $this.Validator.ValidateForwardDns($hostname, $ipAddress)
                        $this.Spreadsheet.UpdateCell($rowNumber, 'Forward DNS Success', $validateResult.Success)
                        $this.Spreadsheet.UpdateCell($rowNumber, 'Forward DNS Resolved IP', $validateResult.ResolvedValue)
                        
                        if ($validateResult.Success -eq 'YES') {
                            Write-Host "  Validation: SUCCESS - Forward DNS now resolves correctly" -ForegroundColor Green
                            $this.Log.LogInfo("Post-update validation successful for A record: $hostname -> $ipAddress")
                        } else {
                            Write-Host "  Validation: FAILED - Forward DNS still not resolving correctly ($($validateResult.Success))" -ForegroundColor Yellow
                            $this.Log.LogError("Post-update validation failed for A record: $hostname -> $ipAddress - Result: $($validateResult.Success)")
                        }
                    } else {
                        $validateResult = $this.Validator.ValidateReverseDns($ipAddress, $hostname)
                        $this.Spreadsheet.UpdateCell($rowNumber, 'Reverse DNS Success', $validateResult.Success)
                        $this.Spreadsheet.UpdateCell($rowNumber, 'Reverse DNS Hostname', $validateResult.ResolvedValue)
                        
                        if ($validateResult.Success -eq 'YES') {
                            Write-Host "  Validation: SUCCESS - Reverse DNS now resolves correctly" -ForegroundColor Green
                            $this.Log.LogInfo("Post-update validation successful for PTR record: $ipAddress -> $hostname")
                        } else {
                            Write-Host "  Validation: FAILED - Reverse DNS still not resolving correctly ($($validateResult.Success))" -ForegroundColor Yellow
                            $this.Log.LogError("Post-update validation failed for PTR record: $ipAddress -> $hostname - Result: $($validateResult.Success)")
                        }
                    }
                } elseif ($result.Status -eq 'ReadOnly') {
                    Write-Host "Read-only mode: Would update $recordType record: $hostname -> $ipAddress" -ForegroundColor Cyan
                }
            } else {
                # Update failed - clear the FIX so it gets re-validated on next run
                if ($recordType -eq 'A') {
                    $this.Spreadsheet.UpdateCell($rowNumber, 'Forward DNS Success', '')
                    $this.Spreadsheet.UpdateCell($rowNumber, 'Forward DNS Resolved IP', '')
                } else {
                    $this.Spreadsheet.UpdateCell($rowNumber, 'Reverse DNS Success', '')
                    $this.Spreadsheet.UpdateCell($rowNumber, 'Reverse DNS Hostname', '')
                }
                
                $this.Spreadsheet.UpdateCell($rowNumber, 'Status', $result.Status)
                $this.Log.LogError("Failed to update $recordType record: $hostname / $ipAddress - Status: $($result.Status)")
                Write-Host "Failed to update $recordType record: $hostname -> $ipAddress" -ForegroundColor Red
                Write-Host "  Cleared FIX flag - will be re-validated on next run" -ForegroundColor Yellow
            }
        }
        
        $this.Log.LogInfo("Executed $updateCount DNS updates")
    }
    
    # Run the complete workflow
    # Requirements: All
    [void] Run([string[]] $args) {
        try {
            # Initialize the orchestrator
            $this.Initialize($args)
            
            # Validate prerequisites (modules and DNS connectivity)
            $this.ValidatePrerequisites()
            
            # Process the spreadsheet (load, validate all rows)
            $this.ProcessSpreadsheet()
            
            # Collect FIX commands from validated rows
            $collectedCommands = $this.CollectFixCommands()
            
            # Execute FIX commands if any exist
            if ($collectedCommands.Count -gt 0) {
                $this.ExecuteFixCommands($collectedCommands)
            } else {
                $this.Log.LogInfo("No FIX commands found, skipping DNS updates")
                Write-Host "No FIX commands found. All validations complete." -ForegroundColor Green
            }
            
            # Save spreadsheet with all results
            $this.Log.LogInfo("Saving spreadsheet with results")
            $this.Spreadsheet.SaveSpreadsheet($this.SpreadsheetPath)
            $this.Log.LogInfo("Spreadsheet saved: $($this.SpreadsheetPath)")
            
            # Log completion summary
            $totalRows = $this.Spreadsheet.GetRows().Count
            $this.Log.LogInfo("DNS-Update completed successfully")
            $this.Log.LogInfo("Total rows processed: $totalRows")
            $this.Log.LogInfo("FIX commands executed: $($collectedCommands.Count)")
            
            Write-Host "`nDNS-Update completed successfully!" -ForegroundColor Green
            Write-Host "Results saved to: $($this.SpreadsheetPath)" -ForegroundColor Gray
            Write-Host "Log file: $($this.Log.LogFilePath)" -ForegroundColor Gray
            
            # Pause for 10 seconds or until user presses a key
            Write-Host "`nPress any key to exit (or wait 10 seconds)..." -ForegroundColor Yellow
            $timeout = 10
            $startTime = Get-Date
            while (((Get-Date) - $startTime).TotalSeconds -lt $timeout) {
                if ([Console]::KeyAvailable) {
                    [Console]::ReadKey($true) | Out-Null
                    break
                }
                Start-Sleep -Milliseconds 100
            }
        }
        catch {
            $errorMsg = "DNS-Update failed: $_"
            if ($null -ne $this.Log) {
                $this.Log.LogError($errorMsg)
            }
            Write-Host $errorMsg -ForegroundColor Red
            
            # Pause for 10 seconds or until user presses a key (even on error)
            Write-Host "`nPress any key to exit (or wait 10 seconds)..." -ForegroundColor Yellow
            $timeout = 10
            $startTime = Get-Date
            while (((Get-Date) - $startTime).TotalSeconds -lt $timeout) {
                if ([Console]::KeyAvailable) {
                    [Console]::ReadKey($true) | Out-Null
                    break
                }
                Start-Sleep -Milliseconds 100
            }
            throw
        }
    }
}
