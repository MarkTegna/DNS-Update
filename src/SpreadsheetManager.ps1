# SpreadsheetManager.ps1
# Manages Excel spreadsheet operations using ImportExcel module
# Author: Mark Oldham
# Requirements: 1.1, 1.2, 1.5, 1.6, 1.11

class SpreadsheetManager {
    [string] $FilePath
    [object] $WorksheetData
    [hashtable] $ColumnMapping
    
    # Required column names
    hidden [string[]] $RequiredColumns = @(
        'Hostname',
        'IP Address',
        'Forward DNS Success',
        'Forward DNS Resolved IP',
        'Reverse DNS Success',
        'Reverse DNS Hostname'
    )
    
    SpreadsheetManager() {
        $this.ColumnMapping = @{}
    }
    
    # Check if a file exists
    [bool] FileExists([string] $filePath) {
        return Test-Path -Path $filePath -PathType Leaf
    }
    
    # Check if a file is locked (open in another process like Excel)
    [bool] IsFileLocked([string] $filePath) {
        if (-not $this.FileExists($filePath)) {
            return $false
        }
        
        try {
            $fileStream = [System.IO.File]::Open($filePath, 'Open', 'ReadWrite', 'None')
            $fileStream.Close()
            $fileStream.Dispose()
            return $false
        }
        catch {
            return $true
        }
    }
    
    # Verify file can be accessed (not locked) before processing
    [void] VerifyFileAccess([string] $filePath) {
        if ($this.IsFileLocked($filePath)) {
            throw "File is locked (possibly open in Excel): $filePath. Please close the file and try again."
        }
    }
    
