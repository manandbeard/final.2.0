
# Family Dashboard

A beautiful, responsive family dashboard designed for Raspberry Pi displays. Shows weather, calendar events, photos, and notes in an elegant layout.

## Features

- 📸 **Photo Slideshow** - Display family photos in a rotating slideshow
- 🗓️ **Calendar Integration** - Show upcoming events from calendar feeds
- 🌤️ **Weather Display** - Current weather conditions
- 📝 **Family Notes** - Shared to-do lists and notes
- 🎨 **Customizable Colors** - Personalize your dashboard appearance
- 📱 **Responsive Design** - Works on various screen sizes
- 🖥️ **Kiosk Mode** - Full-screen display perfect for wall-mounted screens

## Quick Installation on Raspberry Pi

1. **One-line installation:**
   ```bash
   curl -sSL https://raw.githubusercontent.com/manandbeard/final.2.0/main/install-pi.sh | bash
   ```

2. **Manual installation:**
   ```bash
   git clone https://github.com/manandbeard/final.2.0.git
   cd final.2.0
   chmod +x install-pi.sh
   ./install-pi.sh
   ```

## What the Installation Does

- Installs Node.js 18.x and dependencies
- Sets up the Family Dashboard service
- Configures kiosk mode for full-screen display
- Creates photo directories
- Optimizes Raspberry Pi performance
- Sets up auto-start on boot

## After Installation

1. **Add Photos:** Copy your family photos to `/home/YOUR_USERNAME/family-dashboard/family-photos/`
2. **Access Dashboard:** Open `http://YOUR_PI_IP:5000` in any browser
3. **Configure Settings:** Click the settings gear to customize weather, colors, etc.
4. **Reboot for Kiosk Mode:** `sudo reboot` to start full-screen kiosk mode

## Supported Systems

- Raspberry Pi 4 (recommended)
- Raspberry Pi 3B+
- Any Linux system with Node.js support

## Troubleshooting

See [PI_INSTALLATION.md](PI_INSTALLATION.md) and [pi-troubleshooting.md](pi-troubleshooting.md) for detailed installation guides and troubleshooting.

## Development

Built with:
- **Frontend:** React, TypeScript, Tailwind CSS
- **Backend:** Express.js, Node.js
- **Features:** Weather API integration, iCal support, photo management

## License

MIT License - Feel free to customize for your family's needs!
