# Implementation Plan: DNS-Update

## Overview

This implementation plan breaks down the DNS-Update program into discrete coding tasks. The program will be implemented in PowerShell, leveraging native DNS cmdlets and the ImportExcel module. Tasks are organized to build incrementally, with early validation of core functionality through code and testing.

## Tasks

- [x] 1. Set up project structure and configuration management
  - Create project directory structure (src/, logs/, config/)
  - Implement Configuration Manager to read/write INI files
  - Create default INI file with all configuration options (ReadOnlyMode defaults to true)
  - Add version information (__version__ = "0.0.1", __author__ = "Mark Oldham", __compile_date__)
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.11, 5.12, 7.5, 7.6, 7.7_

- [ ]* 1.1 Write unit tests for Configuration Manager
  - Test INI file creation with defaults (including ReadOnlyMode=true)
  - Test configuration value reading
  - Test handling of missing configuration keys
  - _Requirements: 5.1, 5.11, 5.12_

- [x] 2. Implement Logger component
  - Create Logger class with file initialization
  - Implement log methods: LogInfo, LogError, LogQuery, LogUpdate, LogAction
  - Use timestamp format YYYYMMDD-HH-MM for log filenames (24-hour format)
  - Implement timestamped log entry format [YYYY-MM-DD HH:MM:SS] [LEVEL] Message
  - Ensure ASCII-only characters in log output (no Unicode box-drawing characters)
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ]* 2.1 Write property test for Logger
  - **Property 22: Log File Format and Location**
  - **Validates: Requirements 6.1, 6.2**

- [ ]* 2.2 Write property test for complete logging
  - **Property 23: Complete Logging**
  - **Validates: Requirements 6.3, 6.4, 6.5, 6.6**

- [ ] 3. Implement Spreadsheet Manager
  - [x] 3.1 Create SpreadsheetManager class with ImportExcel module integration
    - Implement FileExists method
    - Implement LoadSpreadsheet using Import-Excel cmdlet
    - Implement SaveSpreadsheet using Export-Excel cmdlet
    - Implement MapColumns to locate columns by name
    - Implement GetRows, GetCellValue, UpdateCell methods
    - _Requirements: 1.1, 1.2, 1.5, 1.6, 1.11_

  - [ ]* 3.2 Write property test for column order independence
    - **Property 1: Column Order Independence**
    - **Validates: Requirements 1.5**

  - [x] 3.3 Implement CreateSampleSpreadsheet method
    - Get local hostname using hostname command
    - Get local IP address using Get-NetIPAddress cmdlet
    - Create Excel file with required column headers
    - Populate one row with local host information
    - _Requirements: 1.3, 1.4_

  - [ ]* 3.4 Write property test for sample spreadsheet creation
    - **Property 26: Sample Spreadsheet Creation**
    - **Validates: Requirements 1.3, 1.4**

  - [x] 3.5 Implement AddStatusColumn method
    - Check if Status column exists
    - Add Status column if missing
    - _Requirements: 1.10_

  - [ ]* 3.6 Write property test for additional column preservation
    - **Property 2: Additional Column Preservation**
    - **Validates: Requirements 1.7**

  - [ ]* 3.7 Write property test for required column validation
    - **Property 3: Required Column Validation**
    - **Validates: Requirements 1.8**

  - [ ]* 3.8 Write property test for spreadsheet round-trip
    - **Property 5: Spreadsheet Round-Trip**
    - **Validates: Requirements 1.11**

- [x] 4. Checkpoint - Ensure spreadsheet operations work
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement DNS Validator component
  - [x] 5.1 Create DnsValidator class with DNS query methods
    - Implement NormalizeHostname to append domain suffix to short names
    - Implement ValidateForwardDns using Get-DnsServerResourceRecord
    - Implement ValidateReverseDns using Get-DnsServerResourceRecord
    - Perform case-insensitive hostname/IP comparisons
    - Handle multiple A/PTR records (return YES if any match)
    - Return validation results as hashtable with Success and ResolvedValue keys
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.8, 2.9, 2.10, 2.11, 2.13, 2.14, 2.15, 2.16, 2.17_

  - [ ]* 5.2 Write property test for hostname normalization
    - **Property 6: Hostname Normalization**
    - **Validates: Requirements 2.3**

  - [ ]* 5.3 Write property test for case-insensitive comparison
    - **Property 7: Case-Insensitive Comparison**
    - **Validates: Requirements 2.4**

  - [ ]* 5.4 Write property test for forward DNS validation logic
    - **Property 8: Forward DNS Validation Logic**
    - **Validates: Requirements 2.5, 2.6, 2.8, 2.9**

  - [ ]* 5.5 Write property test for reverse DNS validation logic
    - **Property 9: Reverse DNS Validation Logic**
    - **Validates: Requirements 2.10, 2.11, 2.13, 2.14**

  - [ ]* 5.6 Write property test for empty cell validation trigger
    - **Property 10: Empty Cell Triggers Validation**
    - **Validates: Requirements 2.15**

  - [ ]* 5.7 Write property test for resolved values written
    - **Property 11: Resolved Values Written**
    - **Validates: Requirements 2.16, 2.17**

  - [x] 5.8 Implement TestDnsConnectivity method
    - Test local hostname forward lookup
    - Test local hostname reverse lookup
    - Return true if both succeed, false otherwise
    - _Requirements: 4.7, 8.3_

  - [x] 5.9 Implement DetectZone method
    - Use Get-DnsServerZone cmdlet to get all zones
    - For hostnames: find longest matching forward lookup zone
    - For IP addresses: find matching reverse lookup zone
    - Return zone name or null if not found
    - _Requirements: 3.10_

  - [ ]* 5.10 Write property test for DNS zone auto-detection
    - **Property 15: DNS Zone Auto-Detection**
    - **Validates: Requirements 3.10**

