# Requirements Document

## Introduction

DNS-Update is a PowerShell-based tool that validates and updates DNS entries by reading an Excel spreadsheet, checking forward and reverse DNS records against Microsoft DNS servers, and updating DNS when requested. The program runs iteratively on the same spreadsheet until all entries are validated as correct.

## Glossary

- **DNS_Program**: DNS-Update
- **Spreadsheet**: The Excel file containing DNS entries to validate and update
- **Forward_DNS**: DNS lookup that resolves a hostname to an IP address (A record)
- **Reverse_DNS**: DNS lookup that resolves an IP address to a hostname (PTR record)
- **DNS_Server**: The Microsoft DNS server being queried and updated (default: eit-priaddc00)
- **Validation_Cell**: A cell in the spreadsheet containing validation results (Forward DNS Success or Reverse DNS Success columns)
- **Status_Column**: A column in the spreadsheet tracking the last action taken on each row
- **FIX_Command**: The text "FIX" (case insensitive) placed in a validation cell to trigger DNS update
- **Update_Limit**: The maximum number of DNS updates allowed per program run (default: 5)
- **DNS_Zone**: A DNS zone on the DNS server that contains DNS records
- **FQDN**: Fully Qualified Domain Name (e.g., server.tgna.tegna.com)
- **Short_Name**: Hostname without domain suffix (e.g., server)
- **Domain_Suffix**: The default domain suffix appended to short names (default: .tgna.tegna.com)
- **Backup_Export**: A timestamped copy of DNS records before any changes are made

## Requirements

### Requirement 1: Spreadsheet Input and Processing

**User Story:** As a DNS administrator, I want to process an Excel spreadsheet containing DNS entries, so that I can validate and update multiple DNS records efficiently.

#### Acceptance Criteria

1. WHEN the DNS_Program starts, THE DNS_Program SHALL read the Excel file specified via command line argument or configuration file
2. WHERE no filename is specified, THE DNS_Program SHALL use "DNS_Validation.xlsx" as the default filename
3. WHEN the Spreadsheet file does not exist, THE DNS_Program SHALL create a sample Spreadsheet with correct column headers
4. WHEN creating a sample Spreadsheet, THE DNS_Program SHALL populate one row with local host information including hostname and IP address
5. WHEN reading the Spreadsheet, THE DNS_Program SHALL locate columns by name regardless of column order
6. THE DNS_Program SHALL require these columns: Hostname, IP Address, Forward DNS Success, Forward DNS Resolved IP, Reverse DNS Success, Reverse DNS Hostname
7. WHEN the Spreadsheet contains additional columns, THE DNS_Program SHALL preserve them without modification
8. WHEN the Spreadsheet is missing required columns, THE DNS_Program SHALL terminate with an error message specifying which columns are missing
9. WHEN a row has an empty Hostname or IP Address, THE DNS_Program SHALL skip that row and write "Skipped" to the Status_Column
10. WHEN a row has Status_Column value "Validated" and neither Forward DNS Success nor Reverse DNS Success contains "FIX", THE DNS_Program SHALL skip that row
11. WHEN the DNS_Program has processed 50 rows that were not skipped, THE DNS_Program SHALL stop processing remaining rows
12. THE DNS_Program SHALL add a Status_Column to the Spreadsheet if it does not exist
13. WHEN processing completes, THE DNS_Program SHALL write all validation results and status updates to the same Spreadsheet file

### Requirement 2: DNS Validation Operations

**User Story:** As a DNS administrator, I want to validate forward and reverse DNS entries against the DNS server, so that I can identify discrepancies between the spreadsheet and actual DNS records.

#### Acceptance Criteria

