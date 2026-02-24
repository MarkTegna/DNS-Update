# DNS-Update Testing Guide

## Prerequisites

Before testing DNS-Update, ensure you have:

### 1. Required PowerShell Modules

Install these modules if not already installed:

```powershell
# Install DnsServer module (usually pre-installed on Windows Server with DNS role)
Install-Module -Name DnsServer -Force

# Install ImportExcel module
Install-Module -Name ImportExcel -Force
```

### 2. System Requirements

- Windows Server with DNS role installed
- Domain member with DNS update rights
- PowerShell 5.1 or later
- Network access to DNS server (default: eit-priaddc00)

### 3. Permissions

- Read/write access to the DNS-Update directory
- DNS update permissions on the target DNS server
- Ability to create/modify DNS records

---

## Quick Start Testing

### Step 1: Navigate to the DNS-Update Directory

```powershell
cd C:\path\to\DNS-Update
```

### Step 2: Run the Program (First Time)

```powershell
.\DNS-Update.ps1
```

**What happens on first run:**
1. Creates `config/DNS-Update.ini` with default settings
2. Creates `logs/` directory
3. Creates `DNS_Validation.xlsx` with your local hostname and IP
4. Validates DNS connectivity
5. Processes the sample spreadsheet
6. Saves results

### Step 3: Check the Results

After the first run, you should see:
- `config/DNS-Update.ini` - Configuration file
- `logs/DNS-Update_YYYYMMDD-HH-MM.log` - Log file
- `DNS_Validation.xlsx` - Spreadsheet with validation results

---

## Configuration File

The INI file is automatically created at `config/DNS-Update.ini` with these defaults:

```ini
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
```

### Important Configuration Notes

- **ReadOnlyMode=true** is the default for safety - no DNS changes will be made
- Change to **ReadOnlyMode=false** when ready to make actual DNS updates
- Update **Server** to match your DNS server name
- Update **DomainSuffix** to match your domain

---

## Testing Scenarios

### Scenario 1: Read-Only Validation (Safe Testing)

This is the default mode - validates DNS without making changes.

```powershell
.\DNS-Update.ps1
```

**Expected behavior:**
- Validates all DNS entries
- Shows what would be updated (if FIX commands exist)
- Does NOT make any DNS changes
- Status shows "ReadOnly" for FIX commands

### Scenario 2: Custom Spreadsheet

```powershell
.\DNS-Update.ps1 -SpreadsheetPath "MyCustomDNS.xlsx"
```

### Scenario 3: View Help

```powershell
.\DNS-Update.ps1 -Help
```

### Scenario 4: Making Actual DNS Updates

**WARNING: This will make real DNS changes!**

1. Edit `config/DNS-Update.ini` and set:
   ```ini
   ReadOnlyMode=false
   ```

2. Add "FIX" to validation cells in your spreadsheet where you want updates

3. Run the program:
   ```powershell
   .\DNS-Update.ps1
   ```

4. Review the confirmation prompt showing all changes

5. Type "Y" to proceed or "N" to cancel

---

## Spreadsheet Format

