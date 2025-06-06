
# Raspberry Pi Troubleshooting Guide

## Common Installation Issues

### 1. Service Won't Start

**Check service status:**
```bash
sudo systemctl status family-dashboard.service
```

**Check logs:**
```bash
sudo journalctl -u family-dashboard.service -f
```

**Common fixes:**
```bash
# Restart the service
sudo systemctl restart family-dashboard.service

# Reload systemd if you modified the service file
sudo systemctl daemon-reload
sudo systemctl enable family-dashboard.service
```

### 2. Web Interface Not Accessible

**Test locally:**
```bash
curl http://localhost:5000
```

**Check if port is in use:**
```bash
sudo netstat -tlnp | grep :5000
```

**Check firewall (if enabled):**
```bash
sudo ufw status
sudo ufw allow 5000
```

### 3. npm/Node.js Issues

**Verify Node.js version:**
```bash
node --version  # Should be 18.x or higher
npm --version
```

**Reinstall dependencies:**
```bash
cd /home/nhell/family-dashboard
rm -rf node_modules package-lock.json
npm install
```

**Clear npm cache:**
```bash
npm cache clean --force
```

### 4. Permission Issues

**Fix ownership:**
```bash
sudo chown -R nhell:nhell /home/nhell/family-dashboard
```

**Fix permissions:**
```bash
chmod 755 /home/nhell/family-dashboard
chmod +x /home/nhell/family-dashboard/*.sh
```

### 5. Memory Issues

**Check memory usage:**
```bash
free -h
htop
```

**Increase GPU memory split:**
```bash
sudo raspi-config
# Advanced Options > Memory Split > Set to 256
```

**Add swap space:**
```bash
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Change CONF_SWAPSIZE=100 to CONF_SWAPSIZE=1024
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

### 6. Display/Kiosk Issues

**Test browser manually:**
```bash
DISPLAY=:0 chromium-browser http://localhost:5000
```

**Check X server:**
```bash
echo $DISPLAY
ps aux | grep X
```

**Reset autostart:**
```bash
rm /home/nhell/.config/autostart/family-dashboard.desktop
# Re-run install script or recreate manually
```

### 7. Photo Loading Issues

**Check photos directory:**
```bash
ls -la /home/nhell/family-dashboard/family-photos/
```

**Fix photo permissions:**
```bash
sudo chown -R nhell:nhell /home/nhell/family-dashboard/family-photos
chmod 755 /home/nhell/family-dashboard/family-photos
chmod 644 /home/nhell/family-dashboard/family-photos/*
```

**Test photo endpoint:**
```bash
curl http://localhost:5000/api/photos
```

## Performance Optimization

### 1. Disable Unnecessary Services
```bash
sudo systemctl disable bluetooth
sudo systemctl disable cups
sudo systemctl disable triggerhappy
sudo systemctl disable hciuart
```

### 2. Update Boot Config
Add to `/boot/config.txt`:
```
# GPU memory
gpu_mem=256

# Hardware acceleration
dtoverlay=vc4-kms-v3d

# Disable WiFi/Bluetooth if using ethernet
dtoverlay=disable-wifi
dtoverlay=disable-bt
```

### 3. Browser Optimizations
The kiosk script already includes optimizations, but you can add:
```bash
--memory-pressure-off
--max_old_space_size=512
--aggressive-cache-discard
```

## Quick Recovery Commands

**Complete service restart:**
```bash
sudo systemctl stop family-dashboard.service
cd /home/nhell/family-dashboard
npm run build
sudo systemctl start family-dashboard.service
```

**Reset to clean state:**
```bash
cd /home/nhell
sudo rm -rf family-dashboard.backup.*
git clone https://github.com/yourusername/family-dashboard.git
cd family-dashboard
npm install
npm run build
sudo systemctl restart family-dashboard.service
```

**View real-time logs:**
```bash
sudo journalctl -u family-dashboard.service -f
```

## Getting Help

1. Run the quick test script: `./quick-test.sh`
2. Check service logs: `sudo journalctl -u family-dashboard.service -f`
3. Verify system resources: `htop` and `free -h`
4. Test manual startup: `cd /home/nhell/family-dashboard && npm start`
