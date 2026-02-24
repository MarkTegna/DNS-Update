# BackupManager.ps1
# Creates backup exports before DNS changes
# Author: Mark Oldham
# Requirements: 4.1, 4.2, 4.3

class BackupManager {
    [string] $LogDirectory
    
    BackupManager([string] $logDirectory) {
        $this.LogDirectory = $logDirectory
    }
    
    # Generate timestamp in format YYYYMMDD-HH-MM (24-hour)
    [string] GenerateTimestamp() {
        return Get-Date -Format "yyyyMMdd-HH-mm"
    }
    
    # Export data to Excel format
    [void] ExportToExcel([object] $data, [string] $filePath) {
        try {
            $data | Export-Excel -Path $filePath -AutoSize -AutoFilter
        }
        catch {
            throw "Failed to export to Excel: $_"
        }
    }
    
    # Export data to CSV format
    [void] ExportToCsv([object] $data, [string] $filePath) {
        try {
            $data | Export-Csv -Path $filePath -NoTypeInformation
        }
        catch {
            throw "Failed to export to CSV: $_"
        }
    }
    
    # Export data to PowerShell Clixml format
    [void] ExportToClixml([object] $data, [string] $filePath) {
        try {
            $data | Export-Clixml -Path $filePath
        }
        catch {
            throw "Failed to export to Clixml: $_"
        }
    }
    
    # Create all three backup formats
    # Requirements: 4.1, 4.2, 4.3
    [void] CreateBackups([object] $worksheetData, [string] $dnsServer) {
        if ($null -eq $worksheetData) {
            throw "No worksheet data provided for backup"
        }
        
        # Ensure log directory exists
        if (-not (Test-Path -Path $this.LogDirectory)) {
            New-Item -ItemType Directory -Path $this.LogDirectory -Force | Out-Null
        }
        
        # Generate timestamp for backup filenames
        $timestamp = $this.GenerateTimestamp()
        
        # Define backup file paths with format: DNS_Backup_YYYYMMDD-HH-MM.<extension>
        $excelBackup = Join-Path -Path $this.LogDirectory -ChildPath "DNS_Backup_$timestamp.xlsx"
        $csvBackup = Join-Path -Path $this.LogDirectory -ChildPath "DNS_Backup_$timestamp.csv"
        $clixmlBackup = Join-Path -Path $this.LogDirectory -ChildPath "DNS_Backup_$timestamp.xml"
        
        try {
            # Create Excel backup
            $this.ExportToExcel($worksheetData, $excelBackup)
            
            # Create CSV backup
            $this.ExportToCsv($worksheetData, $csvBackup)
            
            # Create Clixml backup
            $this.ExportToClixml($worksheetData, $clixmlBackup)
            
            Write-Host "Backups created successfully:" -ForegroundColor Green
            Write-Host "  - Excel: $excelBackup" -ForegroundColor Gray
            Write-Host "  - CSV: $csvBackup" -ForegroundColor Gray
            Write-Host "  - XML: $clixmlBackup" -ForegroundColor Gray
        }
        catch {
            throw "Failed to create backups: $_"
        }
    }
}
