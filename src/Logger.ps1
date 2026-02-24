# Logger.ps1
# Provides logging functionality for DNS-Update program
# Author: Mark Oldham

class Logger {
    [string] $LogFilePath
    
    # Initialize logger with log directory
    [void] Initialize([string] $logDirectory) {
        # Create log directory if it doesn't exist
        if (-not (Test-Path -Path $logDirectory)) {
            New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
        }
        
        # Generate timestamp for log filename (YYYYMMDD-HH-MM format, 24-hour)
        $timestamp = Get-Date -Format "yyyyMMdd-HH-mm"
        $this.LogFilePath = Join-Path -Path $logDirectory -ChildPath "DNS-Update_$timestamp.log"
        
        # Create log file
        $this.LogInfo("Logger initialized")
    }
    
    # Write formatted log entry to file
    hidden [void] WriteLog([string] $level, [string] $message) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$level] $message"
        
        # Ensure ASCII-only output (replace Unicode characters)
        $logEntry = $logEntry -replace '[^\x00-\x7F]', '?'
        
        Add-Content -Path $this.LogFilePath -Value $logEntry -Encoding ASCII
    }
    
    # Log informational message
    [void] LogInfo([string] $message) {
        $this.WriteLog("INFO", $message)
    }
    
    # Log error message
    [void] LogError([string] $message) {
        $this.WriteLog("ERROR", $message)
    }
    
    # Log DNS query operation
    [void] LogQuery([string] $queryType, [string] $target, [string] $result) {
        $message = "$queryType query: $target -> $result"
        $this.WriteLog("QUERY", $message)
    }
    
    # Log DNS update operation
    [void] LogUpdate([string] $recordType, [string] $target, [string] $result) {
        $message = "$recordType record: $target -> $result"
        $this.WriteLog("UPDATE", $message)
    }
    
    # Log action taken by program
    [void] LogAction([string] $action, [string] $details) {
        $message = "$action - $details"
        $this.WriteLog("ACTION", $message)
    }
}
