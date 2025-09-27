#!/bin/bash

# macOS-specific setup script for ServiceNow development environment
# This script is optimized for macOS with Homebrew and includes macOS-specific features

set -e  # Exit on any error

PROJECT_NAME="sn-dev-project"
NODE_VERSION="22.16.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}🍎 Starting ServiceNow Development Environment Setup on macOS...${NC}"
}

print_info() {
    echo -e "${CYAN}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo -e "${GREEN}$(printf '=%.0s' {1..60})${NC}"
}

print_brew() {
    echo -e "${BLUE}🍺 $1${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if we're on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only."
        print_info "For Linux, use: ./setup-project.sh"
        print_info "For Windows, use: .\\setup-project.ps1"
        exit 1
    fi
}

# Function to check if we're on Apple Silicon or Intel
check_architecture() {
    local arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        echo "arm64"
    elif [[ "$arch" == "x86_64" ]]; then
        echo "x86_64"
    else
        echo "unknown"
    fi
}

# Function to clone repositories
clone_repositories() {
    print_info "\n📦 Cloning repositories..."
    
    local repos=(
        "https://github.com/sonisoft-cnanda/sn-sdk-mock.git:sn-sdk-mock"
        "https://github.com/sonisoft-cnanda/servicenow-glide.git:servicenow-glide"
    )
    
    for repo_info in "${repos[@]}"; do
        IFS=':' read -r url folder <<< "$repo_info"
        
        if [ -d "$folder" ]; then
            print_warning "Repository $folder already exists, skipping..."
        else
            print_info "Cloning $url into $folder..."
            if git clone "$url" "$folder"; then
                print_success "Successfully cloned $folder"
            else
                print_error "Failed to clone $folder"
                exit 1
            fi
        fi
    done
}

# Function to install Xcode Command Line Tools if needed
install_xcode_tools() {
    print_info "\n🔧 Checking for Xcode Command Line Tools..."
    
    if xcode-select -p >/dev/null 2>&1; then
        print_success "Xcode Command Line Tools are already installed"
    else
        print_info "Installing Xcode Command Line Tools..."
        print_warning "This will open a dialog. Please follow the instructions to install."
        xcode-select --install
        
        print_info "Waiting for installation to complete..."
        print_warning "Please complete the Xcode Command Line Tools installation and press Enter to continue..."
        read -r
    fi
}

# Function to install Homebrew
install_homebrew() {
    print_info "\n🍺 Checking for Homebrew..."
    
    if command_exists brew; then
        print_success "Homebrew is already installed"
        brew --version
        return 0
    fi
    
    print_brew "Installing Homebrew..."
    local arch=$(check_architecture)
    
    if [[ "$arch" == "arm64" ]]; then
        # Apple Silicon Mac
        print_info "Installing Homebrew for Apple Silicon Mac..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon
        if [[ "$SHELL" == *"zsh"* ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zshrc"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.bash_profile"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        # Intel Mac
        print_info "Installing Homebrew for Intel Mac..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Intel
        if [[ "$SHELL" == *"zsh"* ]]; then
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zshrc"
            eval "$(/usr/local/bin/brew shellenv)"
        else
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.bash_profile"
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    # Verify installation
    if command_exists brew; then
        print_success "Homebrew installed successfully!"
        brew --version
    else
        print_error "Homebrew installation failed"
        exit 1
    fi
}

# Function to install nodenv via Homebrew
install_nodenv() {
    print_info "\n🟢 Checking for nodenv..."
    
    if command_exists nodenv; then
        print_success "nodenv is already installed"
        nodenv --version
        return 0
    fi
    
    print_brew "Installing nodenv via Homebrew..."
    brew install nodenv
    
    # Add to shell profile
    local shell_profile=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_profile="$HOME/.zshrc"
    else
        shell_profile="$HOME/.bash_profile"
    fi
    
    if [ -f "$shell_profile" ]; then
        print_info "Adding nodenv to $shell_profile..."
        echo 'export PATH="$HOME/.nodenv/bin:$PATH"' >> "$shell_profile"
        echo 'eval "$(nodenv init -)"' >> "$shell_profile"
        print_success "Added nodenv to $shell_profile"
    fi
    
    # Add to current session
    export PATH="$HOME/.nodenv/bin:$PATH"
    eval "$(nodenv init -)"
    
    # Verify installation
    if command_exists nodenv; then
        print_success "nodenv installed successfully!"
        nodenv --version
    else
        print_error "nodenv installation failed"
        exit 1
    fi
}

# Function to install additional useful tools
install_optional_tools() {
    print_info "\n🛠️  Installing additional development tools..."
    
    local tools=(
        "git"
        "gh"  # GitHub CLI
        "jq"  # JSON processor
    )
    
    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            print_brew "Installing $tool..."
            brew install "$tool"
        else
            print_info "$tool is already installed"
        fi
    done
}

# Function to create project directory and setup
create_project() {
    print_info "\n📁 Creating project directory: $PROJECT_NAME"
    
    if [ -d "$PROJECT_NAME" ]; then
        print_warning "Project directory $PROJECT_NAME already exists"
    else
        mkdir -p "$PROJECT_NAME"
        print_success "Created project directory: $PROJECT_NAME"
    fi
    
    # Create .node-version file
    print_info "Creating .node-version file with Node.js version $NODE_VERSION..."
    echo "$NODE_VERSION" > "$PROJECT_NAME/.node-version"
    print_success "Created .node-version file in $PROJECT_NAME"
    
    # Create basic project structure
    local src_dir="$PROJECT_NAME/src"
    local test_dir="$PROJECT_NAME/test"
    
    mkdir -p "$src_dir"
    print_success "Created src directory"
    
    mkdir -p "$test_dir"
    print_success "Created test directory"
}

# Function to create package.json
create_package_json() {
    local package_json_path="$PROJECT_NAME/package.json"
    
    if [ ! -f "$package_json_path" ]; then
        print_info "Creating package.json..."
        
        cat > "$package_json_path" << EOF
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "ServiceNow Development Project",
  "main": "src/index.js",
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "build": "tsc",
    "build:watch": "tsc --watch",
    "dev": "ts-node src/index.ts",
    "lint": "eslint src/**/*.ts",
    "lint:fix": "eslint src/**/*.ts --fix"
  },
  "devDependencies": {
    "@servicenow/glide": "git://github.com/sonisoft-cnanda/servicenow-glide",
    "sn-sdk-mock": "file:../sn-sdk-mock",
    "@types/jest": "^29.5.0",
    "@types/node": "^20.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.0.0",
    "jest": "^29.5.0",
    "ts-node": "^10.9.0",
    "typescript": "^5.0.0"
  },
  "jest": {
    "testEnvironment": "node",
    "testMatch": ["**/test/**/*.test.js", "**/test/**/*.test.ts"],
    "collectCoverageFrom": [
      "src/**/*.{js,ts}",
      "!src/**/*.d.ts"
    ]
  }
}
EOF
        print_success "Created package.json"
    fi
}

