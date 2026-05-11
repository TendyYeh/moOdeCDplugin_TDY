#!/bin/bash
# moOdeCDPlay V0.1 script

# make drive readable, just in case
# (allow for odd enumeration)
if [ -b /dev/sr0 ]; then
   chmod 644 /dev/sr0
   /usr/bin/eject -x 2 /dev/sr0
elif [ -b /dev/sr1 ]; then
   chmod 644 /dev/sr1
   /usr/bin/eject -x 2 /dev/sr1
else
  exit 1
fi

# 讓爬蟲與抓取邏輯脫離 udev 的控制，丟給系統背景執行
systemd-run --no-block /usr/local/bin/moodecdplayer --on-insert > /tmp/udev_cd.log 2>&1
