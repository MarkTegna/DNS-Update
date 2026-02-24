# Technology Stack

## Language & Platform

- **Language**: PowerShell (NOTE: This project uses PowerShell, not Python as specified in global standards)
- **Platform**: Windows
- **Target**: Windows DNS Server management
- **Rationale**: PowerShell is required for native Windows DNS Server management via DnsServer module

## Core Dependencies

- **DnsServer Module**: Windows PowerShell module for DNS server management (Get-DnsServerResourceRecord, Add-DnsServerResourceRecordA, etc.)
- **ImportExcel Module**: PowerShell module for reading/writing Excel files without Excel installation
- **Pester**: PowerShell testing framework for unit tests

## Architecture

The project uses a modular class-based architecture with the following components:

- **ConfigurationManager**: INI-based configuration management
- **Logger**: Structured logging with timestamp-based filenames
- **DnsValidator**: DNS record validation (forward and reverse lookups)
- **DnsUpdater**: DNS record creation and updates with safety limits
- **SpreadsheetManager**: Excel file reading and writing
- **BackupManager**: Configuration and data file backup
- **ProgressDisplay**: User-facing progress tracking and display
- **Version**: Version metadata management

## Common Commands

### Testing
```powershell
# Run all tests
.\tests\Test-ConfigurationManager.ps1
.\tests\Test-DnsValidator.ps1
.\tests\Test-DnsUpdater.ps1
.\tests\Test-Logger.ps1
.\tests\Test-SpreadsheetManager.ps1

# Run specific test file
Invoke-Pester -Path .\tests\Test-ConfigurationManager.ps1
```

### Running the Application
```powershell
# Run with default configuration
.\DNS-Update.ps1

# Run with custom spreadsheet
.\DNS-Update.ps1 -SpreadsheetPath "custom.xlsx"

# Run in update mode (not read-only)
.\DNS-Update.ps1 -ReadOnlyMode $false
```

## Configuration

- Configuration files use INI format
- Default location: `config/DNS-Update.ini`
- Auto-created with defaults on first run
- All configurable options must be in INI files
- Default options are uncommented, optional settings are commented out

## Version Management

- Version format: `MAJOR.MINOR.PATCH[LETTER]` (e.g., 0.0.1, 0.0.1a)
- Version info stored in `src/Version.ps1`
- Automatic builds increment letter suffix
- User builds increment PATCH and remove letter
- Current version: 0.0.1
