#!/usr/bin/python3
import json
import os
from mpd import MPDClient
import sys

CONFIRMED_FILE = "/tmp/cd_confirmed.json"

def inject_to_mpd():
    if not os.path.exists(CONFIRMED_FILE):
        print(f"錯誤：找不到檔案 {CONFIRMED_FILE}")
        return

    try:
        with open(CONFIRMED_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        album = data.get("album", "Unknown Album")
        artist = data.get("artist", "Unknown Artist")
        tracks = data.get("tracks", [])

        print(f"成功讀取 JSON，準備匯入: {album} - {artist}")

        client = MPDClient()
        client.connect("localhost", 6600)
        client.clear()
        print("成功連線到 MPD 並清空播放清單")

        for i, track_title in enumerate(tracks):
            track_num = i + 1
            track_url = f"cdda:///{track_num}"
            try:
                trk_id = client.addid(track_url)
                client.addtagid(trk_id, "album", album)
                client.addtagid(trk_id, "albumartist", artist)
                client.addtagid(trk_id, "artist", artist)
                client.addtagid(trk_id, "title", track_title)
                client.addtagid(trk_id, "track", str(track_num))
                print(f"成功加入音軌: {track_num}")
            except Exception as inner_e:
                print(f"加入音軌 {track_num} 時發生錯誤: {inner_e}")

        client.play()
        client.close()
        client.disconnect()
        print("成功開始播放！")
        
        # 清理暫存檔
        os.remove(CONFIRMED_FILE)
        if os.path.exists("/tmp/cd_pending.json"):
            os.remove("/tmp/cd_pending.json")
        print("暫存檔清理完畢。")

    except Exception as e:
        print(f"發生嚴重錯誤，程式中斷: {e}")

if __name__ == "__main__":
    inject_to_mpd()