- [ ] 6. Implement DNS Updater component
  - [x] 6.1 Create DnsUpdater class with update methods
    - Implement RecordExists to check for existing DNS records
    - Implement HasMultipleRecords to detect multiple A/PTR records
    - Implement UpdateARecord using Add-DnsServerResourceRecord or Set-DnsServerResourceRecord (skip if ReadOnlyMode is true)
    - Implement UpdatePtrRecord using Add-DnsServerResourceRecord or Set-DnsServerResourceRecord (skip if ReadOnlyMode is true)
    - When ReadOnlyMode is true, log that updates were skipped and return simulated results
    - Implement CanUpdate to check update limit
    - Implement IncrementUpdateCount to track updates
    - Return update results as hashtable with Success and Status keys
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.11, 5.8, 5.9, 5.10_

  - [ ]* 6.2 Write property test for FIX command case insensitivity
    - **Property 12: FIX Command Case Insensitivity**
    - **Validates: Requirements 3.1, 3.2**

  - [ ]* 6.3 Write property test for DNS record update
    - **Property 13: DNS Record Update**
    - **Validates: Requirements 3.4, 3.6**

  - [ ]* 6.4 Write property test for update limit enforcement
    - **Property 14: Update Limit Enforcement**
    - **Validates: Requirements 3.8, 3.9**

- [x] 7. Checkpoint - Ensure DNS operations work
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Implement Backup Manager component
  - [x] 8.1 Create BackupManager class with backup methods
    - Implement GenerateTimestamp using format YYYYMMDD-HH-MM (24-hour)
    - Implement ExportToExcel using Export-Excel cmdlet
    - Implement ExportToCsv using Export-Csv cmdlet
    - Implement ExportToClixml using Export-Clixml cmdlet
    - Implement CreateBackups to create all three backup formats
    - Save backups to configured log directory
    - _Requirements: 4.1, 4.2, 4.3_

  - [ ]* 8.2 Write property test for backup before changes
    - **Property 16: Backup Before Changes**
    - **Validates: Requirements 4.1**

  - [ ]* 8.3 Write property test for complete backup set
    - **Property 17: Complete Backup Set**
    - **Validates: Requirements 4.2, 4.3**

- [ ] 9. Implement Progress Display component
  - [x] 9.1 Create ProgressDisplay class with display methods
    - Implement Initialize to set total row count
    - Implement UpdateProgress using Write-Progress cmdlet
    - Only show progress if more than 10 rows
    - Implement ShowConfirmation to display FIX commands in table format using Format-Table
    - Implement GetUserConfirmation using Read-Host for Y/N prompt
    - Ensure ASCII-only characters in all display output (no Unicode box-drawing)
    - _Requirements: 6.7, 4.4, 4.5, 4.6_

  - [ ]* 9.2 Write property test for progress display threshold
    - **Property 24: Progress Display Threshold**
    - **Validates: Requirements 6.7**

  - [ ]* 9.3 Write property test for confirmation prompt content
    - **Property 18: Confirmation Prompt Content**
    - **Validates: Requirements 4.4**

  - [ ]* 9.4 Write property test for user confirmation controls updates
    - **Property 19: User Confirmation Controls Updates**
    - **Validates: Requirements 4.5, 4.6**

