# Product Overview

DNS-Update is a Windows PowerShell-based DNS validation and update tool that automates the process of validating and correcting DNS records against a DNS server.

## Core Functionality

- Validates forward DNS (hostname to IP) and reverse DNS (IP to hostname) records
- Reads DNS validation data from Excel spreadsheets
- Automatically detects appropriate DNS zones for records
- Updates or creates missing/incorrect DNS records with safety limits
- Provides detailed logging and progress tracking
- Supports read-only mode for safe testing before making changes

## Key Features

- Excel spreadsheet integration for bulk DNS validation
- Automatic DNS zone detection for both forward and reverse lookups
- Configurable update limits to prevent accidental mass changes
- Read-only mode enabled by default for safety
- Comprehensive logging with timestamp-based filenames (YYYYMMDD-HH-MM format)
- Backup management for configuration and data files

## Target Users

System administrators and network engineers who need to validate and maintain DNS records across Windows DNS servers.
