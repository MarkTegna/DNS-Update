# DNS-Update Quick Start

## Installation

1. **Install Required Modules:**
   ```powershell
   Install-Module -Name DnsServer -Force
   Install-Module -Name ImportExcel -Force
   ```

2. **Navigate to DNS-Update Directory:**
   ```powershell
   cd C:\path\to\DNS-Update
   ```

## First Run

```powershell
.\DNS-Update.ps1
```

This will:
- Create `config/DNS-Update.ini` with defaults
- Create `DNS_Validation.xlsx` with your local host info
- Validate DNS (read-only mode - no changes made)
- Create log file in `logs/`

## Configuration

Edit `config/DNS-Update.ini`:

```ini
[DNS]
Server=eit-priaddc00              # Your DNS server
DomainSuffix=.tgna.tegna.com      # Your domain

[Safety]
ReadOnlyMode=true                  # false to make actual changes
```

## Basic Commands

```powershell
# Run with default spreadsheet
.\DNS-Update.ps1

# Run with custom spreadsheet
.\DNS-Update.ps1 -SpreadsheetPath "MyDNS.xlsx"

# Show help
.\DNS-Update.ps1 -Help
```

## Spreadsheet Columns (Required)

- Hostname
- IP Address
- Forward DNS Success
- Forward DNS Resolved IP
- Reverse DNS Success
- Reverse DNS Hostname

## Making DNS Updates

1. Run validation (ReadOnlyMode=true)
2. Edit spreadsheet - change "NO" to "FIX" where you want updates
3. Test: Run again to see what would change
4. Edit config: Set ReadOnlyMode=false
5. Run: `.\DNS-Update.ps1`
6. Confirm: Type "Y" when prompted

## Validation Results

- **YES** = DNS matches spreadsheet
- **NO** = DNS doesn't match (use "FIX" to update)
- **FAIL** = DNS zone not found
- **MULTIPLE** = Multiple records exist
- **FIX** = Command to update this record

## Safety Features

✓ Read-only mode by default
✓ Confirmation prompt before changes
✓ Automatic backups created
✓ Update limit (5 per run)
✓ Detailed logging

## Files Created

- `config/DNS-Update.ini` - Configuration
- `logs/DNS-Update_YYYYMMDD-HH-MM.log` - Log file
- `logs/DNS_Backup_YYYYMMDD-HH-MM.*` - Backups (when updating)
- `DNS_Validation.xlsx` - Sample spreadsheet

## Troubleshooting

**Module not found?**
```powershell
Install-Module -Name DnsServer -Force
Install-Module -Name ImportExcel -Force
```

**DNS connectivity failed?**
- Check DNS server name in config
- Verify network connectivity
- Check permissions

**Missing columns?**
- Ensure spreadsheet has all required columns
- Column order doesn't matter

## Example Workflow

```powershell
# 1. First run - creates sample spreadsheet
.\DNS-Update.ps1

# 2. Edit DNS_Validation.xlsx - add your DNS entries

# 3. Validate (read-only)
.\DNS-Update.ps1

# 4. Mark records for update - change "NO" to "FIX" in spreadsheet

# 5. Test what would change (still read-only)
.\DNS-Update.ps1

# 6. Make actual changes
# Edit config: ReadOnlyMode=false
.\DNS-Update.ps1

# 7. Type "Y" to confirm

# 8. Verify results in spreadsheet
```

## Need More Help?

See `TESTING_GUIDE.md` for detailed instructions.

Author: Mark Oldham | Version: 0.0.1
