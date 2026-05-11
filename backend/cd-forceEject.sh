#!/bin/bash
mpc stop

/usr/local/bin/moodecdplayer --on-eject

eject /dev/sr0
