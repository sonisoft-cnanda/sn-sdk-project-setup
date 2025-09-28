# PowerShell script to update package.json with ServiceNow dependencies
# This script should be run after the ServiceNow SDK has created the initial package.json
# It updates the @servicenow/glide dependency and adds the sn-sdk-mock dependency

param(
    [switch]$Install,
    [switch]$Help
)

# Function to print colored output
function Write-Info {
    param($Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Success {
    param($Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host $Message -ForegroundColor Red
}

# Function to check if a command exists
function Test-Command {
    param($Command)
    try {
        if (Get-Command $Command -ErrorAction Stop) {
            return $true
        }
    }
    catch {
        return $false
    }
}

# Function to check if jq is available
function Test-Jq {
    if (-not (Test-Command "jq")) {
        Write-Error "jq is required but not installed. Please install jq first:"
        Write-Info "  Windows (Chocolatey): choco install jq"
        Write-Info "  Windows (Scoop): scoop install jq"
        Write-Info "  Windows (Manual): Download from https://stedolan.github.io/jq/"
        exit 1
    }
}

# Function to update package.json
function Update-PackageJson {
    $packageJsonPath = "package.json"
    
    if (-not (Test-Path $packageJsonPath)) {
        Write-Error "package.json not found in current directory"
        Write-Info "Please run this script from the project directory that contains package.json"
        exit 1
    }
    
    Write-Info "Found package.json, updating dependencies..."
    
    try {
        # Create a backup
        Copy-Item $packageJsonPath "${packageJsonPath}.backup"
        Write-Info "Created backup: ${packageJsonPath}.backup"
        
        # Read the current package.json
        $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
        
        # Update the @servicenow/glide dependency
        Write-Info "Updating @servicenow/glide dependency to use git repository..."
        if (-not $packageJson.devDependencies) {
            $packageJson | Add-Member -Type NoteProperty -Name "devDependencies" -Value @{}
        }
        $packageJson.devDependencies["@servicenow/glide"] = "git://github.com/sonisoft-cnanda/servicenow-glide"
        
        # Add sn-sdk-mock dependency
        Write-Info "Adding sn-sdk-mock dependency..."
        $packageJson.devDependencies["sn-sdk-mock"] = "file:../sn-sdk-mock"
        
        # Write the updated package.json
        $packageJson | ConvertTo-Json -Depth 10 | Set-Content $packageJsonPath -Encoding UTF8
        
        Write-Success "Successfully updated package.json with ServiceNow dependencies"
        
        # Show the updated devDependencies section
        Write-Info "`nUpdated devDependencies:"
        $packageJson.devDependencies | ConvertTo-Json -Depth 3
        
    } catch {
        Write-Error "Error updating package.json: $($_.Exception.Message)"
        exit 1
    }
}

# Function to install dependencies
function Install-Dependencies {
    Write-Info "`nInstalling updated dependencies..."
    
    if (Test-Command "npm") {
        try {
            npm install
            Write-Success "Dependencies installed successfully"
        } catch {
            Write-Error "Failed to install dependencies: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "npm not found, skipping dependency installation"
        Write-Info "Please run 'npm install' manually to install the updated dependencies"
    }
}

# Function to show usage
function Show-Usage {
    Write-Host "Usage: .\update-package-dependencies.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "Updates package.json with ServiceNow dependencies:" -ForegroundColor White
    Write-Host "  - Updates @servicenow/glide to use git repository" -ForegroundColor White
    Write-Host "  - Adds sn-sdk-mock dependency" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor White
    Write-Host "  -Install    Install dependencies after updating package.json" -ForegroundColor White
    Write-Host "  -Help       Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Example:" -ForegroundColor White
    Write-Host "  .\update-package-dependencies.ps1 -Install    # Update and install dependencies" -ForegroundColor White
    Write-Host "  .\update-package-dependencies.ps1             # Update only (manual npm install required)" -ForegroundColor White
}

# Main execution
try {
    if ($Help) {
        Show-Usage
        exit 0
    }
    
    Write-Info "Starting package.json dependency update..."
    
    # Check prerequisites
    Test-Jq
    
    # Update package.json
    Update-PackageJson
    
    # Install dependencies if requested
    if ($Install) {
        Install-Dependencies
    } else {
        Write-Info "`nTo install the updated dependencies, run: npm install"
    }
    
    Write-Success "`nPackage dependency update completed!"
    Write-Info "Backup of original package.json saved as package.json.backup"
    
} catch {
    Write-Error "`nError occurred during update: $($_.Exception.Message)"
    exit 1
}
