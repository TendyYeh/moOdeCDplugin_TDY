#!/bin/bash
# moOde CD Player Pro Plugin Setup Script
# Developed for moOde 10.x integration
# Target Device: /dev/sr0

echo "-------------------------------------------------------"
echo "Starting moOde CD Player Pro Plugin Installation..."
echo "-------------------------------------------------------"

# 1. Install System Dependencies
echo "[1/6] Installing system dependencies and Python libraries..."
sudo apt update
sudo apt -y install libcdio-dev libcdio-utils python3-musicbrainzngs python3-cdio \
                  python3-requests python3-libdiscid swig cd-discid mpc eject setcd

# Install python-mpd2 with system package override for Debian Bookworm
sudo pip3 install -U python-mpd2 --break-system-packages

# 2. Deploy Executable Scripts
echo "[2/6] Deploying backend scripts to /usr/local/bin..."
# Copy all executable scripts from backend folder
sudo cp ./backend/moodecdplayer.py /usr/local/bin/moodecdplayer
sudo cp ./backend/addaudiocd.sh /usr/local/bin/
sudo cp ./backend/remaudiocd.sh /usr/local/bin/
sudo cp ./backend/cd-autoeject.sh /usr/local/bin/
sudo cp ./backend/cd_mpd_inject.py /usr/local/bin/

# Set executable permissions for all deployed scripts
sudo chmod +x /usr/local/bin/moodecdplayer
sudo chmod +x /usr/local/bin/addaudiocd.sh
sudo chmod +x /usr/local/bin/remaudiocd.sh
sudo chmod +x /usr/local/bin/cd-autoeject.sh
sudo chmod +x /usr/local/bin/cd_mpd_inject.py

# 3. Configure Systemd Services
echo "[3/6] Configuring Systemd services..."
sudo cp configs/*.service /etc/systemd/system/

# Reload daemon and enable the auto-eject monitor service
sudo systemctl daemon-reload
sudo systemctl enable cd-autoeject.service
sudo systemctl restart cd-autoeject.service

# 4. Configure Hardware Detection (udev)
echo "[4/6] Setting up udev hardware detection rules..."
sudo cp configs/99-srX.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules

# 5. Deploy UI Eject Button & PHP Backend
echo "[5/6] Deploying UI Eject Button and PHP Backend..."
sudo cp ./ui/css/cd-import-modal.css /var/www/css/
sudo cp ./ui/html/cd-import-modal.html /var/www/templates/

sudo chown www-data:www-data /var/www/css/cd-import-modal.css
sudo chown www-data:www-data /var/www/templates/cd-import-modal.html
# Copy PHP backend and set permissions (Updated to match your path: ./ui/php/)
sudo cp ./ui/php/EjectCD.php /var/www/command/EjectCD.php
sudo chown www-data:www-data /var/www/command/EjectCD.php
sudo chmod 755 /var/www/command/EjectCD.php

sudo cp ./ui/php/CheckCDState.php /var/www/command/CheckCDState.php
sudo chown www-data:www-data /var/www/command/CheckCDState.php
sudo chmod 755 /var/www/command/CheckCDState.php

sudo cp ./ui/php/ConfirmCDImport.php /var/www/command/ConfirmCDImport.php
sudo chown www-data:www-data /var/www/command/ConfirmCDImport.php
sudo chmod 755 /var/www/command/ConfirmCDImport.php

# Copy JS frontend and set permissions
sudo cp ./ui/js/inject-eject-btn.js /var/www/js/inject-eject-btn.js
sudo chown www-data:www-data /var/www/js/inject-eject-btn.js

sudo cp ./ui/js/cd-import-modal.js /var/www/js/cd-import-modal.js
sudo chown www-data:www-data /var/www/js/cd-import-modal.js

# NEW STRATEGY: Inject JS into header.php instead of indextpl
# We target the "Common JS" comment for consistent placement
if ! grep -q "inject-eject-btn.js" /var/www/header.php; then
    sudo sed -i '/lib.min.js/a \    <script src="/js/inject-eject-btn.js" defer></script>' /var/www/header.php
    echo "  -> Injected eject button script into header.php."
else
    echo "  -> Eject button script already injected into header.php. Skipping."
fi

if ! grep -q "cd-import-modal.css" /var/www/header.php; then
    sudo sed -i '/styles.min.css/a \\    <link rel="stylesheet" href="/css/cd-import-modal.css">' /var/www/header.php
fi

if ! grep -q "cd-import-modal.js" /var/www/header.php; then
    sudo sed -i '/inject-eject-btn.js/a \\    <script src="/js/cd-import-modal.js" defer></script>' /var/www/header.php
    echo "  -> Injected CD Import Modal script."
fi

# 6. Configure Sudoers for Web Server (www-data)
echo "[6/6] Configuring Sudoers for Web Server to allow ejection..."
# Grant www-data permission to execute the eject script without password
# (Updated to match your path: ./ui/php/)
sudo cp ./ui/php/moodecdplayer_sudoers /etc/sudoers.d/moodecdplayer
sudo chown root:root /etc/sudoers.d/moodecdplayer
sudo chmod 0440 /etc/sudoers.d/moodecdplayer

## 7. Persistent Hardware Button Unlock (Optional / Commented out)
#echo "[7/7] Updating worker.sh for persistent hardware unlock..."
## Check if the eject command already exists to prevent duplicate entries
#if ! grep -q "eject -i off" /var/www/command/worker.sh; then
#    # Insert unlock command before 'exit 0' in moOde's worker script
#    sudo sed -i '/exit 0/i /usr/bin/eject -i off /dev/sr0 > /dev/null 2>&1' /var/www/command/worker.sh
#    echo "Added hardware unlock to worker.sh."
#else
#    echo "Hardware unlock already configured in worker.sh. Skipping."
#fi

echo "-------------------------------------------------------"
echo "Installation Complete! Please refresh your browser (Ctrl+F5)."
echo "-------------------------------------------------------"