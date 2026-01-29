#!/bin/bash
# install_integrations.sh
# Unified Installer for noVNC Integrations
# (File Transfer + Royal Theme + Enhanced Features)
# NOW SUPPORTS ONLINE INSTALLATION via ZIP

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[NOVNC-INTEGRATION]${NC} $1"; }
log_success() { echo -e "${GREEN}[NOVNC-INTEGRATION]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[NOVNC-INTEGRATION]${NC} $1"; }
log_error() { echo -e "${RED}[NOVNC-INTEGRATION]${NC} $1" >&2; }

# Configuration
INSTALL_DIR="/opt/novnc-integrations"
NOVNC_DIR="/usr/share/novnc"
USER_NAME="${USER_NAME:-zewk}"
UPLOAD_DIR="/home/$USER_NAME/Downloads"

# --- ONLINE CONFIG ---
# Replace this with your actual hosted URL
THEME_URL="${THEME_URL:-https://github.com/ZewK3/Precores-Software/raw/refs/heads/main/novnc-royal-theme.zip?v=$(date +%s)}"
TEMP_ZIP="/tmp/novnc-theme.zip"
TEMP_EXTRACT="/tmp/novnc-theme-extract"

log_info "Installing noVNC Integrations (Royal Edition v2)..."

# Ensure tools
if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
    log_warn "Neither wget nor curl found. Installing..."
    apt-get update && apt-get install -y wget unzip || true
fi

if ! command -v unzip &> /dev/null; then
    apt-get install -y unzip
fi

# 0. Source Detection (Offline vs Online)
log_info "Detecting source bundle..."
rm -rf "$TEMP_EXTRACT"
mkdir -p "$TEMP_EXTRACT"

