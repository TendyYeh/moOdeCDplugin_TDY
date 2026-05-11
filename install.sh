#!/bin/bash
# moOde CD Player Pro Plugin Setup Script (V2 - Interactive Modal Edition)
# Developed for moOde 10.x integration
# Target Device: /dev/sr0

echo "-------------------------------------------------------"
echo "Starting moOde CD Player Pro Plugin Installation..."
echo "-------------------------------------------------------"

# # 1. 安裝系統依賴套件
# echo "[1/7] Installing system dependencies and Python libraries..."
# sudo apt update
# sudo apt -y install libcdio-dev libcdio-utils python3-musicbrainzngs python3-cdio \
#                   python3-requests python3-libdiscid swig cd-discid mpc eject setcd

# # 安裝 python-mpd2 (針對 Debian Bookworm)
# sudo pip3 install -U python-mpd2 --break-system-packages

# 2. 部署後端執行腳本
echo "[2/7] Deploying backend scripts to /usr/local/bin..."
# 複製主要執行檔與新增的 MPD 注入引擎
sudo cp ./backend/moodecdplayer.py /usr/local/bin/moodecdplayer
sudo cp ./backend/addaudiocd.sh /usr/local/bin/
sudo cp ./backend/remaudiocd.sh /usr/local/bin/
sudo cp ./backend/cd-autoeject.sh /usr/local/bin/
sudo cp ./backend/cd_mpd_inject.py /usr/local/bin/

# 賦予執行權限
sudo chmod +x /usr/local/bin/moodecdplayer
sudo chmod +x /usr/local/bin/addaudiocd.sh
sudo chmod +x /usr/local/bin/remaudiocd.sh
sudo chmod +x /usr/local/bin/cd-autoeject.sh
sudo chmod +x /usr/local/bin/cd_mpd_inject.py

# 3. 建立 CD Metadata 快取目錄
echo "[3/7] Setting up CD metadata cache directory..."
sudo mkdir -p /var/lib/moode_cd_library
sudo chown www-data:www-data /var/lib/moode_cd_library
sudo chmod 775 /var/lib/moode_cd_library

# 4. 部署 PHP 指令橋樑
echo "[4/7] Deploying PHP bridge scripts to /var/www/command/..."
sudo cp ./ui/php/EjectCD.php /var/www/command/
sudo cp ./ui/php/CheckCDState.php /var/www/command/
sudo cp ./ui/php/ConfirmCDImport.php /var/www/command/

# 設定 www-data 權限
sudo chown www-data:www-data /var/www/command/EjectCD.php /var/www/command/CheckCDState.php /var/www/command/ConfirmCDImport.php
sudo chmod 755 /var/www/command/EjectCD.php /var/www/command/CheckCDState.php /var/www/command/ConfirmCDImport.php

# 5. 部署 UI 資源並注入 header.php
echo "[5/7] Deploying UI scripts and injecting into header.php..."
sudo cp ./ui/js/inject-eject-btn.js /var/www/js/
sudo cp ./ui/js/cd-import-modal.js /var/www/js/
sudo cp ./ui/css/cd-import-modal.css /var/www/css/
sudo cp ./ui/html/cd-import-modal.html /var/www/templates/

sudo chown www-data:www-data /var/www/js/inject-eject-btn.js
sudo chown www-data:www-data /var/www/js/cd-import-modal.js
sudo chown www-data:www-data /var/www/css/cd-import-modal.css
sudo chown www-data:www-data /var/www/templates/cd-import-modal.html


# 注入 CSS 連結到 header.php (在 styles.min.css 之後)
if ! grep -q "cd-import-modal.css" /var/www/header.php; then
    sudo sed -i '/styles.min.css/a \\    <link rel="stylesheet" href="/css/cd-import-modal.css">' /var/www/header.php
fi


# 注入退片按鈕 JS (使用 lib.min.js 為錨點)
if ! grep -q "inject-eject-btn.js" /var/www/header.php; then
    sudo sed -i '/lib.min.js/a \\    <script src="/js/inject-eject-btn.js" defer></script>' /var/www/header.php
    echo "  -> Injected Eject Button script."
fi

# 注入 CD 匯入彈窗 JS (緊接在退片 JS 之後)
if ! grep -q "cd-import-modal.js" /var/www/header.php; then
    sudo sed -i '/inject-eject-btn.js/a \\    <script src="/js/cd-import-modal.js" defer></script>' /var/www/header.php
    echo "  -> Injected CD Import Modal script."
fi

# 6. 配置 Sudoers 白名單 (www-data)
echo "[6/7] Configuring Sudoers for Interactive Import and Ejection..."
# 建立一個包含退片與 MPD 注入權限的設定檔
cat <<EOF > /tmp/moodecdplayer_sudoers
www-data ALL=(ALL) NOPASSWD: /usr/local/bin/cd-autoeject.sh
www-data ALL=(ALL) NOPASSWD: /usr/local/bin/cd_mpd_inject.py
EOF

sudo cp /tmp/moodecdplayer_sudoers /etc/sudoers.d/moodecdplayer
sudo chown root:root /etc/sudoers.d/moodecdplayer
sudo chmod 0440 /etc/sudoers.d/moodecdplayer
rm /tmp/moodecdplayer_sudoers

# 7. 配置 udev 規則
echo "[7/7] Setting up udev hardware detection rules..."
sudo cp configs/99-srX.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules


# echo "[7/7] Configuring udev rules for automatic detection..."
# UDEV_RULE='/etc/udev/rules.d/99-addaudiocd.rules'
# echo 'SUBSYSTEM=="block", KERNEL=="sr0", ACTION=="change", ENV{ID_CDROM_MEDIA_TRACK_COUNT_AUDIO}=="?*", RUN+="/usr/local/bin/addaudiocd.sh /dev/sr0"' | sudo tee $UDEV_RULE > /dev/null
# sudo udevadm control --reload-rules

echo "-------------------------------------------------------"
echo "Installation Complete!"
echo "Please refresh your moOde Web UI and insert a CD to test."
echo "-------------------------------------------------------"