Your Excel spreadsheet must have these columns (order doesn't matter):

| Column Name | Description | Example |
|-------------|-------------|---------|
| Hostname | Server hostname (short or FQDN) | server01 or server01.tgna.tegna.com |
| IP Address | IPv4 address | 10.1.2.3 |
| Forward DNS Success | Validation result or "FIX" | YES, NO, FAIL, MULTIPLE, or FIX |
| Forward DNS Resolved IP | IP resolved from DNS | 10.1.2.3 |
| Reverse DNS Success | Validation result or "FIX" | YES, NO, FAIL, MULTIPLE, or FIX |
| Reverse DNS Hostname | Hostname resolved from DNS | server01.tgna.tegna.com |
| Status | Last action taken | Validated, Updated, Skipped, Failed, MULTIPLE |

### Validation Results

- **YES** - DNS record matches spreadsheet
- **NO** - DNS record exists but doesn't match
- **FAIL** - DNS zone not found or query failed
- **MULTIPLE** - Multiple DNS records exist (ambiguous)
- **FIX** - User command to update this record

### Status Values

- **Validated** - Row was validated successfully
- **Updated** - DNS record was updated
- **Skipped** - Row had empty hostname or IP
- **Failed** - Update operation failed
- **MULTIPLE** - Multiple records exist (cannot update)
- **ReadOnly** - Would have updated (read-only mode)

---

## Testing Workflow

### Phase 1: Initial Validation (Read-Only)

1. Ensure `ReadOnlyMode=true` in config
2. Create or edit your spreadsheet with DNS entries
3. Run: `.\DNS-Update.ps1`
4. Review validation results in spreadsheet
5. Check log file for details

### Phase 2: Mark Records for Update

1. Open the spreadsheet
2. Find rows with "NO" in validation columns
3. Replace "NO" with "FIX" for records you want to update
4. Save the spreadsheet

### Phase 3: Test Updates (Read-Only)

1. Keep `ReadOnlyMode=true`
2. Run: `.\DNS-Update.ps1`
3. Review what would be updated
4. Verify the changes look correct

### Phase 4: Make Actual Updates

1. Set `ReadOnlyMode=false` in config
2. Run: `.\DNS-Update.ps1`
3. Review the confirmation prompt
4. Type "Y" to proceed
5. Check results in spreadsheet and log

### Phase 5: Verify Updates

1. Set `ReadOnlyMode=true` again
2. Clear validation cells (or delete them)
3. Run: `.\DNS-Update.ps1`
4. Verify all records now show "YES"

---

## Troubleshooting

### Error: "DnsServer PowerShell module is not available"

**Solution:**
```powershell
Install-Module -Name DnsServer -Force
```

### Error: "ImportExcel PowerShell module is not available"

**Solution:**
```powershell
Install-Module -Name ImportExcel -Force
```

### Error: "DNS connectivity validation failed"

**Possible causes:**
- DNS server name is incorrect in config
- Network connectivity issues
- DNS server is not accessible
- Insufficient permissions

**Solution:**
1. Check DNS server name in `config/DNS-Update.ini`
2. Test connectivity: `Test-Connection eit-priaddc00`
3. Verify DNS role is installed on target server

### Error: "Missing required columns"

**Solution:**
Ensure your spreadsheet has all required columns:
- Hostname
- IP Address
- Forward DNS Success
- Forward DNS Resolved IP
- Reverse DNS Success
- Reverse DNS Hostname

### Error: "Zone not found"

**Possible causes:**
- DNS zone doesn't exist on server
- Hostname/IP doesn't match any zone
- Insufficient permissions to query zones

**Solution:**
1. Verify DNS zones exist on server
2. Check domain suffix in config matches your zones
3. Verify permissions to query DNS

---

## Log Files

Log files are created in `logs/` directory with format:
```
DNS-Update_YYYYMMDD-HH-MM.log
```

Example: `DNS-Update_20240224-14-30.log`

Log entries include:
- Program start/stop
- Configuration loaded
- DNS queries and results
- DNS updates and results
- Errors and warnings
- Action summaries

---

## Backup Files

When FIX commands are executed, backups are created in `logs/` directory:

```
DNS_Backup_YYYYMMDD-HH-MM.xlsx
DNS_Backup_YYYYMMDD-HH-MM.csv
DNS_Backup_YYYYMMDD-HH-MM.xml
```

These backups contain the spreadsheet data before any DNS changes.

---

## Safety Features

1. **Read-Only Mode (Default)**: No DNS changes until you explicitly disable it
2. **Confirmation Prompt**: Shows all changes before applying them
3. **Update Limit**: Maximum 5 updates per run (configurable)
4. **Automatic Backups**: Created before any DNS changes
5. **Multiple Record Detection**: Won't update if multiple records exist
6. **Zone Validation**: Verifies DNS zone exists before updates

---

## Common Testing Patterns

### Pattern 1: Validate Existing DNS

```powershell
# Create spreadsheet with your DNS entries
# Run validation
.\DNS-Update.ps1

# Check results - all should be YES if DNS is correct
```

### Pattern 2: Fix Mismatched Records

```powershell
# Run validation
.\DNS-Update.ps1

# Edit spreadsheet - change "NO" to "FIX"
# Test in read-only mode
.\DNS-Update.ps1

# Make actual changes
# Edit config: ReadOnlyMode=false
.\DNS-Update.ps1
```

### Pattern 3: Iterative Validation

```powershell
# Run multiple times until all records are YES
.\DNS-Update.ps1
# Fix issues in spreadsheet or DNS
.\DNS-Update.ps1
# Repeat until clean
```

---

## Next Steps

After successful testing:

1. Review the implementation in `src/` directory
2. Run unit tests in `tests/` directory
3. Create custom spreadsheets for your environment
4. Adjust configuration for your DNS server
5. Consider creating a scheduled task for regular validation

---

## Support

For issues or questions:
- Check log files in `logs/` directory
- Review error messages in console output
- Verify prerequisites are met
- Check DNS server connectivity and permissions

Author: Mark Oldham
Version: 0.0.1
Compile Date: 2024-02-24