    # Create a sample spreadsheet with local host information
    # Requirements: 1.3, 1.4
    [void] CreateSampleSpreadsheet([string] $filePath) {
        try {
            # Get local hostname
            $hostname = hostname
            
            # Get local IP address (first non-loopback IPv4 address)
            $ipAddress = ""
            $netIpAddresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
                $_.IPAddress -ne '127.0.0.1' -and $_.PrefixOrigin -ne 'WellKnown' 
            }
            
            if ($netIpAddresses -and $netIpAddresses.Count -gt 0) {
                $ipAddress = $netIpAddresses[0].IPAddress
            }
            
            # Create sample data with required columns
            $sampleData = [PSCustomObject]@{
                'Hostname' = $hostname
                'IP Address' = $ipAddress
                'Forward DNS Success' = ''
                'Forward DNS Resolved IP' = ''
                'Reverse DNS Success' = ''
                'Reverse DNS Hostname' = ''
            }
            
            # Export to Excel file
            $sampleData | Export-Excel -Path $filePath -AutoSize -AutoFilter
            
        }
        catch {
            throw "Failed to create sample spreadsheet: $_"
        }
    }
    
    # Load spreadsheet from file using Import-Excel cmdlet
    [void] LoadSpreadsheet([string] $filePath) {
        if (-not $this.FileExists($filePath)) {
            throw "Spreadsheet file not found: $filePath"
        }
        
        # Verify file is not locked before attempting to load
        $this.VerifyFileAccess($filePath)
        
        try {
            $this.FilePath = $filePath
            $data = Import-Excel -Path $filePath
            
            # Ensure WorksheetData is always an array (Import-Excel returns single object for one row)
            if ($data -isnot [array]) {
                $this.WorksheetData = @($data)
            } else {
                $this.WorksheetData = $data
            }
            
            if ($null -eq $this.WorksheetData -or $this.WorksheetData.Count -eq 0) {
                throw "Spreadsheet is empty or could not be read: $filePath"
            }
            
            # Map columns after loading
            $this.MapColumns()
        }
        catch {
            throw "Failed to load spreadsheet: $_"
        }
    }
    
    # Save spreadsheet to file using Export-Excel cmdlet
    [void] SaveSpreadsheet([string] $filePath) {
        if ($null -eq $this.WorksheetData) {
            throw "No worksheet data to save"
        }
        
        # Verify file is not locked before attempting to save
        if ($this.FileExists($filePath)) {
            $this.VerifyFileAccess($filePath)
        }
        
        try {
            # Remove existing file to ensure Export-Excel overwrites properly
            if (Test-Path -Path $filePath) {
                Remove-Item -Path $filePath -Force
            }
            
            $this.WorksheetData | Export-Excel -Path $filePath -WorksheetName "Sheet1" -AutoSize -AutoFilter
        }
        catch {
            throw "Failed to save spreadsheet: $_"
        }
    }
    
    # Map columns by name to handle flexible column ordering
    [void] MapColumns() {
        if ($null -eq $this.WorksheetData -or $this.WorksheetData.Count -eq 0) {
            throw "No worksheet data loaded"
        }
        
        # Get the first row to extract column names
        $firstRow = $this.WorksheetData[0]
        $properties = $firstRow.PSObject.Properties
        
        # Clear existing mapping
        $this.ColumnMapping.Clear()
        
        # Map each property name to its position
        $index = 0
        foreach ($prop in $properties) {
            $this.ColumnMapping[$prop.Name] = $index
            $index++
        }
        
        # Validate that all required columns exist
        $missingColumns = @()
        foreach ($requiredCol in $this.RequiredColumns) {
            if (-not $this.ColumnMapping.ContainsKey($requiredCol)) {
                $missingColumns += $requiredCol
            }
        }
        
        if ($missingColumns.Count -gt 0) {
            $missingList = $missingColumns -join ', '
            throw "Missing required columns: $missingList"
        }
    }
    
    # Get all rows from the spreadsheet
    [array] GetRows() {
        if ($null -eq $this.WorksheetData) {
            return @()
        }
        
        return $this.WorksheetData
    }
    
    # Get cell value by row index and column name
    [string] GetCellValue([int] $row, [string] $column) {
        if ($null -eq $this.WorksheetData) {
            throw "No worksheet data loaded"
        }
        
        if ($row -lt 0 -or $row -ge $this.WorksheetData.Count) {
            throw "Row index out of range: $row"
        }
        
        if (-not $this.ColumnMapping.ContainsKey($column)) {
            throw "Column not found: $column"
        }
        
        $rowData = $this.WorksheetData[$row]
        $value = $rowData.$column
        
        if ($null -eq $value) {
            return ""
        }
        
        return $value.ToString()
    }
    
    # Update cell value by row index and column name
    [void] UpdateCell([int] $row, [string] $column, [string] $value) {
        if ($null -eq $this.WorksheetData) {
            throw "No worksheet data loaded"
        }
        
        if ($row -lt 0 -or $row -ge $this.WorksheetData.Count) {
            throw "Row index out of range: $row"
        }
        
        # Add column if it doesn't exist
        if (-not $this.ColumnMapping.ContainsKey($column)) {
            # Add the column to the mapping
            $this.ColumnMapping[$column] = $this.ColumnMapping.Count
            
            # Add the property to all rows
            foreach ($rowData in $this.WorksheetData) {
                $rowData | Add-Member -MemberType NoteProperty -Name $column -Value "" -Force
            }
        }
        
        $rowData = $this.WorksheetData[$row]
        $rowData.$column = $value
    }
    
    # Add Status column if it doesn't exist
    # Requirements: 1.10
    [void] AddStatusColumn() {
        if ($null -eq $this.WorksheetData) {
            throw "No worksheet data loaded"
        }
        
        # Check if Status column already exists
        if ($this.ColumnMapping.ContainsKey('Status')) {
            return
        }
        
        # Add Status column to the mapping
        $this.ColumnMapping['Status'] = $this.ColumnMapping.Count
        
        # Add the Status property to all rows with empty value
        foreach ($rowData in $this.WorksheetData) {
            $rowData | Add-Member -MemberType NoteProperty -Name 'Status' -Value "" -Force
        }
    }
}