- [ ] 10. Implement Main Orchestrator
  - [x] 10.1 Create MainOrchestrator class with main program flow
    - Implement Initialize to parse command line arguments and load configuration
    - Implement ValidatePrerequisites to check for DnsServer and ImportExcel modules
    - Display installation instructions if modules are missing: Install-Module -Name DnsServer, Install-Module -Name ImportExcel
    - Call TestDnsConnectivity and terminate if DNS connectivity fails
    - _Requirements: 4.7, 4.8, 4.9, 4.10_

  - [x] 10.2 Implement ProcessSpreadsheet method
    - Check if spreadsheet file exists, create sample if not
    - Load spreadsheet using SpreadsheetManager
    - Validate required columns exist
    - Add Status column if missing
    - Initialize progress display
    - Loop through all rows and call ValidateRow for each
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.6, 1.8, 1.10_

  - [x] 10.3 Implement ValidateRow method
    - Check for empty Hostname or IP Address, skip if empty and mark "Skipped"
    - Check if validation cells are empty or contain "FIX"
    - Call DnsValidator methods for forward and reverse DNS
    - Write validation results to spreadsheet cells
    - Collect FIX commands for later execution
    - Update progress display
    - _Requirements: 1.9, 2.15, 2.16, 2.17_

  - [ ]* 10.4 Write property test for empty row handling
    - **Property 4: Empty Row Handling**
    - **Validates: Requirements 1.9**

  - [ ] 10.5 Implement CollectFixCommands method
    - Scan all rows for "FIX" in validation cells (case insensitive)
    - Create FixCommand objects with row number, record type, hostname, IP, zone
    - Detect zone for each FIX command
    - Check for multiple records, mark as "MULTIPLE" if found
    - Return array of FixCommand objects
    - _Requirements: 3.1, 3.2, 3.7, 3.10, 3.11_

  - [ ] 10.6 Implement ExecuteFixCommands method
    - Create backups before any updates
    - Display confirmation prompt with all FIX commands
    - If user responds "N", skip updates and return
    - If user responds "Y", proceed with updates
    - Loop through FIX commands up to update limit
    - Call DnsUpdater methods for each FIX command
    - Write update results to Status column
    - Log all update operations
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 3.8, 3.9_

  - [ ] 10.7 Implement Run method to orchestrate complete workflow
    - Call Initialize
    - Call ValidatePrerequisites
    - Call ProcessSpreadsheet
    - Call CollectFixCommands
    - Call ExecuteFixCommands if FIX commands exist
    - Save spreadsheet with all results
    - Log completion summary
    - _Requirements: All_

  - [ ]* 10.8 Write property test for valid status values
    - **Property 25: Valid Status Values**
    - **Validates: Requirements 6.8**

  - [ ]* 10.9 Write property test for configuration file auto-creation
    - **Property 20: Configuration File Auto-Creation**
    - **Validates: Requirements 5.7, 5.8**

  - [ ]* 10.10 Write property test for configuration defaults
    - **Property 21: Configuration Defaults**
    - **Validates: Requirements 5.2, 5.3, 5.4, 5.5, 5.6, 5.7**

  - [ ]* 10.11 Write property test for read-only mode safety
    - **Property 27: Read-Only Mode Safety**
    - **Validates: Requirements 5.8, 5.9, 5.10**

- [ ] 11. Create main entry point script
  - Create DNS-Update.ps1 as main entry point
  - Parse command line arguments for spreadsheet filename (default: DNS_Validation.xlsx)
  - Support -Help parameter to display usage information
  - Create MainOrchestrator instance
  - Call Run method with arguments
  - Handle top-level exceptions and display error messages
  - Add help text showing author "Mark Oldham", version, compile date, and usage examples
  - _Requirements: 1.1, 1.2, 7.6, 7.7_

- [ ] 12. Checkpoint - Ensure end-to-end workflow works
  - Ensure all tests pass, ask the user if questions arise.

- [ ]* 13. Write integration tests
  - Test complete workflow: load → validate → FIX → update → save
  - Test iterative workflow: process same spreadsheet multiple times
  - Test update limit enforcement across multiple runs
  - Test backup and restore scenarios
  - _Requirements: All_

- [ ] 14. Create build and distribution scripts
  - Create PowerShell build script to package the program
  - Include version management following version-management.md standards (initial version 0.0.1)
  - Support automatic builds (letter suffix: 0.0.1a, 0.0.1b) for development
  - Support user builds (no letter: 0.0.1 → 0.0.2) when explicitly requested
  - Create ZIP distribution with version number in filename format: DNS-Update-{version}.zip
  - Include all supporting files: INI template, README, logs directory structure
  - Add compile date to version information in format YYYY-MM-DD
  - Never auto-push to GitHub (only when explicitly told)
  - _Requirements: 7.3, 7.4, 7.5_

- [ ] 15. Create documentation
  - Create README.md with installation instructions for PowerShell modules (DnsServer, ImportExcel)
  - Include usage examples showing command line syntax and spreadsheet format
  - Document all INI configuration options with defaults and descriptions
  - Document all Status column values: Skipped, Validated, Updated, Failed, MULTIPLE
  - Document backup file formats (Excel, CSV, Clixml) and locations
  - Include author "Mark Oldham", version number, and compile date in header
  - Add troubleshooting section for common issues (DNS connectivity, module installation, permissions)
  - _Requirements: 7.6, 7.7_

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties (minimum 100 iterations each)
- Unit tests validate specific examples and edge cases
- All testing must be performed against live DNS environment using actual spreadsheet records
- PowerShell modules required: DnsServer, ImportExcel
- Program must run on Windows Server as domain member with DNS update rights
- Platform: Windows only (uses native Windows DNS cmdlets)
- All log and backup files use timestamp format YYYYMMDD-HH-MM (24-hour format)
- ASCII-only output in logs and console (no Unicode box-drawing characters per lessons-learned.md)
- Version management follows version-management.md standards with automatic builds (letter suffix) for development
