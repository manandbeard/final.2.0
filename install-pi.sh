
#!/bin/bash

# Family Dashboard - Raspberry Pi Automated Installation Script
# Run with: GITHUB_REPO=manandbeard/family-dashboard curl -sSL https://raw.githubusercontent.com/manandbeard/family-dashboard/main/install-pi.sh | bash

set -e

echo "🏠 Family Dashboard - Raspberry Pi Installation"
echo "=============================================="

# Pre-installation checks
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check system requirements
check_system() {
    print_status "Checking system requirements..."
    
    # Check available disk space (need at least 2GB)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 2097152 ]; then
        print_error "Insufficient disk space. Need at least 2GB free."
        exit 1
    fi
    
    # Check available RAM (recommend at least 1GB)
    total_ram=$(free -m | awk 'NR==2{print $2}')
    if [ "$total_ram" -lt 1024 ]; then
        print_warning "Less than 1GB RAM detected. Performance may be affected."
    fi
    
    # Check internet connectivity
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        print_error "No internet connection detected. Please connect to internet and try again."
        exit 1
    fi
    
    print_success "System checks passed"
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    print_warning "This script is designed for Raspberry Pi. Continuing anyway..."
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root (don't use sudo)"
   exit 1
fi

# Run system checks
check_system

print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

print_status "Installing required packages..."
sudo apt install -y git curl chromium-browser unzip

# Install Node.js 18.x
print_status "Installing Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify Node.js installation
node_version=$(node --version)
npm_version=$(npm --version)
print_success "Node.js ${node_version} and npm ${npm_version} installed"

# Create project directory
PROJECT_DIR="/home/$(whoami)/family-dashboard"
print_status "Setting up project directory at ${PROJECT_DIR}..."

if [ -d "$PROJECT_DIR" ]; then
    print_warning "Project directory already exists. Backing up..."
    sudo mv "$PROJECT_DIR" "${PROJECT_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Download project files from GitHub
print_status "Downloading Family Dashboard files..."
if [ -z "$GITHUB_REPO" ]; then
    echo "Usage: GITHUB_REPO=username/repo-name $0"
    echo "Or edit this script to set your GitHub repository URL"
    read -p "Enter your GitHub repository (format: username/repo-name): " GITHUB_REPO
fi

if [ -n "$GITHUB_REPO" ]; then
    # Validate GitHub repo format
    if [[ ! "$GITHUB_REPO" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
        print_error "Invalid GitHub repository format. Use: username/repo-name"
        exit 1
    fi
    
    # Clone with error handling
    if git clone "https://github.com/${GITHUB_REPO}.git" .; then
        print_success "Downloaded files from GitHub repository: ${GITHUB_REPO}"
    else
        print_error "Failed to clone repository. Please check the repository name and your internet connection."
        exit 1
    fi
else
    print_error "No GitHub repository specified. Exiting."
    exit 1
fi

# Create necessary directories
mkdir -p family-photos
mkdir -p server/photos

# Install npm dependencies (if package.json exists)
if [ -f "package.json" ]; then
    print_status "Installing npm dependencies..."
    npm install
    
    print_status "Building application..."
    npm run build
else
    print_warning "package.json not found. Please copy your project files first."
fi

# Make scripts executable
print_status "Setting up executable permissions..."
chmod +x pi-startup.sh 2>/dev/null || print_warning "pi-startup.sh not found"

# Create kiosk startup script
print_status "Creating kiosk startup script..."
cat > start-kiosk.sh << 'EOF'
#!/bin/bash

# Wait for network
sleep 10

# Start Family Dashboard in kiosk mode
DISPLAY=:0 chromium-browser \
    --kiosk \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-restore-session-state \
    --disable-pinch \
    --overscroll-history-navigation=0 \
    --disable-features=TranslateUI \
    --disable-ipc-flooding-protection \
    --aggressive-cache-discard \
    --memory-pressure-off \
    --max_old_space_size=100 \
    http://localhost:5000 &
EOF

chmod +x start-kiosk.sh

# Install systemd service
if [ -f "family-dashboard.service" ]; then
    print_status "Installing systemd service..."
    sed "s/%i/$(whoami)/g" family-dashboard.service | sudo tee /etc/systemd/system/family-dashboard@$(whoami).service > /dev/null
    sudo systemctl daemon-reload
    sudo systemctl enable family-dashboard@$(whoami).service
else
    print_warning "family-dashboard.service not found. Service not installed."
fi

# Set up autostart for kiosk mode
print_status "Setting up kiosk mode autostart..."
mkdir -p /home/$(whoami)/.config/autostart

cat > /home/$(whoami)/.config/autostart/family-dashboard.desktop << EOF
[Desktop Entry]
Type=Application
Name=Family Dashboard Kiosk
Exec=${PROJECT_DIR}/start-kiosk.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Performance optimizations
print_status "Applying performance optimizations..."

# GPU memory split
if ! grep -q "gpu_mem=" /boot/config.txt; then
    echo 'gpu_mem=128' | sudo tee -a /boot/config.txt
fi

# Hardware acceleration
if ! grep -q "dtoverlay=vc4-kms-v3d" /boot/config.txt; then
    echo 'dtoverlay=vc4-kms-v3d' | sudo tee -a /boot/config.txt
fi

# Disable unnecessary services
print_status "Disabling unnecessary services..."
sudo systemctl disable bluetooth 2>/dev/null || true
sudo systemctl disable cups 2>/dev/null || true
sudo systemctl disable triggerhappy 2>/dev/null || true

# Create sample photos directory with proper permissions
print_status "Setting up photos directory..."
sudo chown -R $(whoami):$(whoami) /home/$(whoami)/family-dashboard/family-photos
sudo chmod 755 /home/$(whoami)/family-dashboard/family-photos

# Verify installation
print_status "Verifying installation..."

# Test if npm dependencies installed correctly
if [ -d "node_modules" ]; then
    print_success "Node.js dependencies installed"
else
    print_warning "Node.js dependencies not found"
fi

# Test if service is properly configured
if systemctl is-enabled family-dashboard.service &>/dev/null; then
    print_success "Systemd service enabled"
else
    print_warning "Systemd service not enabled"
fi

# Start the service for testing
print_status "Starting Family Dashboard service..."
if sudo systemctl start family-dashboard@$(whoami).service; then
    print_success "Service started successfully"
    
    # Wait a moment and check if service is running
    sleep 5
    if systemctl is-active family-dashboard@$(whoami).service &>/dev/null; then
        print_success "Service is running"
        
        # Test if web interface is accessible
        if curl -s http://localhost:5000 > /dev/null; then
            print_success "Web interface is accessible at http://localhost:5000"
        else
            print_warning "Web interface not yet accessible (may need a moment to start)"
        fi
    else
        print_warning "Service started but may not be running properly"
    fi
else
    print_warning "Failed to start service initially"
fi

print_success "Installation completed!"
echo ""
echo "=============================================="
echo "🎉 Family Dashboard Installation Complete!"
echo "=============================================="
echo ""
echo "✅ Installation Status:"
echo "   📁 Project files: ${PROJECT_DIR}"
echo "   🖼️  Photos directory: ${PROJECT_DIR}/family-photos/"
echo "   🌐 Web access: http://localhost:5000"
echo "   🌐 Network access: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "🚀 Next steps:"
echo "1. Add your family photos to: ${PROJECT_DIR}/family-photos/"
echo "2. Configure settings (weather API, etc.) via the web interface"
echo "3. Test the dashboard: curl http://localhost:5000"
echo "4. Reboot to start kiosk mode: sudo reboot"
echo ""
echo "🔧 Useful commands:"
echo "   Status: sudo systemctl status family-dashboard@$(whoami).service"
echo "   Logs: sudo journalctl -u family-dashboard@$(whoami).service -f"
echo "   Restart: sudo systemctl restart family-dashboard@$(whoami).service"
echo ""
if systemctl is-active family-dashboard@$(whoami).service &>/dev/null; then
    print_success "✅ Dashboard is currently running and ready to use!"
else
    print_warning "⚠️  Dashboard service needs to be started manually"
fi
EOF
