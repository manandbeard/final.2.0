
#!/bin/bash

# Quick test script for Family Dashboard installation
# Run after installation to verify everything is working

echo "🔍 Family Dashboard - Quick Test"
echo "================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Test 1: Check if project directory exists
print_test "Checking project directory..."
if [ -d "/home/nhell/family-dashboard" ]; then
    print_pass "Project directory exists"
else
    print_fail "Project directory not found"
    exit 1
fi

# Test 2: Check if Node.js is installed
print_test "Checking Node.js installation..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_pass "Node.js is installed: $NODE_VERSION"
else
    print_fail "Node.js not found"
fi

# Test 3: Check if npm dependencies are installed
print_test "Checking npm dependencies..."
cd /home/nhell/family-dashboard
if [ -d "node_modules" ]; then
    print_pass "npm dependencies installed"
else
    print_fail "npm dependencies not found"
fi

# Test 4: Check systemd service
print_test "Checking systemd service..."
if systemctl is-enabled family-dashboard.service &>/dev/null; then
    print_pass "Service is enabled"
    if systemctl is-active family-dashboard.service &>/dev/null; then
        print_pass "Service is running"
    else
        print_fail "Service is not running"
        print_info "Try: sudo systemctl start family-dashboard.service"
    fi
else
    print_fail "Service is not enabled"
    print_info "Try: sudo systemctl enable family-dashboard.service"
fi

# Test 5: Check web interface
print_test "Testing web interface..."
sleep 2
if curl -s http://localhost:5000 > /dev/null; then
    print_pass "Web interface is accessible"
else
    print_fail "Web interface not accessible"
    print_info "Check service status: sudo systemctl status family-dashboard.service"
fi

# Test 6: Check photos directory
print_test "Checking photos directory..."
if [ -d "/home/nhell/family-dashboard/family-photos" ]; then
    PHOTO_COUNT=$(ls -1 /home/nhell/family-dashboard/family-photos | wc -l)
    print_pass "Photos directory exists ($PHOTO_COUNT files)"
else
    print_fail "Photos directory not found"
fi

# Test 7: Check kiosk setup
print_test "Checking kiosk setup..."
if [ -f "/home/nhell/.config/autostart/family-dashboard.desktop" ]; then
    print_pass "Kiosk autostart configured"
else
    print_fail "Kiosk autostart not configured"
fi

echo ""
echo "🏁 Test Summary"
echo "==============="
echo "Dashboard URL: http://localhost:5000"
echo "Network URL: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "If tests failed, check the installation logs:"
echo "sudo journalctl -u family-dashboard.service -f"
