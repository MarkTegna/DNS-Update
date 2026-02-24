# ProgressDisplay.ps1
# Provides progress display and user confirmation functionality for DNS-Update program
# Author: Mark Oldham

class ProgressDisplay {
    [int] $TotalRows
    [int] $CurrentRow
    
    # Initialize progress display with total row count
    [void] Initialize([int] $totalRows) {
        $this.TotalRows = $totalRows
        $this.CurrentRow = 0
    }
    
    # Update progress display (only shows if more than 10 rows)
    [void] UpdateProgress([int] $currentRow) {
        $this.CurrentRow = $currentRow
        
        # Only show progress if more than 10 rows
        if ($this.TotalRows -gt 10) {
            $percentComplete = [math]::Round(($currentRow / $this.TotalRows) * 100, 0)
            Write-Progress -Activity "Processing DNS Records" `
                           -Status "Processing row $currentRow of $($this.TotalRows)" `
                           -PercentComplete $percentComplete
        }
    }
    
    # Show confirmation prompt with FIX commands in table format
    [void] ShowConfirmation([array] $fixCommands) {
        Write-Host ""
        Write-Host "The following DNS records will be updated:" -ForegroundColor Yellow
        Write-Host ""
        
        # Create table data with ASCII-only characters
        $tableData = $fixCommands | ForEach-Object {
            [PSCustomObject]@{
                Row = $_.RowNumber
                Type = $_.RecordType
                Hostname = $_.Hostname
                IPAddress = $_.IpAddress
                Zone = $_.Zone
            }
        }
        
        # Display table using Format-Table
        $tableData | Format-Table -AutoSize
        
        Write-Host ""
    }
    
    # Get user confirmation (Y/N prompt)
    [bool] GetUserConfirmation() {
        $response = Read-Host "Do you want to proceed with these updates? (Y/N)"
        
        # Case-insensitive comparison
        return ($response -match '^[Yy]$')
    }
}
