# Version Information for DNS-Update
# This file contains version metadata for the DNS-Update program

$script:__version__ = "0.0.1a"
$script:__author__ = "Mark Oldham"
$script:__compile_date__ = "2026-02-26"

function Get-DnsUpdateVersion {
    return @{
        Version = $script:__version__
        Author = $script:__author__
        CompileDate = $script:__compile_date__
    }
}

function Show-DnsUpdateVersion {
    $versionInfo = Get-DnsUpdateVersion
    Write-Host "DNS-Update Version $($versionInfo.Version)"
    Write-Host "Author: $($versionInfo.Author)"
    Write-Host "Compile Date: $($versionInfo.CompileDate)"
}

# Export version variables for use in other modules
Export-ModuleMember -Variable __version__, __author__, __compile_date__
Export-ModuleMember -Function Get-DnsUpdateVersion, Show-DnsUpdateVersion
