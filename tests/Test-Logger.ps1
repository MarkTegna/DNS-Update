# Test-Logger.ps1
# Unit tests for Logger component

# Import the Logger class
. "$PSScriptRoot\..\src\Logger.ps1"

Describe "Logger Component Tests" {
    BeforeEach {
        # Create temporary test directory
        $script:testLogDir = Join-Path -Path $TestDrive -ChildPath "test_logs"
        if (Test-Path $script:testLogDir) {
            Remove-Item -Path $script:testLogDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $script:testLogDir -Force | Out-Null
    }
    
    AfterEach {
        # Clean up test directory
        if (Test-Path $script:testLogDir) {
            Remove-Item -Path $script:testLogDir -Recurse -Force
        }
    }
    
    Context "Logger Initialization" {
        It "Should create log directory if it doesn't exist" {
            $logger = [Logger]::new()
            $logger.Initialize($script:testLogDir)
            
            Test-Path -Path $script:testLogDir | Should Be $true
        }
        
        It "Should create log file with correct timestamp format YYYYMMDD-HH-MM" {
            $logger = [Logger]::new()
            $logger.Initialize($script:testLogDir)
            
            # Check that log file exists
            $logger.LogFilePath | Should Not BeNullOrEmpty
            Test-Path -Path $logger.LogFilePath | Should Be $true
            
            # Verify filename format (DNS-Update_YYYYMMDD-HH-MM.log)
            $filename = Split-Path -Path $logger.LogFilePath -Leaf
            $filename | Should Match '^DNS-Update_\d{8}-\d{2}-\d{2}\.log$'
        }
        
        It "Should write initialization message to log file" {
            $logger = [Logger]::new()
            $logger.Initialize($script:testLogDir)
            
            $logContent = Get-Content -Path $logger.LogFilePath -Raw
            $logContent | Should Match "Logger initialized"
        }
    }
    
    Context "Log Entry Format" {
        It "Should format log entries with timestamp and level" {
            $logger = [Logger]::new()
            $logger.Initialize($script:testLogDir)
            
            $logger.LogInfo("Test message")
            
            $logContent = Get-Content -Path $logger.LogFilePath
            $lastEntry = $logContent[-1]
            
            # Verify format: [YYYY-MM-DD HH:MM:SS] [LEVEL] Message
            $lastEntry | Should Match '^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[INFO\] Test message$'
        }
        
        It "Should use 24-hour time format in log entries" {
            $logger = [Logger]::new()
            $logger.Initialize($script:testLogDir)
            
            $logger.LogInfo("Time format test")
            
            $logContent = Get-Content -Path $logger.LogFilePath
            $lastEntry = $logContent[-1]
            
            # Extract time portion and verify it's in 24-hour format (00-23)
            if ($lastEntry -match '\[(\d{4}-\d{2}-\d{2} (\d{2}):\d{2}:\d{2})\]') {
                $hour = [int]$matches[2]
                ($hour -ge 0 -and $hour -le 23) | Should Be $true
            }
        }
        
        It "Should replace Unicode characters with ASCII equivalents" {
            $logger = [Logger]::new()
            $logger.Initialize($script:testLogDir)
            
            # Log message with Unicode box-drawing characters
            $unicodeMessage = "Test " + [char]0x2551 + " " + [char]0x2554 + " message"
            $logger.LogInfo($unicodeMessage)
            
            $logContent = Get-Content -Path $logger.LogFilePath -Encoding ASCII
            $lastEntry = $logContent[-1]
            
            # Verify Unicode characters were replaced (should contain ?)
            $lastEntry | Should Match '\?'
        }
    }
    
    Context "Log Methods" {
        BeforeEach {
            $script:logger = [Logger]::new()
            $script:logger.Initialize($script:testLogDir)
        }
        
        It "LogInfo should write INFO level messages" {
            $script:logger.LogInfo("Information message")
            
            $logContent = Get-Content -Path $script:logger.LogFilePath
            $lastEntry = $logContent[-1]
            
            $lastEntry | Should Match '\[INFO\] Information message'
        }
        
        It "LogError should write ERROR level messages" {
            $script:logger.LogError("Error message")
            
            $logContent = Get-Content -Path $script:logger.LogFilePath
            $lastEntry = $logContent[-1]
            
            $lastEntry | Should Match '\[ERROR\] Error message'
        }
        
        It "LogQuery should format DNS query messages correctly" {
            $script:logger.LogQuery("Forward DNS", "server01.tgna.tegna.com", "10.1.2.3 (YES)")
            
            $logContent = Get-Content -Path $script:logger.LogFilePath
            $lastEntry = $logContent[-1]
            
            $lastEntry | Should Match '\[QUERY\] Forward DNS query: server01\.tgna\.tegna\.com -> 10\.1\.2\.3 \(YES\)'
        }
        
        It "LogUpdate should format DNS update messages correctly" {
            $script:logger.LogUpdate("A", "server02.tgna.tegna.com -> 10.1.2.4", "SUCCESS")
            
            $logContent = Get-Content -Path $script:logger.LogFilePath
            $lastEntry = $logContent[-1]
            
            $lastEntry | Should Match '\[UPDATE\] A record: server02\.tgna\.tegna\.com -> 10\.1\.2\.4 -> SUCCESS'
        }
        
        It "LogAction should format action messages correctly" {
            $script:logger.LogAction("Update limit reached", "5 updates completed, skipping remaining FIX commands")
            
            $logContent = Get-Content -Path $script:logger.LogFilePath
            $lastEntry = $logContent[-1]
            
            $lastEntry | Should Match '\[ACTION\] Update limit reached - 5 updates completed, skipping remaining FIX commands'
        }
    }
    
    Context "Multiple Log Entries" {
        It "Should append multiple log entries to the same file" {
            $logger = [Logger]::new()
            $logger.Initialize($script:testLogDir)
            
            $logger.LogInfo("First message")
            $logger.LogError("Second message")
            $logger.LogQuery("Forward DNS", "test.com", "1.2.3.4")
            
            $logContent = Get-Content -Path $logger.LogFilePath
            
            # Should have 4 entries (initialization + 3 test messages)
            ($logContent.Count -ge 4) | Should Be $true
            
            # Verify all messages are present
            ($logContent -join "`n") | Should Match "First message"
            ($logContent -join "`n") | Should Match "Second message"
            ($logContent -join "`n") | Should Match "test\.com"
        }
    }
    
    Context "Log File Location" {
        It "Should create log file in specified directory" {
            $customLogDir = Join-Path -Path $TestDrive -ChildPath "custom_logs"
            
            $logger = [Logger]::new()
            $logger.Initialize($customLogDir)
            
            $logger.LogFilePath | Should Match ([regex]::Escape($customLogDir))
            Test-Path -Path $logger.LogFilePath | Should Be $true
        }
    }
}
