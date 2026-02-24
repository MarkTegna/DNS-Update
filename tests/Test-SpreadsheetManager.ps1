# Test-SpreadsheetManager.ps1
# Unit tests for SpreadsheetManager class
# Author: Mark Oldham

# Import the SpreadsheetManager class
. "$PSScriptRoot\..\src\SpreadsheetManager.ps1"

Describe "SpreadsheetManager Unit Tests" {
    BeforeAll {
        # Create a test directory for temporary files
        $script:TestDir = Join-Path $TestDrive "SpreadsheetTests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
    }
    
    Context "FileExists Method" {
        It "Should return true for existing file" {
            $testFile = Join-Path $script:TestDir "test.xlsx"
            "test" | Out-File -FilePath $testFile
            
            $manager = [SpreadsheetManager]::new()
            $result = $manager.FileExists($testFile)
            
            $result | Should Be $true
        }
        
        It "Should return false for non-existing file" {
            $testFile = Join-Path $script:TestDir "nonexistent.xlsx"
            
            $manager = [SpreadsheetManager]::new()
            $result = $manager.FileExists($testFile)
            
            $result | Should Be $false
        }
    }
    
    Context "LoadSpreadsheet Method" {
        It "Should throw error for non-existing file" {
            $testFile = Join-Path $script:TestDir "nonexistent.xlsx"
            
            $manager = [SpreadsheetManager]::new()
            
            $errorThrown = $false
            try {
                $manager.LoadSpreadsheet($testFile)
            } catch {
                $errorThrown = $true
            }
            
            $errorThrown | Should Be $true
        }
        
        It "Should load spreadsheet with required columns" {
            # Create a test spreadsheet with required columns
            $testFile = Join-Path $script:TestDir "valid.xlsx"
            $testData = @(
                [PSCustomObject]@{
                    'Hostname' = 'server01'
                    'IP Address' = '10.1.2.3'
                    'Forward DNS Success' = ''
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                    'Reverse DNS Hostname' = ''
                }
            )
            $testData | Export-Excel -Path $testFile -AutoSize
            
            $manager = [SpreadsheetManager]::new()
            $manager.LoadSpreadsheet($testFile)
            
            $manager.WorksheetData | Should Not BeNullOrEmpty
            ($manager.ColumnMapping.Count -gt 0) | Should Be $true
        }
        
        It "Should throw error for missing required columns" {
            # Create a test spreadsheet missing required columns
            $testFile = Join-Path $script:TestDir "invalid.xlsx"
            $testData = @(
                [PSCustomObject]@{
                    'Hostname' = 'server01'
                    'IP Address' = '10.1.2.3'
                }
            )
            $testData | Export-Excel -Path $testFile -AutoSize
            
            $manager = [SpreadsheetManager]::new()
            
            $errorThrown = $false
            try {
                $manager.LoadSpreadsheet($testFile)
            } catch {
                $errorThrown = $true
            }
            
            $errorThrown | Should Be $true
        }
    }
    
    Context "MapColumns Method" {
        It "Should map all required columns" {
            $testFile = Join-Path $script:TestDir "maptest.xlsx"
            $testData = @(
                [PSCustomObject]@{
                    'Hostname' = 'server01'
                    'IP Address' = '10.1.2.3'
                    'Forward DNS Success' = ''
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                    'Reverse DNS Hostname' = ''
                }
            )
            $testData | Export-Excel -Path $testFile -AutoSize
            
            $manager = [SpreadsheetManager]::new()
            $manager.LoadSpreadsheet($testFile)
            
            $manager.ColumnMapping.ContainsKey('Hostname') | Should Be $true
            $manager.ColumnMapping.ContainsKey('IP Address') | Should Be $true
            $manager.ColumnMapping.ContainsKey('Forward DNS Success') | Should Be $true
        }
        
        It "Should handle columns in different order" {
            $testFile = Join-Path $script:TestDir "ordertest.xlsx"
            $testData = @(
                [PSCustomObject]@{
                    'Forward DNS Success' = ''
                    'Hostname' = 'server01'
                    'Reverse DNS Hostname' = ''
                    'IP Address' = '10.1.2.3'
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                }
            )
            $testData | Export-Excel -Path $testFile -AutoSize
            
            $manager = [SpreadsheetManager]::new()
            $manager.LoadSpreadsheet($testFile)
            
            ($manager.ColumnMapping.Count -ge 6) | Should Be $true
        }
    }
    
    Context "GetRows Method" {
        It "Should return all rows from spreadsheet" {
            $testFile = Join-Path $script:TestDir "rowstest.xlsx"
            $testData = @(
                [PSCustomObject]@{
                    'Hostname' = 'server01'
                    'IP Address' = '10.1.2.3'
                    'Forward DNS Success' = ''
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                    'Reverse DNS Hostname' = ''
                },
                [PSCustomObject]@{
                    'Hostname' = 'server02'
                    'IP Address' = '10.1.2.4'
                    'Forward DNS Success' = ''
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                    'Reverse DNS Hostname' = ''
                }
            )
            $testData | Export-Excel -Path $testFile -AutoSize
            
            $manager = [SpreadsheetManager]::new()
            $manager.LoadSpreadsheet($testFile)
            
            $rows = $manager.GetRows()
            $rows.Count | Should Be 2
        }
        
        It "Should return empty array when no data loaded" {
            $manager = [SpreadsheetManager]::new()
            $rows = $manager.GetRows()
            
            $rows.Count | Should Be 0
        }
    }
    
    Context "GetCellValue Method" {
        It "Should return correct cell value" {
            $testFile = Join-Path $script:TestDir "celltest.xlsx"
            $testData = @(
                [PSCustomObject]@{
                    'Hostname' = 'server01'
                    'IP Address' = '10.1.2.3'
                    'Forward DNS Success' = 'YES'
                    'Forward DNS Resolved IP' = '10.1.2.3'
                    'Reverse DNS Success' = 'NO'
                    'Reverse DNS Hostname' = 'other.server'
                }
            )
            $testData | Export-Excel -Path $testFile -AutoSize
            
            $manager = [SpreadsheetManager]::new()
            $manager.LoadSpreadsheet($testFile)
            
            $value = $manager.GetCellValue(0, 'Hostname')
            $value | Should Be 'server01'
            
            $value = $manager.GetCellValue(0, 'Forward DNS Success')
            $value | Should Be 'YES'
        }
        
        It "Should return empty string for null values" {
            $testFile = Join-Path $script:TestDir "nulltest.xlsx"
            $testData = @(
                [PSCustomObject]@{
                    'Hostname' = 'server01'
                    'IP Address' = '10.1.2.3'
                    'Forward DNS Success' = ''
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                    'Reverse DNS Hostname' = ''
                }
            )
            $testData | Export-Excel -Path $testFile -AutoSize
            
            $manager = [SpreadsheetManager]::new()
            $manager.LoadSpreadsheet($testFile)
            
            $value = $manager.GetCellValue(0, 'Forward DNS Success')
            $value | Should Be ''
        }
        
        It "Should throw error for invalid row index" {
            $testFile = Join-Path $script:TestDir "invalidrow.xlsx"
            $testData = @(
                [PSCustomObject]@{
                    'Hostname' = 'server01'
                    'IP Address' = '10.1.2.3'
                    'Forward DNS Success' = ''
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                    'Reverse DNS Hostname' = ''
                }
            )
            $testData | Export-Excel -Path $testFile -AutoSize
            
            $manager = [SpreadsheetManager]::new()
            $manager.LoadSpreadsheet($testFile)
            
            $errorThrown = $false
            try {
                $manager.GetCellValue(10, 'Hostname')
            } catch {
                $errorThrown = $true
            }
            
            $errorThrown | Should Be $true
        }
    }
    
    Context "UpdateCell Method" {
        It "Should update existing cell value" {
            $testFile = Join-Path $script:TestDir "updatetest.xlsx"
            $testData = @(
                [PSCustomObject]@{
                    'Hostname' = 'server01'
                    'IP Address' = '10.1.2.3'
                    'Forward DNS Success' = ''
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                    'Reverse DNS Hostname' = ''
                }
            )
            $testData | Export-Excel -Path $testFile -AutoSize
            
            $manager = [SpreadsheetManager]::new()
            $manager.LoadSpreadsheet($testFile)
            
            $manager.UpdateCell(0, 'Forward DNS Success', 'YES')
            $value = $manager.GetCellValue(0, 'Forward DNS Success')
            
            $value | Should Be 'YES'
        }
        
        It "Should add new column if it doesn't exist" {
            $testFile = Join-Path $script:TestDir "newcoltest.xlsx"
            $testData = @(
                [PSCustomObject]@{
                    'Hostname' = 'server01'
                    'IP Address' = '10.1.2.3'
                    'Forward DNS Success' = ''
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                    'Reverse DNS Hostname' = ''
                }
            )
            $testData | Export-Excel -Path $testFile -AutoSize
            
            $manager = [SpreadsheetManager]::new()
            $manager.LoadSpreadsheet($testFile)
            
            $manager.UpdateCell(0, 'Status', 'Validated')
            $value = $manager.GetCellValue(0, 'Status')
            
            $value | Should Be 'Validated'
            $manager.ColumnMapping.ContainsKey('Status') | Should Be $true
        }
    }
    
    Context "SaveSpreadsheet Method" {
        It "Should save spreadsheet to file" {
            $testFile = Join-Path $script:TestDir "savetest.xlsx"
            $outputFile = Join-Path $script:TestDir "savetest_output.xlsx"
            
            $testData = @(
                [PSCustomObject]@{
                    'Hostname' = 'server01'
                    'IP Address' = '10.1.2.3'
                    'Forward DNS Success' = ''
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                    'Reverse DNS Hostname' = ''
                }
            )
            $testData | Export-Excel -Path $testFile -AutoSize
            
            $manager = [SpreadsheetManager]::new()
            $manager.LoadSpreadsheet($testFile)
            $manager.UpdateCell(0, 'Forward DNS Success', 'YES')
            $manager.SaveSpreadsheet($outputFile)
            
            Test-Path $outputFile | Should Be $true
            
            # Verify the saved data
            $savedData = Import-Excel -Path $outputFile
            $savedData[0].'Forward DNS Success' | Should Be 'YES'
        }
    }
    
    Context "CreateSampleSpreadsheet Method" {
        It "Should create a sample spreadsheet with required columns" {
            $testFile = Join-Path $script:TestDir "sample.xlsx"
            
            # Remove file if it exists
            if (Test-Path $testFile) {
                Remove-Item $testFile -Force
            }
            
            $manager = [SpreadsheetManager]::new()
            $manager.CreateSampleSpreadsheet($testFile)
            
            # Verify file was created
            Test-Path $testFile | Should Be $true
            
            # Load and verify the sample data
            $sampleData = Import-Excel -Path $testFile
            # Import-Excel returns a single object (not array) for one row
            if ($sampleData -isnot [array]) {
                $sampleData = @($sampleData)
            }
            $sampleData.Count | Should Be 1
            
            # Verify all required columns exist
            $sampleData[0].PSObject.Properties.Name -contains 'Hostname' | Should Be $true
            $sampleData[0].PSObject.Properties.Name -contains 'IP Address' | Should Be $true
            $sampleData[0].PSObject.Properties.Name -contains 'Forward DNS Success' | Should Be $true
            $sampleData[0].PSObject.Properties.Name -contains 'Forward DNS Resolved IP' | Should Be $true
            $sampleData[0].PSObject.Properties.Name -contains 'Reverse DNS Success' | Should Be $true
            $sampleData[0].PSObject.Properties.Name -contains 'Reverse DNS Hostname' | Should Be $true
        }
        
        It "Should populate sample spreadsheet with local host information" {
            $testFile = Join-Path $script:TestDir "sample_populated.xlsx"
            
            # Remove file if it exists
            if (Test-Path $testFile) {
                Remove-Item $testFile -Force
            }
            
            $manager = [SpreadsheetManager]::new()
            $manager.CreateSampleSpreadsheet($testFile)
            
            # Load the sample data
            $sampleData = Import-Excel -Path $testFile
            # Import-Excel returns a single object (not array) for one row
            if ($sampleData -isnot [array]) {
                $sampleData = @($sampleData)
            }
            
            # Verify hostname is populated (should not be empty)
            $sampleData[0].Hostname | Should Not BeNullOrEmpty
            
            # Verify IP address property exists (value might be empty if no valid IP found)
            $sampleData[0].PSObject.Properties.Name -contains 'IP Address' | Should Be $true
        }
        
        It "Should get local hostname using hostname command" {
            $testFile = Join-Path $script:TestDir "sample_hostname.xlsx"
            
            # Remove file if it exists
            if (Test-Path $testFile) {
                Remove-Item $testFile -Force
            }
            
            # Get expected hostname
            $expectedHostname = hostname
            
            $manager = [SpreadsheetManager]::new()
            $manager.CreateSampleSpreadsheet($testFile)
            
            # Load the sample data
            $sampleData = Import-Excel -Path $testFile
            # Import-Excel returns a single object (not array) for one row
            if ($sampleData -isnot [array]) {
                $sampleData = @($sampleData)
            }
            
            # Verify hostname matches
            $sampleData[0].Hostname | Should Be $expectedHostname
        }
        
        It "Should get local IP address using Get-NetIPAddress" {
            $testFile = Join-Path $script:TestDir "sample_ip.xlsx"
            
            # Remove file if it exists
            if (Test-Path $testFile) {
                Remove-Item $testFile -Force
            }
            
            # Get expected IP address (first non-loopback IPv4)
            $expectedIp = ""
            $netIpAddresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
                $_.IPAddress -ne '127.0.0.1' -and $_.PrefixOrigin -ne 'WellKnown' 
            }
            if ($netIpAddresses -and $netIpAddresses.Count -gt 0) {
                $expectedIp = $netIpAddresses[0].IPAddress
            }
            
            $manager = [SpreadsheetManager]::new()
            $manager.CreateSampleSpreadsheet($testFile)
            
            # Load the sample data
            $sampleData = Import-Excel -Path $testFile
            # Import-Excel returns a single object (not array) for one row
            if ($sampleData -isnot [array]) {
                $sampleData = @($sampleData)
            }
            
            # Verify IP address matches
            $sampleData[0].'IP Address' | Should Be $expectedIp
        }
    }
    
    Context "AddStatusColumn Method" {
        It "Should add Status column if it doesn't exist" {
            $testFile = Join-Path $script:TestDir "statustest.xlsx"
            $testData = @(
                [PSCustomObject]@{
                    'Hostname' = 'server01'
                    'IP Address' = '10.1.2.3'
                    'Forward DNS Success' = ''
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                    'Reverse DNS Hostname' = ''
                }
            )
            $testData | Export-Excel -Path $testFile -AutoSize
            
            $manager = [SpreadsheetManager]::new()
            $manager.LoadSpreadsheet($testFile)
            
            # Verify Status column doesn't exist initially
            $manager.ColumnMapping.ContainsKey('Status') | Should Be $false
            
            # Add Status column
            $manager.AddStatusColumn()
            
            # Verify Status column now exists
            $manager.ColumnMapping.ContainsKey('Status') | Should Be $true
            
            # Verify Status column is added to all rows with empty value
            $value = $manager.GetCellValue(0, 'Status')
            $value | Should Be ''
        }
        
        It "Should not duplicate Status column if it already exists" {
            $testFile = Join-Path $script:TestDir "statusexists.xlsx"
            $testData = @(
                [PSCustomObject]@{
                    'Hostname' = 'server01'
                    'IP Address' = '10.1.2.3'
                    'Forward DNS Success' = ''
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                    'Reverse DNS Hostname' = ''
                    'Status' = 'Validated'
                }
            )
            $testData | Export-Excel -Path $testFile -AutoSize
            
            $manager = [SpreadsheetManager]::new()
            $manager.LoadSpreadsheet($testFile)
            
            # Verify Status column exists
            $manager.ColumnMapping.ContainsKey('Status') | Should Be $true
            $initialValue = $manager.GetCellValue(0, 'Status')
            $initialValue | Should Be 'Validated'
            
            # Call AddStatusColumn again
            $manager.AddStatusColumn()
            
            # Verify Status column still exists with same value
            $manager.ColumnMapping.ContainsKey('Status') | Should Be $true
            $value = $manager.GetCellValue(0, 'Status')
            $value | Should Be 'Validated'
        }
        
        It "Should add Status column to multiple rows" {
            $testFile = Join-Path $script:TestDir "statusmulti.xlsx"
            $testData = @(
                [PSCustomObject]@{
                    'Hostname' = 'server01'
                    'IP Address' = '10.1.2.3'
                    'Forward DNS Success' = ''
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                    'Reverse DNS Hostname' = ''
                },
                [PSCustomObject]@{
                    'Hostname' = 'server02'
                    'IP Address' = '10.1.2.4'
                    'Forward DNS Success' = ''
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                    'Reverse DNS Hostname' = ''
                },
                [PSCustomObject]@{
                    'Hostname' = 'server03'
                    'IP Address' = '10.1.2.5'
                    'Forward DNS Success' = ''
                    'Forward DNS Resolved IP' = ''
                    'Reverse DNS Success' = ''
                    'Reverse DNS Hostname' = ''
                }
            )
            $testData | Export-Excel -Path $testFile -AutoSize
            
            $manager = [SpreadsheetManager]::new()
            $manager.LoadSpreadsheet($testFile)
            
            # Add Status column
            $manager.AddStatusColumn()
            
            # Verify Status column exists for all rows
            $manager.GetCellValue(0, 'Status') | Should Be ''
            $manager.GetCellValue(1, 'Status') | Should Be ''
            $manager.GetCellValue(2, 'Status') | Should Be ''
            
            # Update Status values
            $manager.UpdateCell(0, 'Status', 'Validated')
            $manager.UpdateCell(1, 'Status', 'Updated')
            $manager.UpdateCell(2, 'Status', 'Skipped')
            
            # Verify updated values
            $manager.GetCellValue(0, 'Status') | Should Be 'Validated'
            $manager.GetCellValue(1, 'Status') | Should Be 'Updated'
            $manager.GetCellValue(2, 'Status') | Should Be 'Skipped'
        }
        
        It "Should throw error when no worksheet data is loaded" {
            $manager = [SpreadsheetManager]::new()
            
            $errorThrown = $false
            try {
                $manager.AddStatusColumn()
            } catch {
                $errorThrown = $true
            }
            
            $errorThrown | Should Be $true
        }
    }
}
