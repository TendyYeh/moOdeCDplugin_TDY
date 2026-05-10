#!/bin/bash
# moOde CD Auto-Eject Monitor (English Version)
# Listens for queue clearing and handles physical ejection

rm -f /tmp/cd_pending.json

WAS_PLAYING_CD=0

while true; do
    # 1. Check if the current playlist contains CDDA tracks
    if mpc -f "%file%" playlist | grep -q "cdda://"; then
        WAS_PLAYING_CD=1
    fi

    # 2. Get current MPD status and line count
    STATUS=$(mpc status)
    LINE_COUNT=$(echo "$STATUS" | wc -l)
    
    # 3. Parse playback modes
    MODE_REPEAT=$(echo "$STATUS" | grep -o 'repeat: [a-z]*' | awk '{print $2}')
    MODE_RANDOM=$(echo "$STATUS" | grep -o 'random: [a-z]*' | awk '{print $2}')
    MODE_SINGLE=$(echo "$STATUS" | grep -o 'single: [a-z]*' | awk '{print $2}')

    # 4. Check if ejection should be blocked by active modes
    DO_NOT_EJECT=0
    if [ "$MODE_REPEAT" == "on" ] || [ "$MODE_RANDOM" == "on" ] || [ "$MODE_SINGLE" == "on" ]; then
        DO_NOT_EJECT=1
    fi

    # 5. Ejection Logic
    # Triggered when: Previously playing CD AND Queue is now empty AND Modes are off
    if [ "$WAS_PLAYING_CD" -eq 1 ] && [ "$LINE_COUNT" -eq 1 ] && [ "$DO_NOT_EJECT" -eq 0 ]; then
        # Buffer for hardware to stabilize
        sleep 2
        # Clean software metadata and eject disc
        /usr/local/bin/moodecdplayer --on-eject
        /usr/bin/eject /dev/sr0
        WAS_PLAYING_CD=0
    fi

    # 6. Reset flag if queue cleared but modes are on (to prevent ghost triggers)
    if [ "$WAS_PLAYING_CD" -eq 1 ] && [ "$LINE_COUNT" -eq 1 ] && [ "$DO_NOT_EJECT" -eq 1 ]; then
        WAS_PLAYING_CD=0
    fi

    # 7. Block and wait for MPD events (playlist, player, or option changes)
    mpc idle playlist player options > /dev/null
done