1. WHEN validating Forward_DNS, THE DNS_Program SHALL query the DNS_Server using Get-DnsServerResourceRecord for the hostname
2. WHEN validating Reverse_DNS, THE DNS_Program SHALL query the DNS_Server using Get-DnsServerResourceRecord for the IP address
3. WHEN a hostname is a Short_Name, THE DNS_Program SHALL append the Domain_Suffix before querying
4. THE DNS_Program SHALL perform all hostname and DNS comparisons case-insensitively
5. WHEN Forward_DNS query returns an IP address matching the Spreadsheet IP Address, THE DNS_Program SHALL write "YES" to Forward DNS Success
6. WHEN Forward_DNS query returns an IP address not matching the Spreadsheet IP Address, THE DNS_Program SHALL write "NO" to Forward DNS Success
7. WHEN Forward_DNS query fails due to missing DNS_Zone, THE DNS_Program SHALL write "FAIL" to Forward DNS Success
8. WHEN Forward_DNS query returns multiple A records and any record matches the Spreadsheet IP Address, THE DNS_Program SHALL write "YES" to Forward DNS Success
9. WHEN Forward_DNS query returns multiple A records and no record matches the Spreadsheet IP Address, THE DNS_Program SHALL write "MULTIPLE" to Forward DNS Success
10. WHEN Reverse_DNS query returns a hostname matching the Spreadsheet Hostname, THE DNS_Program SHALL write "YES" to Reverse DNS Success
11. WHEN Reverse_DNS query returns a hostname not matching the Spreadsheet Hostname, THE DNS_Program SHALL write "NO" to Reverse DNS Success
12. WHEN Reverse_DNS query fails due to missing DNS_Zone, THE DNS_Program SHALL write "FAIL" to Reverse DNS Success
13. WHEN Reverse_DNS query returns multiple PTR records and any record matches the Spreadsheet Hostname, THE DNS_Program SHALL write "YES" to Reverse DNS Success
14. WHEN Reverse_DNS query returns multiple PTR records and no record matches the Spreadsheet Hostname, THE DNS_Program SHALL write "MULTIPLE" to Reverse DNS Success
15. WHEN a Validation_Cell is empty, THE DNS_Program SHALL perform validation for that DNS type
16. THE DNS_Program SHALL write the resolved IP address to Forward DNS Resolved IP column
17. THE DNS_Program SHALL write the resolved hostname to Reverse DNS Hostname column

### Requirement 3: DNS Update Operations

**User Story:** As a DNS administrator, I want to update DNS records by marking validation cells with "FIX", so that I can correct discrepancies between the spreadsheet and DNS server.

#### Acceptance Criteria

1. WHEN Forward DNS Success contains "FIX" (case insensitive), THE DNS_Program SHALL create or update the A record for that hostname
2. WHEN Reverse DNS Success contains "FIX" (case insensitive), THE DNS_Program SHALL create or update the PTR record for that IP address
3. WHEN an A record does not exist and Forward DNS Success contains "FIX", THE DNS_Program SHALL create the A record using Set-DnsServerResourceRecord
4. WHEN an A record exists with incorrect IP and Forward DNS Success contains "FIX", THE DNS_Program SHALL update the A record to the Spreadsheet IP Address
5. WHEN a PTR record does not exist and Reverse DNS Success contains "FIX", THE DNS_Program SHALL create the PTR record using Set-DnsServerResourceRecord
6. WHEN a PTR record exists with incorrect hostname and Reverse DNS Success contains "FIX", THE DNS_Program SHALL update the PTR record to the Spreadsheet Hostname
7. WHEN multiple DNS records exist for a FIX_Command, THE DNS_Program SHALL write "MULTIPLE" to the Status_Column and skip the update
8. WHEN the Update_Limit is reached, THE DNS_Program SHALL skip all remaining FIX_Command operations
9. WHEN the Update_Limit is reached, THE DNS_Program SHALL continue validating remaining rows
10. THE DNS_Program SHALL auto-detect the DNS_Zone based on the hostname or IP address
11. WHEN a DNS_Zone cannot be found for a FIX_Command, THE DNS_Program SHALL write "FAIL" to the Status_Column

### Requirement 4: Safety and Backup Operations

**User Story:** As a DNS administrator, I want safety features and backups before making DNS changes, so that I can recover from mistakes and review changes before they are applied.

#### Acceptance Criteria

