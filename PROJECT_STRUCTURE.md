# DNS-Update Project Structure

## Directory Layout

```
DNS-Update/
├── src/                          # Source code
│   ├── ConfigurationManager.ps1  # Configuration management class
│   └── Version.ps1               # Version information
├── tests/                        # Unit tests
│   └── Test-ConfigurationManager.ps1
├── logs/                         # Log files (YYYYMMDD-HH-MM format)
├── config/                       # Configuration files
└── DNS_Validation.xlsx           # Sample spreadsheet
```

## Version Information

- **Version**: 0.0.1
- **Author**: Mark Oldham
- **Compile Date**: Auto-generated on build

## Configuration Management

The Configuration Manager handles all program settings through an INI file format.

### Default Configuration Values

- **DNS Server**: eit-priaddc00
- **Domain Suffix**: .tgna.tegna.com
- **Log Directory**: ./logs
- **Update Limit**: 5
- **Default Spreadsheet**: DNS_Validation.xlsx
- **Read-Only Mode**: true (default for safety)

### Configuration File Location

The default configuration file will be created at `config/DNS-Update.ini` when the program first runs.

### Read-Only Mode

By default, ReadOnlyMode is set to `true` for safety. When enabled:
- All validation operations proceed normally
- DNS update operations are skipped
- Program logs what would be updated
- No actual DNS changes are made

This allows safe testing and validation before making real DNS changes.

## Testing

Unit tests are located in the `tests/` directory. Run tests with:

```powershell
.\tests\Test-ConfigurationManager.ps1
```

All tests currently pass:
- Configuration file auto-creation with defaults
- Custom configuration value loading
- Missing key handling (uses defaults)
- ReadOnlyMode defaults to true

## Next Steps

Task 1 is complete. The next task (Task 2) will implement the Logger component.
