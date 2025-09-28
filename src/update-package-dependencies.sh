#!/bin/bash

# Script to update package.json with ServiceNow dependencies
# This script should be run after the ServiceNow SDK has created the initial package.json
# It updates the @servicenow/glide dependency and adds the sn-sdk-mock dependency

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if jq is available
check_jq() {
    if ! command_exists jq; then
        print_error "jq is required but not installed. Please install jq first:"
        print_info "  Ubuntu/Debian: sudo apt-get install jq"
        print_info "  macOS: brew install jq"
        print_info "  CentOS/RHEL: sudo yum install jq"
        print_info "  Fedora: sudo dnf install jq"
        exit 1
    fi
}

# Function to update package.json
update_package_json() {
    local package_json_path="package.json"
    
    if [ ! -f "$package_json_path" ]; then
        print_error "package.json not found in current directory"
        print_info "Please run this script from the project directory that contains package.json"
        exit 1
    fi
    
    print_info "Found package.json, updating dependencies..."
    
    # Create a backup
    cp "$package_json_path" "${package_json_path}.backup"
    print_info "Created backup: ${package_json_path}.backup"
    
    # Update the package.json using jq
    print_info "Updating @servicenow/glide dependency to use git repository..."
    jq '.devDependencies["@servicenow/glide"] = "git://github.com/sonisoft-cnanda/servicenow-glide"' "$package_json_path" > "${package_json_path}.tmp" && mv "${package_json_path}.tmp" "$package_json_path"
    
    print_info "Adding sn-sdk-mock dependency..."
    jq '.devDependencies["sn-sdk-mock"] = "file:../sn-sdk-mock"' "$package_json_path" > "${package_json_path}.tmp" && mv "${package_json_path}.tmp" "$package_json_path"
    
    print_success "Successfully updated package.json with ServiceNow dependencies"
    
    # Show the updated devDependencies section
    print_info "\nUpdated devDependencies:"
    jq '.devDependencies' "$package_json_path"
}

# Function to install dependencies
install_dependencies() {
    print_info "\nInstalling updated dependencies..."
    
    if command_exists npm; then
        npm install
        print_success "Dependencies installed successfully"
    else
        print_warning "npm not found, skipping dependency installation"
        print_info "Please run 'npm install' manually to install the updated dependencies"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Updates package.json with ServiceNow dependencies:"
    echo "  - Updates @servicenow/glide to use git repository"
    echo "  - Adds sn-sdk-mock dependency"
    echo ""
    echo "Options:"
    echo "  -i, --install    Install dependencies after updating package.json"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --install    # Update and install dependencies"
    echo "  $0              # Update only (manual npm install required)"
}

# Main execution
main() {
    local install_deps=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--install)
                install_deps=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_info "Starting package.json dependency update..."
    
    # Check prerequisites
    check_jq
    
    # Update package.json
    update_package_json
    
    # Install dependencies if requested
    if [ "$install_deps" = true ]; then
        install_dependencies
    else
        print_info "\nTo install the updated dependencies, run: npm install"
    fi
    
    print_success "\nPackage dependency update completed!"
    print_info "Backup of original package.json saved as package.json.backup"
}

# Run main function
main "$@"
