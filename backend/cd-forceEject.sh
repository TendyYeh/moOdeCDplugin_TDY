#!/bin/bash

# 1. 停止播放，釋放光碟機佔用
mpc stop

# 2. 執行 coissac / plybrd 的退片清理邏輯 (清除 UI 上的 CD 資訊)
/usr/local/bin/moodecdplayer --on-eject

# 3. 實體退片 (若你的光碟機是 cdrom 請自行更改)
eject /dev/sr0
