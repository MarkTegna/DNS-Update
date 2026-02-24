# Test-DnsUpdater.ps1
# Unit tests for DnsUpdater class
# Author: Mark Oldham

# Import the DnsUpdater class
. "$PSScriptRoot\..\src\DnsUpdater.ps1"

# Test configuration
$testDnsServer = "eit-priaddc00"
$testUpdateLimit = 5
$testReadOnlyMode = $true  # Always use read-only mode for testing

Write-Host "=== DnsUpdater Unit Tests ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Constructor initialization
Write-Host "Test 1: Constructor initialization" -ForegroundColor Yellow
try {
    $updater = [DnsUpdater]::new($testDnsServer, $testUpdateLimit, $testReadOnlyMode)
    
    if ($updater.DnsServer -eq $testDnsServer -and 
        $updater.UpdateLimit -eq $testUpdateLimit -and 
        $updater.ReadOnlyMode -eq $testReadOnlyMode -and
        $updater.UpdateCount -eq 0) {
        Write-Host "[OK] Constructor properly initializes all properties" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Constructor did not initialize properties correctly" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Constructor threw exception: $_" -ForegroundColor Red
}
Write-Host ""

# Test 2: CanUpdate method
Write-Host "Test 2: CanUpdate method" -ForegroundColor Yellow
try {
    $updater = [DnsUpdater]::new($testDnsServer, 3, $testReadOnlyMode)
    
    if ($updater.CanUpdate()) {
        Write-Host "[OK] CanUpdate returns true when count is 0" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] CanUpdate should return true when count is 0" -ForegroundColor Red
    }
    
    # Increment to limit
    $updater.IncrementUpdateCount()
    $updater.IncrementUpdateCount()
    $updater.IncrementUpdateCount()
    
    if (-not $updater.CanUpdate()) {
        Write-Host "[OK] CanUpdate returns false when limit is reached" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] CanUpdate should return false when limit is reached" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] CanUpdate test threw exception: $_" -ForegroundColor Red
}
Write-Host ""

# Test 3: IncrementUpdateCount method
Write-Host "Test 3: IncrementUpdateCount method" -ForegroundColor Yellow
try {
    $updater = [DnsUpdater]::new($testDnsServer, $testUpdateLimit, $testReadOnlyMode)
    
    $initialCount = $updater.UpdateCount
    $updater.IncrementUpdateCount()
    
    if ($updater.UpdateCount -eq ($initialCount + 1)) {
        Write-Host "[OK] IncrementUpdateCount properly increments counter" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] IncrementUpdateCount did not increment counter" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] IncrementUpdateCount test threw exception: $_" -ForegroundColor Red
}
Write-Host ""

# Test 4: ReadOnlyMode behavior for UpdateARecord
Write-Host "Test 4: ReadOnlyMode behavior for UpdateARecord" -ForegroundColor Yellow
try {
    $updater = [DnsUpdater]::new($testDnsServer, $testUpdateLimit, $true)
    
    # Try to update a record in read-only mode
    $result = $updater.UpdateARecord("testhost.tgna.tegna.com", "10.1.2.3", "tgna.tegna.com")
    
    if ($result.Success -eq $true -and $result.Status -eq "ReadOnly") {
        Write-Host "[OK] UpdateARecord returns ReadOnly status in read-only mode" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] UpdateARecord should return ReadOnly status (Got: Success=$($result.Success), Status=$($result.Status))" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] ReadOnlyMode test threw exception: $_" -ForegroundColor Red
}
Write-Host ""