1. WHEN the DNS_Program identifies FIX_Command operations to perform, THE DNS_Program SHALL create a Backup_Export before making any changes
2. THE DNS_Program SHALL create three backup formats: timestamped Excel file, CSV file, and PowerShell Export-Clixml file
3. THE DNS_Program SHALL use filename format YYYYMMDD-HH-MM for all Backup_Export files
4. WHEN FIX_Command operations are identified, THE DNS_Program SHALL display all records to be updated in a confirmation prompt
5. WHEN the user responds "N" to the confirmation prompt, THE DNS_Program SHALL skip all DNS updates and continue with validation only
6. WHEN the user responds "Y" to the confirmation prompt, THE DNS_Program SHALL proceed with DNS updates
7. WHEN the DNS_Program starts, THE DNS_Program SHALL validate DNS connectivity by testing local hostname forward and reverse lookup
8. WHEN DNS connectivity validation fails, THE DNS_Program SHALL terminate with an error message
9. WHEN the DnsServer PowerShell module is not available, THE DNS_Program SHALL terminate with installation instructions
10. WHEN the ImportExcel PowerShell module is not available, THE DNS_Program SHALL terminate with installation instructions

### Requirement 5: Configuration Management

**User Story:** As a DNS administrator, I want to configure program behavior through an INI file, so that I can customize the program for different environments without modifying code.

#### Acceptance Criteria

1. THE DNS_Program SHALL read configuration from a .ini file
2. THE DNS_Program SHALL support configuration of DNS_Server target with default value "eit-priaddc00"
3. THE DNS_Program SHALL support configuration of Domain_Suffix with default value ".tgna.tegna.com"
4. THE DNS_Program SHALL support configuration of log directory with default value "./logs"
5. THE DNS_Program SHALL support configuration of Update_Limit with default value 5
6. THE DNS_Program SHALL support configuration of default Spreadsheet filename with default value "DNS_Validation.xlsx"
7. THE DNS_Program SHALL support configuration of ReadOnlyMode with default value true
8. WHEN ReadOnlyMode is true, THE DNS_Program SHALL skip all DNS update operations (Set-DnsServerResourceRecord and Add-DnsServerResourceRecord)
9. WHEN ReadOnlyMode is true, THE DNS_Program SHALL log that updates were skipped due to read-only mode
10. WHEN ReadOnlyMode is true, THE DNS_Program SHALL still perform all validation operations and display what would be updated
11. WHEN the .ini file does not exist, THE DNS_Program SHALL create it with all default options
12. WHEN the .ini file is created, THE DNS_Program SHALL include all available options with non-default options commented out

### Requirement 6: Logging and Progress Display

**User Story:** As a DNS administrator, I want detailed logging and progress display, so that I can troubleshoot issues and monitor program execution.

#### Acceptance Criteria

1. THE DNS_Program SHALL create log files using filename format YYYYMMDD-HH-MM in 24-hour format
2. THE DNS_Program SHALL write log files to the directory specified in configuration
3. THE DNS_Program SHALL log all DNS queries with hostname or IP address and result
4. THE DNS_Program SHALL log all DNS updates with record type, hostname or IP address, and result
5. THE DNS_Program SHALL log all errors with error message and context
6. THE DNS_Program SHALL log all actions taken including validation, updates, and skipped operations
7. WHEN processing more than 10 rows, THE DNS_Program SHALL display progress in format "Processing row X of Y..."
8. THE DNS_Program SHALL update the Status_Column with values: "Skipped", "Validated", "Updated", "Failed", or "MULTIPLE"

### Requirement 7: Platform and Distribution

**User Story:** As a DNS administrator, I want the program packaged as a Windows executable with proper version management, so that I can deploy and track versions easily.

#### Acceptance Criteria

1. THE DNS_Program SHALL be implemented as a PowerShell script
2. THE DNS_Program SHALL run on Windows Server as a domain member with DNS update rights
3. THE DNS_Program SHALL be packaged as a Windows executable including all supporting files
4. THE DNS_Program SHALL be distributed as a ZIP file with version number in the filename
5. THE DNS_Program SHALL follow version management standards with initial version 0.0.1
6. THE DNS_Program SHALL include author "Mark Oldham" in documentation and help
7. THE DNS_Program SHALL include version number and compile date in documentation and help

### Requirement 8: Testing Requirements

**User Story:** As a developer, I want to test the program against live DNS environment using actual spreadsheet records, so that I can ensure the program works correctly in production conditions.

#### Acceptance Criteria

1. THE DNS_Program SHALL be tested against live DNS environment only
2. THE DNS_Program SHALL be tested using records from actual Spreadsheet only
3. THE DNS_Program SHALL validate DNS connectivity before processing any records
