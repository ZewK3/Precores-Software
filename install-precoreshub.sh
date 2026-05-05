#!/bin/bash
################################################################################
# PrecoresHub v5.0.0 - Quick Install Script
# 
# This script downloads and installs PrecoresHub from GitHub
################################################################################

set -e

VERSION="5.0.0"
GITHUB_USER="ZewK3"
REPO_NAME="Precores-Software"
ARCHIVE_NAME="PrecoresHub.tar.gz"
DOWNLOAD_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}/raw/refs/heads/main/${ARCHIVE_NAME}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    clear
    echo "================================================================"
    echo "           PrecoresHub v${VERSION} - Quick Install"
    echo "================================================================"
    echo ""
}

# Check if curl or wget is available
check_download_tool() {
    if command -v curl &>/dev/null; then
        DOWNLOAD_CMD="curl -L -o"
        print_info "Using curl for download"
    elif command -v wget &>/dev/null; then
        DOWNLOAD_CMD="wget -O"
        print_info "Using wget for download"
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
}

# Download archive
download_archive() {
    print_info "Downloading PrecoresHub v${VERSION}..."
    
    if [[ "$DOWNLOAD_CMD" == "curl -L -o" ]]; then
        curl -L -o "${ARCHIVE_NAME}" "${DOWNLOAD_URL}"
    else
        wget -O "${ARCHIVE_NAME}" "${DOWNLOAD_URL}"
    fi
    
    if [[ $? -eq 0 ]]; then
        print_success "Download completed"
    else
        print_error "Download failed"
        exit 1
    fi
}

# Extract archive
extract_archive() {
    print_info "Extracting archive..."
    
    if [[ ! -f "${ARCHIVE_NAME}" ]]; then
        print_error "Archive not found: ${ARCHIVE_NAME}"
        exit 1
    fi
    
    tar -xzf "${ARCHIVE_NAME}"
    
    if [[ $? -eq 0 ]]; then
        print_success "Extraction completed"
    else
        print_error "Extraction failed"
        exit 1
    fi
}

# Run installation
run_installation() {
    print_info "Running installation script..."
    
    if [[ -f "PrecoresHub/install.sh" ]]; then
        cd PrecoresHub
        chmod +x install.sh
        bash install.sh
    else
        print_error "Installation script not found"
        exit 1
    fi
}

# Cleanup
cleanup() {
    print_info "Cleaning up..."
    
    cd ..
    rm -f "${ARCHIVE_NAME}"
    rm -rf "PrecoresHub"
    
    print_success "Cleanup completed"
}

# Main setup
main() {
    print_header
    
    print_info "This script will download and install PrecoresHub v${VERSION}"
    echo ""
    read -p "Continue? (y/n): " continue_setup
    
    if [[ "$continue_setup" != "y" ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    echo ""
    
    # Check download tool
    check_download_tool
    
    # Download
    download_archive
    
    # Extract
    extract_archive
    
    # Install
    run_installation
    
    # Cleanup
    read -p "Remove downloaded files? (y/n): " do_cleanup
    if [[ "$do_cleanup" == "y" ]]; then
        cleanup
    fi
    
    echo ""
    print_success "Installation completed!"
    echo ""
    print_info "Run 'precoreshub' to start PrecoresHub"
    echo ""
}

# Run main
main "$@"