# Function to create TypeScript config
create_ts_config() {
    local ts_config_path="$PROJECT_NAME/tsconfig.json"
    
    if [ ! -f "$ts_config_path" ]; then
        print_info "Creating tsconfig.json..."
        
        cat > "$ts_config_path" << EOF
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "moduleResolution": "node",
    "allowSyntheticDefaultImports": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "test"]
}
EOF
        print_success "Created tsconfig.json"
    fi
}

# Function to create ESLint config
create_eslint_config() {
    local eslint_config_path="$PROJECT_NAME/.eslintrc.js"
    
    if [ ! -f "$eslint_config_path" ]; then
        print_info "Creating ESLint configuration..."
        
        cat > "$eslint_config_path" << EOF
module.exports = {
  parser: '@typescript-eslint/parser',
  extends: [
    'eslint:recommended',
    '@typescript-eslint/recommended',
  ],
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
  rules: {
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/no-explicit-any': 'warn',
    'prefer-const': 'error',
    'no-var': 'error',
  },
  env: {
    node: true,
    jest: true,
  },
};
EOF
        print_success "Created .eslintrc.js"
    fi
}

# Function to create .gitignore
create_gitignore() {
    local gitignore_path="$PROJECT_NAME/.gitignore"
    
    if [ ! -f "$gitignore_path" ]; then
        print_info "Creating .gitignore..."
        
        cat > "$gitignore_path" << EOF
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build outputs
dist/
build/
*.tsbuildinfo

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Logs
logs
*.log

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# nyc test coverage
.nyc_output

# Jest
.jest/
EOF
        print_success "Created .gitignore"
    fi
}

# Function to display final instructions
show_next_steps() {
    print_header
    print_success "🎉 Setup completed successfully!"
    print_header
    
    print_info "\n📋 Next steps:"
    print_info "1. Navigate to your project directory: cd $PROJECT_NAME"
    
    if command_exists nodenv; then
        print_info "2. Install Node.js version: nodenv install $NODE_VERSION"
        print_info "3. Set local Node.js version: nodenv local $NODE_VERSION"
    else
        print_warning "2. Install and configure nodenv, then run: nodenv install $NODE_VERSION"
    fi
    
    print_info "4. Install dependencies: npm install"
    print_info "5. Start developing!"
    
    print_info "\n📁 Project structure created:"
    echo -e "${WHITE}- $PROJECT_NAME/${NC}"
    echo -e "${WHITE}  ├── .node-version ($NODE_VERSION)${NC}"
    echo -e "${WHITE}  ├── .eslintrc.js${NC}"
    echo -e "${WHITE}  ├── .gitignore${NC}"
    echo -e "${WHITE}  ├── package.json${NC}"
    echo -e "${WHITE}  ├── tsconfig.json${NC}"
    echo -e "${WHITE}  ├── src/${NC}"
    echo -e "${WHITE}  └── test/${NC}"
    echo -e "${WHITE}- sn-sdk-mock/${NC}"
    echo -e "${WHITE}- servicenow-glide/${NC}"
    
    print_info "\n💡 Pro tips for macOS development:"
    print_info "• Use iTerm2 for a better terminal experience"
    print_info "• Install VS Code for excellent TypeScript support"
    print_info "• Use GitHub CLI (gh) for easy repository management"
    print_info "• Consider using Oh My Zsh for enhanced shell experience"
}

# Main execution
main() {
    print_status
    
    # Check if we're on macOS
    check_macos
    
    # Check if git is available
    if ! command_exists git; then
        print_error "Git is not installed or not in PATH. Please install Git first."
        exit 1
    fi
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                PROJECT_NAME="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  -n, --name NAME    Set project name (default: sn-dev-project)"
                echo "  -h, --help         Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Install Xcode Command Line Tools
    install_xcode_tools
    
    # Install Homebrew
    install_homebrew
    
    # Install nodenv
    install_nodenv
    
    # Install optional tools
    install_optional_tools
    
    # Clone repositories
    clone_repositories
    
    # Create project structure
    create_project
    create_package_json
    create_ts_config
    create_eslint_config
    create_gitignore
    
    # Show next steps
    show_next_steps
}

# Run main function
main "$@"
