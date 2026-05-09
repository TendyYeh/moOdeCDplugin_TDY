#!/bin/bash
# moOde CD Player Pro Plugin Setup Script
# Developed for moOde 10.x integration
# Target Device: /dev/sr0

echo "-------------------------------------------------------"
echo "Starting moOde CD Player Pro Plugin Installation..."
echo "-------------------------------------------------------"

# 1. Install System Dependencies
echo "[1/5] Installing system dependencies and Python libraries..."
sudo apt update
sudo apt -y install libcdio-dev libcdio-utils python3-musicbrainzngs python3-cdio \
                  python3-requests python3-libdiscid swig cd-discid mpc eject setcd

# Install python-mpd2 with system package override for Debian Bookworm
sudo pip3 install -U python-mpd2 --break-system-packages

# 2. Deploy Executable Scripts
echo "[2/5] Deploying backend scripts to /usr/local/bin..."
# Copy all scripts from backend folder
sudo cp backend/* /usr/local/bin/

# Set executable permissions for all deployed scripts
sudo chmod +x /usr/local/bin/moodecdplayer
sudo chmod +x /usr/local/bin/addaudiocd.sh
sudo chmod +x /usr/local/bin/remaudiocd.sh
sudo chmod +x /usr/local/bin/cd-autoeject.sh

# 3. Configure Systemd Services
echo "[3/5] Configuring Systemd services..."
sudo cp configs/*.service /etc/systemd/system/

# Reload daemon and enable the auto-eject monitor service
sudo systemctl daemon-reload
sudo systemctl enable cd-autoeject.service
sudo systemctl restart cd-autoeject.service

# 4. Configure Hardware Detection (udev)
echo "[4/5] Setting up udev hardware detection rules..."
sudo cp configs/99-srX.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules

## 5. Persistent Hardware Button Unlock
#echo "[5/5] Updating worker.sh for persistent hardware unlock..."
## Check if the eject command already exists to prevent duplicate entries
#if ! grep -q "eject -i off" /var/www/command/worker.sh; then
#    # Insert unlock command before 'exit 0' in moOde's worker script
#    sudo sed -i '/exit 0/i /usr/bin/eject -i off /dev/sr0 > /dev/null 2>&1' /var/www/command/worker.sh
#    echo "Added hardware unlock to worker.sh."
#else
#    echo "Hardware unlock already configured in worker.sh. Skipping."
#fi

echo "-------------------------------------------------------"
echo "Installation Successful!"
echo "Your CD drive is now limited to 2x speed for silence."
echo "Auto-eject is active (protected by playback modes)."
echo "-------------------------------------------------------"
