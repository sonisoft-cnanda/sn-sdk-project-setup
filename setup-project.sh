#!/bin/bash

# Bash script to setup ServiceNow development environment
# This script clones required repositories, creates project structure, and sets up nodenv
# Compatible with Linux and macOS

set -e  # Exit on any error

PROJECT_NAME="sn-dev-project"
NODE_VERSION="22.16.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}Starting ServiceNow Development Environment Setup...${NC}"
}

print_info() {
    echo -e "${CYAN}$1${NC}"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

print_header() {
    echo -e "${GREEN}$(printf '=%.0s' {1..60})${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Function to clone repositories
clone_repositories() {
    print_info "\nCloning repositories..."
    
    local repos=(
        "https://github.com/sonisoft-cnanda/sn-sdk-mock.git:sn-sdk-mock.git"
        "https://github.com/sonisoft-cnanda/servicenow-glide.git:servicenow-glide.git"
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

# Function to install nodenv on Linux
install_nodenv_linux() {
    print_info "Installing nodenv on Linux..."
    
    # Check if we're on Ubuntu/Debian
    if command_exists apt-get; then
        print_info "Installing dependencies via apt..."
        sudo apt-get update
        sudo apt-get install -y git curl build-essential libssl-dev zlib1g-dev \
            libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
            libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl
    # Check if we're on CentOS/RHEL/Fedora
    elif command_exists yum; then
        print_info "Installing dependencies via yum..."
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y git curl openssl-devel zlib-devel bzip2-devel \
            readline-devel sqlite-devel wget curl llvm ncurses-devel \
            ncurses-libs ncurses-devel xz-devel tk-devel libffi-devel \
            xz-devel openssl-devel
    elif command_exists dnf; then
        print_info "Installing dependencies via dnf..."
        sudo dnf groupinstall -y "Development Tools"
        sudo dnf install -y git curl openssl-devel zlib-devel bzip2-devel \
            readline-devel sqlite-devel wget curl llvm ncurses-devel \
            ncurses-libs xz-devel tk-devel libffi-devel openssl-devel
    fi
    
    # Install nodenv
    print_info "Installing nodenv..."
    curl -fsSL https://github.com/nodenv/nodenv-installer/raw/HEAD/bin/nodenv-installer | bash
    
    # Add to shell profile
    local shell_profile=""
    if [ -f "$HOME/.bashrc" ]; then
        shell_profile="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        shell_profile="$HOME/.bash_profile"
    elif [ -f "$HOME/.profile" ]; then
        shell_profile="$HOME/.profile"
    fi
    
    if [ -n "$shell_profile" ]; then
        print_info "Adding nodenv to $shell_profile..."
        echo 'export PATH="$HOME/.nodenv/bin:$PATH"' >> "$shell_profile"
        echo 'eval "$(nodenv init -)"' >> "$shell_profile"
        print_success "Added nodenv to $shell_profile"
    fi
    
    # Add to current session
    export PATH="$HOME/.nodenv/bin:$PATH"
    eval "$(nodenv init -)"
}

# Function to install nodenv on macOS
install_nodenv_macos() {
    print_info "Installing nodenv on macOS..."
    
    # Check if Homebrew is installed
    if ! command_exists brew; then
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH
        if [[ "$SHELL" == *"zsh"* ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zshrc"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.bash_profile"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
    
    # Install nodenv via Homebrew
    print_info "Installing nodenv via Homebrew..."
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
}

# Function to check and install nodenv
install_nodenv() {
    print_info "\nChecking for nodenv..."
    
    if command_exists nodenv; then
        print_success "nodenv is already installed"
        nodenv --version
        return 0
    fi
    
    local os=$(detect_os)
    
    case $os in
        "linux")
            install_nodenv_linux
            ;;
        "macos")
            install_nodenv_macos
            ;;
        *)
            print_error "Unsupported operating system: $OSTYPE"
            print_info "Please install nodenv manually from: https://github.com/nodenv/nodenv"
            return 1
            ;;
    esac
    
    # Verify installation
    if command_exists nodenv; then
        print_success "nodenv installed successfully!"
        nodenv --version
    else
        print_error "nodenv installation failed. Please restart your terminal and try again."
        return 1
    fi
}

# Function to create project directory and setup
create_project() {
    print_info "\nCreating project directory: $PROJECT_NAME"
    
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
    "build": "tsc",
    "dev": "ts-node src/index.ts"
  },
  "devDependencies": {
    "@servicenow/glide": "git://github.com/sonisoft-cnanda/servicenow-glide",
    "sn-sdk-mock": "file:../sn-sdk-mock",
    "@types/jest": "^29.5.0",
    "@types/node": "^20.0.0",
    "jest": "^29.5.0",
    "ts-node": "^10.9.0",
    "typescript": "^5.0.0"
  },
  "jest": {
    "testEnvironment": "node",
    "testMatch": ["**/test/**/*.test.js", "**/test/**/*.test.ts"]
  }
}
EOF
        print_success "Created package.json"
    fi
}

# Function to create basic TypeScript config
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
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "test"]
}
EOF
        print_success "Created tsconfig.json"
    fi
}

# Function to display final instructions
show_next_steps() {
    print_header
    print_success "Setup completed successfully!"
    print_header
    
    print_info "\nNext steps:"
    print_info "1. Navigate to your project directory: cd $PROJECT_NAME"
    
    if command_exists nodenv; then
        print_info "2. Install Node.js version: nodenv install $NODE_VERSION"
        print_info "3. Set local Node.js version: nodenv local $NODE_VERSION"
    else
        print_warning "2. Install and configure nodenv, then run: nodenv install $NODE_VERSION"
    fi
    
    print_info "4. Install dependencies: npm install"
    print_info "5. Start developing!"
    
    print_info "\nProject structure created:"
    echo -e "${WHITE}- $PROJECT_NAME/${NC}"
    echo -e "${WHITE}  ├── .node-version ($NODE_VERSION)${NC}"
    echo -e "${WHITE}  ├── package.json${NC}"
    echo -e "${WHITE}  ├── tsconfig.json${NC}"
    echo -e "${WHITE}  ├── src/${NC}"
    echo -e "${WHITE}  └── test/${NC}"
    echo -e "${WHITE}- sn-sdk-mock/${NC}"
    echo -e "${WHITE}- servicenow-glide/${NC}"
}

# Main execution
main() {
    print_status
    
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
    
    # Clone repositories
    clone_repositories
    
    # Install nodenv
    install_nodenv
    
    # Create project structure
    create_project
    create_package_json
    create_ts_config
    
    # Show next steps
    show_next_steps
}

# Run main function
main "$@"