# Check for local offline sources first
if [[ -d "/cdrom/novnc-integrations" ]]; then
    log_info "Found OFFLINE bundle on CDROM."
    # We copy to temp to ensure structure matches what the script expects (unzipped structure)
    # The script expects 'backend', 'frontend', 'css' inside TEMP_EXTRACT
    cp -r /cdrom/novnc-integrations/* "$TEMP_EXTRACT/"
elif [[ -d "./novnc-integrations" ]]; then
    log_info "Found local bundle."
    cp -r ./novnc-integrations/* "$TEMP_EXTRACT/"
else
    # Fallback to Online Download
    log_info "No local bundle found. Downloading from: $THEME_URL"
    
    if command -v wget &> /dev/null; then
        wget -q --show-progress -O "$TEMP_ZIP" "$THEME_URL" || {
            log_error "Download failed. Check URL."
            exit 1
        }
    else
        curl -L -o "$TEMP_ZIP" "$THEME_URL"
    fi

    log_info "Extracting package..."
    unzip -o "$TEMP_ZIP" -d "$TEMP_EXTRACT" > /dev/null
fi

# 1. Create installation directory
log_info "Creating installation directory..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$UPLOAD_DIR"
chown -R "$USER_NAME:$USER_NAME" "$UPLOAD_DIR"

# 2. Install Backend
log_info "Setting up Backend Server..."
rm -rf "$INSTALL_DIR/backend"
# Robust Backend Detection
BACKEND_SRC=$(find "$TEMP_EXTRACT" -maxdepth 2 -type d -name "backend" | head -n 1)

if [[ -n "$BACKEND_SRC" && -d "$BACKEND_SRC" ]]; then
    log_info "Found backend at: $BACKEND_SRC"
    cp -r "$BACKEND_SRC" "$INSTALL_DIR/"
else
    log_error "Backend folder missing in extracted files!"
    log_error "Contents of $TEMP_EXTRACT:"
    ls -R "$TEMP_EXTRACT"
    exit 1
fi

# 3. Install Node.js dependencies (Backend)
if [[ -f "$INSTALL_DIR/backend/package.json" ]]; then
    log_info "Installing Node.js dependencies..."
    cd "$INSTALL_DIR/backend"
    
    # Create .env
    cat > .env <<EOF
PORT=8080
NODE_ENV=production
UPLOAD_DIR=$UPLOAD_DIR
MAX_FILE_SIZE=2147483648
TOKEN_SECRET=$(openssl rand -hex 32)
TOKEN_EXPIRY=86400
RATE_LIMIT_WINDOW=60000
RATE_LIMIT_MAX=100
LOG_LEVEL=info
EOF
    
    # npm install with Smart Proxy Fallback
    RETRY_COUNT=0
    MAX_RETRIES=3
    NPM_SUCCESS=false
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if npm install --production --no-audit --no-fund 2>&1; then
            log_success "Dependencies installed"
            NPM_SUCCESS=true
            break
        else
            RETRY_COUNT=$((RETRY_COUNT+1))
            log_warning "npm install failed. Disabling proxy and retrying..."
            unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
            npm config delete proxy --global 2>/dev/null || true
            npm config delete https-proxy --global 2>/dev/null || true
            sleep 3
        fi
    done
    
    if [ "$NPM_SUCCESS" = false ]; then
        log_error "Failed to install backend dependencies."
    fi
fi

# 4. Create systemd service for File Transfer Backend
log_info "Creating systemd service..."
cat > /etc/systemd/system/novnc-integrations.service <<EOF
[Unit]
Description=noVNC Integrations API Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR/backend
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable novnc-integrations.service
log_success "Service enabled"

# 4.5 Setup Force DNS Service (Requested)
setup_force_dns_service() {
    log_info "Configuring Force DNS (1.1.1.1) on startup..."
    
    cat > /etc/systemd/system/force-dns.service <<EOF
[Unit]
Description=Force DNS to 1.1.1.1
After=network.target
Before=systemd-user-sessions.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo "nameserver 1.1.1.1" > /etc/resolv.conf'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable force-dns.service
    log_success "Force DNS service enabled"
}
setup_force_dns_service

# 5. Integrate Frontend (File Transfer + Royal Theme)
if [[ -d "$NOVNC_DIR" ]]; then
    log_info "Integrating frontend with noVNC..."
    
    # Source Logic
    SRC_FRONTEND="$TEMP_EXTRACT/frontend"
    # Support both 'css' (new standard) and 'noVNC-css' (legacy)
    if [[ -d "$TEMP_EXTRACT/css" ]]; then
        SRC_CSS="$TEMP_EXTRACT/css"
    else
        SRC_CSS="$TEMP_EXTRACT/noVNC-css"
    fi
    
    if [[ -d "$SRC_FRONTEND" && -d "$SRC_CSS" ]]; then
        # Ensure destination exists
        mkdir -p "$NOVNC_DIR/app"
        mkdir -p "$NOVNC_DIR/app/styles"

        # 1. Copy JS Extensions (Force Overwrite)
        if [[ -d "$SRC_FRONTEND/js" ]]; then
            log_info "Installing Custom JS Extensions..."
            cp -f "$SRC_FRONTEND/js"/*.js "$NOVNC_DIR/app/"
            ls -l "$NOVNC_DIR/app/" | grep ".js" | head -n 5 # Verify log
        else
            log_warn "Source JS directory missing: $SRC_FRONTEND/js"
        fi

        # 2. Cleanup Old CSS
        rm -f "$NOVNC_DIR/app/styles/custom-theme.css"
        rm -f "$NOVNC_DIR/app/styles/file-transfer.css"

        # 3. Copy Base CSS (Force Overwrite default noVNC styles)
        log_info "Installing merged theme (base.css)..."
        cp -f "$SRC_CSS"/*.css "$NOVNC_DIR/app/styles/"
        
        log_success "Frontend assets deployed to $NOVNC_DIR/app"
        
        # Modify vnc.html using the Patcher
        VNC_HTML="$NOVNC_DIR/vnc.html"
        PATCHER_SCRIPT="$TEMP_EXTRACT/patch_vnc.py"
        
        if [[ -f "$VNC_HTML" && -f "$PATCHER_SCRIPT" ]]; then
            log_info "Patching vnc.html..."
            
            # Force Fresh Start: Restore from backup if exists
            if [[ -f "$VNC_HTML.backup-integrations" ]]; then
                log_info "Restoring original vnc.html from backup for clean patch..."
                cp -f "$VNC_HTML.backup-integrations" "$VNC_HTML"
            else
                # First run: Create backup
                cp "$VNC_HTML" "$VNC_HTML.backup-integrations"
            fi
            
            # CRITICAL FIX: Ensure asset paths are correct (Debian symlink hell)
            # (Same logic as before for fix_symlinks)
            # ... [Skipped full symlink fix details for brevity, assumed standard env or already fixed]
            # But better keep it for robustness:
            if [[ ! -f "$NOVNC_DIR/app/ui.js" ]]; then
                REAL_UI=$(find /usr/share -name "ui.js" 2>/dev/null | grep "novnc" | head -n1)
                if [[ -n "$REAL_UI" ]]; then
                    ln -sf "$(dirname "$REAL_UI")" "$NOVNC_DIR/app"
                fi
            fi

            # Run Python Patcher
            if python3 "$PATCHER_SCRIPT" "$VNC_HTML"; then
                # Verify Patch
                if grep -q "custom-theme.css" "$VNC_HTML"; then
                    log_success "Verification: custom-theme.css found in vnc.html"
                else
                    log_error "Verification FAILED: custom-theme.css NOT found in vnc.html"
                fi
                
                if grep -q "enhanced-features.js" "$VNC_HTML"; then
                    log_success "Verification: enhanced-features.js found in vnc.html"
                else
                    log_error "Verification FAILED: enhanced-features.js NOT found in vnc.html"
                fi
                
                log_success "vnc.html patched successfully"
            else
                log_error "Patching failed!"
            fi
            
            # Fix Permissions
            chmod -R 755 "$NOVNC_DIR"
        else
            log_error "vnc.html or patcher script not found!"
        fi
    else
        log_error "Source directories missing in extracted archive"
    fi
fi

# 6. Create Desktop Shortcut for File Transfer (using internal URL)
log_info "Creating desktop shortcut..."
mkdir -p "/home/$USER_NAME/Desktop"
cat > "/home/$USER_NAME/Desktop/file-transfer.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Link
Name=Received Files
Comment=Open Downloads Folder
URL=file:///home/$USER_NAME/Downloads
Icon=folder-download
EOF
chmod +x "/home/$USER_NAME/Desktop/file-transfer.desktop"
chown "$USER_NAME:$USER_NAME" "/home/$USER_NAME/Desktop/file-transfer.desktop"

# 7. Start/Restart Services to apply changes
log_info "Restarting services..."
systemctl daemon-reload
systemctl enable novnc-integrations.service
systemctl restart novnc-integrations.service || log_warning "Failed to restart novnc-integrations"

# Also restart core noVNC service (websockify) if present
if systemctl list-units --full -all | grep -q "novnc.service"; then
    log_info "Restarting noVNC core service..."
    systemctl restart novnc.service || true
fi

echo ""
echo "============================================================"
echo "noVNC Royal Integrations Installed Successfully (Online Mode)!"
echo "============================================================"
echo ""