# Test 5: ReadOnlyMode behavior for UpdatePtrRecord
Write-Host "Test 5: ReadOnlyMode behavior for UpdatePtrRecord" -ForegroundColor Yellow
try {
    $updater = [DnsUpdater]::new($testDnsServer, $testUpdateLimit, $true)
    
    # Try to update a PTR record in read-only mode
    $result = $updater.UpdatePtrRecord("10.1.2.3", "testhost.tgna.tegna.com", "2.1.10.in-addr.arpa")
    
    if ($result.Success -eq $true -and $result.Status -eq "ReadOnly") {
        Write-Host "[OK] UpdatePtrRecord returns ReadOnly status in read-only mode" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] UpdatePtrRecord should return ReadOnly status (Got: Success=$($result.Success), Status=$($result.Status))" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] ReadOnlyMode test threw exception: $_" -ForegroundColor Red
}
Write-Host ""

# Test 6: Empty parameter handling for UpdateARecord
Write-Host "Test 6: Empty parameter handling for UpdateARecord" -ForegroundColor Yellow
try {
    $updater = [DnsUpdater]::new($testDnsServer, $testUpdateLimit, $false)
    
    $result1 = $updater.UpdateARecord("", "10.1.2.3", "tgna.tegna.com")
    $result2 = $updater.UpdateARecord("testhost.tgna.tegna.com", "", "tgna.tegna.com")
    $result3 = $updater.UpdateARecord("testhost.tgna.tegna.com", "10.1.2.3", "")
    
    if ($result1.Success -eq $false -and $result2.Success -eq $false -and $result3.Success -eq $false) {
        Write-Host "[OK] UpdateARecord handles empty parameters correctly" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] UpdateARecord should return false for empty parameters" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Empty parameter test threw exception: $_" -ForegroundColor Red
}
Write-Host ""

# Test 7: Empty parameter handling for UpdatePtrRecord
Write-Host "Test 7: Empty parameter handling for UpdatePtrRecord" -ForegroundColor Yellow
try {
    $updater = [DnsUpdater]::new($testDnsServer, $testUpdateLimit, $false)
    
    $result1 = $updater.UpdatePtrRecord("", "testhost.tgna.tegna.com", "2.1.10.in-addr.arpa")
    $result2 = $updater.UpdatePtrRecord("10.1.2.3", "", "2.1.10.in-addr.arpa")
    $result3 = $updater.UpdatePtrRecord("10.1.2.3", "testhost.tgna.tegna.com", "")
    
    if ($result1.Success -eq $false -and $result2.Success -eq $false -and $result3.Success -eq $false) {
        Write-Host "[OK] UpdatePtrRecord handles empty parameters correctly" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] UpdatePtrRecord should return false for empty parameters" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Empty parameter test threw exception: $_" -ForegroundColor Red
}
Write-Host ""

# Test 8: RecordExists with empty parameters
Write-Host "Test 8: RecordExists with empty parameters" -ForegroundColor Yellow
try {
    $updater = [DnsUpdater]::new($testDnsServer, $testUpdateLimit, $testReadOnlyMode)
    
    $result1 = $updater.RecordExists("", "tgna.tegna.com", "A")
    $result2 = $updater.RecordExists("testhost", "", "A")
    
    if ($result1 -eq $false -and $result2 -eq $false) {
        Write-Host "[OK] RecordExists handles empty parameters correctly" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] RecordExists should return false for empty parameters" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] RecordExists empty parameter test threw exception: $_" -ForegroundColor Red
}
Write-Host ""

# Test 9: HasMultipleRecords with empty parameters
Write-Host "Test 9: HasMultipleRecords with empty parameters" -ForegroundColor Yellow
try {
    $updater = [DnsUpdater]::new($testDnsServer, $testUpdateLimit, $testReadOnlyMode)
    
    $result1 = $updater.HasMultipleRecords("", "tgna.tegna.com", "A")
    $result2 = $updater.HasMultipleRecords("testhost", "", "A")
    
    if ($result1 -eq $false -and $result2 -eq $false) {
        Write-Host "[OK] HasMultipleRecords handles empty parameters correctly" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] HasMultipleRecords should return false for empty parameters" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] HasMultipleRecords empty parameter test threw exception: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== DnsUpdater Unit Tests Complete ===" -ForegroundColor Cyan
