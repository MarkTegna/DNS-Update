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
        
        # Check if we have commands
        if ($null -eq $fixCommands -or $fixCommands.Count -eq 0) {
            Write-Host "  (No FIX commands to display)" -ForegroundColor Gray
        } else {
            # Display each command
            for ($i = 0; $i -lt $fixCommands.Count; $i++) {
                $cmd = $fixCommands[$i]
                $rowNum = $cmd.RowNumber + 1
                $type = $cmd.RecordType
                $host = $cmd.Hostname
                $ip = $cmd.IpAddress
                $zone = $cmd.Zone
                Write-Host "  Row ${rowNum}: ${type} record - ${host} -> ${ip} (Zone: ${zone})" -ForegroundColor Cyan
            }
        }
        
        Write-Host ""
    }
    
    # Get user confirmation (Y/N prompt)
    [bool] GetUserConfirmation() {
        $response = Read-Host "Do you want to proceed with these updates? (Y/N)"
        
        # Case-insensitive comparison
        return ($response -match '^[Yy]$')
    }
}
