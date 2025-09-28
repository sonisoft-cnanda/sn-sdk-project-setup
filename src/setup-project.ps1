# PowerShell script to setup ServiceNow development environment
# This script clones required repositories, creates project structure, and sets up nodenv

param(
    [string]$ProjectName = "sn-dev-project"
)

Write-Host "Starting ServiceNow Development Environment Setup..." -ForegroundColor Green

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

# Function to clone repositories
function Clone-Repositories {
    Write-Host "`nCloning repositories..." -ForegroundColor Yellow
    
    $repos = @(
        @{
            url = "https://github.com/sonisoft-cnanda/sn-sdk-mock.git"
            folder = "sn-sdk-mock"
        },
        @{
            url = "https://github.com/sonisoft-cnanda/servicenow-glide.git"
            folder = "servicenow-glide"
        }
    )
    
    foreach ($repo in $repos) {
        if (Test-Path $repo.folder) {
            Write-Host "Repository $($repo.folder) already exists, skipping..." -ForegroundColor Yellow
        } else {
            Write-Host "Cloning $($repo.url) into $($repo.folder)..." -ForegroundColor Cyan
            try {
                git clone $repo.url $repo.folder
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Successfully cloned $($repo.folder)" -ForegroundColor Green
                } else {
                    Write-Host "Failed to clone $($repo.folder)" -ForegroundColor Red
                }
            }
            catch {
                Write-Host "Error cloning $($repo.folder): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# Function to check and install nodenv
function Install-NodeEnv {
    Write-Host "`nChecking for nodenv..." -ForegroundColor Yellow
    
    if (Test-Command "nodenv") {
        Write-Host "nodenv is already installed" -ForegroundColor Green
        nodenv --version
    } else {
        Write-Host "nodenv not found. Installing nodenv..." -ForegroundColor Yellow
        
        # Check if we're on Windows
        if ($IsWindows -or $env:OS -eq "Windows_NT") {
            Write-Host "Installing nodenv-win..." -ForegroundColor Cyan
            
            # Install via Chocolatey if available
            if (Test-Command "choco") {
                Write-Host "Installing nodenv-win via Chocolatey..." -ForegroundColor Cyan
                choco install nodenv-win -y
            }
            # Install via Scoop if available
            elseif (Test-Command "scoop") {
                Write-Host "Installing nodenv-win via Scoop..." -ForegroundColor Cyan
                scoop install nodenv-win
            }
            # Manual installation instructions
            else {
                Write-Host "Chocolatey and Scoop not found. Please install nodenv-win manually:" -ForegroundColor Yellow
                Write-Host "1. Download from: https://github.com/nodenv/nodenv-win" -ForegroundColor Cyan
                Write-Host "2. Or install Chocolatey first: https://chocolatey.org/install" -ForegroundColor Cyan
                Write-Host "3. Then run: choco install nodenv-win" -ForegroundColor Cyan
                return $false
            }
        } else {
            # Unix-like systems
            Write-Host "Installing nodenv via curl..." -ForegroundColor Cyan
            curl -fsSL https://github.com/nodenv/nodenv-installer/raw/HEAD/bin/nodenv-installer | bash
            
            # Add to PATH
            $env:PATH += ":$HOME/.nodenv/bin"
            Write-Host "Added nodenv to PATH for this session" -ForegroundColor Yellow
        }
        
        # Refresh environment
        if ($IsWindows -or $env:OS -eq "Windows_NT") {
            refreshenv
        }
        
        # Verify installation
        if (Test-Command "nodenv") {
            Write-Host "nodenv installed successfully!" -ForegroundColor Green
            nodenv --version
        } else {
            Write-Host "nodenv installation may have failed. Please restart your terminal and try again." -ForegroundColor Red
            return $false
        }
    }
    
    return $true
}

# Function to create project directory and setup
function Create-Project {
    Write-Host "`nCreating project directory: $ProjectName" -ForegroundColor Yellow
    
    if (Test-Path $ProjectName) {
        Write-Host "Project directory $ProjectName already exists" -ForegroundColor Yellow
    } else {
        New-Item -ItemType Directory -Path $ProjectName -Force | Out-Null
        Write-Host "Created project directory: $ProjectName" -ForegroundColor Green
    }
    
    # Create .node-version file
    $nodeVersionFile = Join-Path $ProjectName ".node-version"
    Write-Host "Creating .node-version file with Node.js version 22.16.0..." -ForegroundColor Cyan
    "22.16.0" | Out-File -FilePath $nodeVersionFile -Encoding UTF8
    Write-Host "Created .node-version file in $ProjectName" -ForegroundColor Green
    
    # Create basic project structure
    $srcDir = Join-Path $ProjectName "src"
    $testDir = Join-Path $ProjectName "test"
    
    if (!(Test-Path $srcDir)) {
        New-Item -ItemType Directory -Path $srcDir -Force | Out-Null
        Write-Host "Created src directory" -ForegroundColor Green
    }
    
    if (!(Test-Path $testDir)) {
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        Write-Host "Created test directory" -ForegroundColor Green
    }
}


# Function to verify and install npm
function Verify-Npm {
    Write-Host "`nVerifying npm installation..." -ForegroundColor Yellow
    
    # Store current directory
    $originalDir = Get-Location
    
    # Change to project directory to use the correct Node.js version
    try {
        Push-Location $ProjectName
        Write-Host "Changed to project directory: $(Get-Location)" -ForegroundColor Cyan
    } catch {
        Write-Host "Failed to change to project directory: $ProjectName" -ForegroundColor Red
        return $false
    }
    
    try {
        # Set the Node.js version for this directory
        if (Test-Command "nodenv") {
            Write-Host "Setting Node.js version 22.16.0 for project..." -ForegroundColor Cyan
            
            # Check if Node.js version exists
            $nodeVersions = nodenv versions 2>$null
            if ($nodeVersions -notcontains "22.16.0") {
                Write-Host "Installing Node.js version 22.16.0..." -ForegroundColor Cyan
                nodenv install 22.16.0
            }
            
            # Set local version
            nodenv local 22.16.0
            
            # Verify Node.js version
            try {
                $currentNodeVersion = node --version 2>$null
                if ($currentNodeVersion) {
                    Write-Host "Node.js version set to: $currentNodeVersion" -ForegroundColor Green
                } else {
                    Write-Host "Failed to set Node.js version" -ForegroundColor Red
                    return $false
                }
            } catch {
                Write-Host "Failed to verify Node.js version" -ForegroundColor Red
                return $false
            }
        }
        
        # Check if npm is available
        if (Test-Command "npm") {
            $npmVersion = npm --version
            Write-Host "npm is available (version: $npmVersion)" -ForegroundColor Green
        } else {
            Write-Host "npm is not available, installing..." -ForegroundColor Yellow
            
            # Install npm using the current Node.js installation
            if (Test-Command "node") {
                Write-Host "Installing npm using Node.js..." -ForegroundColor Cyan
                # Use the Node.js installation to install npm
                try {
                    if (Test-Command "bash") {
                        # Use bash if available (Git Bash, WSL, etc.)
                        Invoke-WebRequest -Uri "https://npmjs.org/install.sh" -OutFile "install-npm.sh"
                        bash install-npm.sh
                    } else {
                        # For Windows, try alternative approach
                        Write-Host "Installing npm via Node.js corepack..." -ForegroundColor Cyan
                        node -e "require('child_process').exec('corepack enable npm')" 2>$null
                    }
                    
                    if (Test-Command "npm") {
                        $npmVersion = npm --version
                        Write-Host "npm installed successfully (version: $npmVersion)" -ForegroundColor Green
                    } else {
                        Write-Host "Failed to install npm" -ForegroundColor Red
                        return $false
                    }
                } catch {
                    Write-Host "Error installing npm: $($_.Exception.Message)" -ForegroundColor Red
                    return $false
                }
            } else {
                Write-Host "Node.js is not available, cannot install npm" -ForegroundColor Red
                return $false
            }
        }
        
        return $true
    } finally {
        # Return to original directory
        Pop-Location
        Write-Host "Returned to original directory: $(Get-Location)" -ForegroundColor Cyan
    }
}

# Function to create basic TypeScript config
function Create-TsConfig {
    $tsConfigPath = Join-Path $ProjectName "tsconfig.json"
    
    if (!(Test-Path $tsConfigPath)) {
        Write-Host "Creating tsconfig.json..." -ForegroundColor Cyan
        
        $tsConfig = @{
            compilerOptions = @{
                target = "ES2020"
                module = "commonjs"
                lib = @("ES2020")
                outDir = "./dist"
                rootDir = "./src"
                strict = $true
                esModuleInterop = $true
                skipLibCheck = $true
                forceConsistentCasingInFileNames = $true
                resolveJsonModule = $true
                declaration = $true
                declarationMap = $true
                sourceMap = $true
            }
            include = @("src/**/*")
            exclude = @("node_modules", "dist", "test")
        }
        
        $tsConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $tsConfigPath -Encoding UTF8
        Write-Host "Created tsconfig.json" -ForegroundColor Green
    }
}

# Main execution
try {
    # Check if git is available
    if (!(Test-Command "git")) {
        Write-Host "Git is not installed or not in PATH. Please install Git first." -ForegroundColor Red
        exit 1
    }
    
    # Clone repositories
    Clone-Repositories
    
    # Install nodenv
    $nodenvInstalled = Install-NodeEnv
    
    # Create project structure
    Create-Project
    Create-TsConfig
    
    # Verify npm installation
    $npmVerified = Verify-Npm
    
    Write-Host "`n" + "="*60 -ForegroundColor Green
    Write-Host "Setup completed successfully!" -ForegroundColor Green
    Write-Host "="*60 -ForegroundColor Green
    
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Navigate to your project directory: cd $ProjectName" -ForegroundColor Cyan
    if ($nodenvInstalled) {
        Write-Host "2. Install Node.js version: nodenv install 22.16.0" -ForegroundColor Cyan
        Write-Host "3. Set local Node.js version: nodenv local 22.16.0" -ForegroundColor Cyan
    } else {
        Write-Host "2. Install and configure nodenv, then run: nodenv install 22.16.0" -ForegroundColor Cyan
    }
    Write-Host "4. Use ServiceNow SDK to initialize the project" -ForegroundColor Cyan
    Write-Host "5. Start developing!" -ForegroundColor Cyan
    
    Write-Host "`nProject structure created:" -ForegroundColor Yellow
    Write-Host "- $ProjectName/" -ForegroundColor White
    Write-Host "  ├── .node-version (22.16.0)" -ForegroundColor White
    Write-Host "  ├── tsconfig.json" -ForegroundColor White
    Write-Host "  ├── src/" -ForegroundColor White
    Write-Host "  └── test/" -ForegroundColor White
    Write-Host "- sn-sdk-mock/" -ForegroundColor White
    Write-Host "- servicenow-glide/" -ForegroundColor White
    
} catch {
    Write-Host "`nError occurred during setup: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
