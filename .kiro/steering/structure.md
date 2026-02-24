# Project Structure

## Directory Layout

```
DNS-Update/
├── src/                          # Source code modules
│   ├── ConfigurationManager.ps1  # INI configuration management
│   ├── Logger.ps1                # Logging with YYYYMMDD-HH-MM format
│   ├── DnsValidator.ps1          # DNS validation logic
│   ├── DnsUpdater.ps1            # DNS update operations
│   ├── SpreadsheetManager.ps1    # Excel file operations
│   ├── BackupManager.ps1         # Backup management
│   ├── ProgressDisplay.ps1       # Progress tracking UI
│   └── Version.ps1               # Version metadata
├── tests/                        # Pester unit tests
│   ├── Test-ConfigurationManager.ps1
│   ├── Test-DnsValidator.ps1
│   ├── Test-DnsUpdater.ps1
│   ├── Test-Logger.ps1
│   └── Test-SpreadsheetManager.ps1
├── config/                       # Configuration files
│   └── DNS-Update.ini            # Auto-generated on first run
├── logs/                         # Log files (YYYYMMDD-HH-MM format)
├── .kiro/                        # Kiro IDE configuration
│   ├── specs/                    # Specification documents
│   └── steering/                 # AI assistant guidance
└── DNS_Validation.xlsx           # Sample spreadsheet
```

## Module Organization

Each source file in `src/` contains a single PowerShell class with related functionality:

- **ConfigurationManager**: Handles INI file parsing and default values
- **Logger**: Provides structured logging with timestamps
- **DnsValidator**: Validates forward/reverse DNS, detects zones
- **DnsUpdater**: Creates/updates A and PTR records with safety limits
- **SpreadsheetManager**: Reads/writes Excel files using ImportExcel module
- **BackupManager**: Creates timestamped backups of files
- **ProgressDisplay**: Shows progress bars and status updates
- **Version**: Exports version, author, and compile date

## File Naming Conventions

- **Log files**: `YYYYMMDD-HH-MM` format (24-hour time)
- **Backup files**: Include timestamp in filename
- **Test files**: Prefix with `Test-` matching source module name
- **Configuration**: INI format with `.ini` extension

## Testing Structure

- One test file per source module
- Tests use Pester framework
- Test files mirror source file names with `Test-` prefix
- All tests should pass before commits

## Configuration Defaults

Default values in `ConfigurationManager.ps1`:
- DNS Server: eit-priaddc00
- Domain Suffix: .tgna.tegna.com
- Log Directory: ./logs
- Update Limit: 5
- Default Spreadsheet: DNS_Validation.xlsx
- Read-Only Mode: true (safety default)
