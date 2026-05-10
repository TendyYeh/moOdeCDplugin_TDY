#!/usr/bin/python3
import json
import os
from mpd import MPDClient

CONFIRMED_FILE = "/tmp/cd_confirmed.json"

def inject_to_mpd():
    if not os.path.exists(CONFIRMED_FILE):
        return

    try:
        # 讀取合併後的最終資料
        with open(CONFIRMED_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        album = data.get("album", "Unknown Album")
        artist = data.get("artist", "Unknown Artist")
        tracks = data.get("tracks", [])

        # 連線至 MPD
        client = MPDClient()
        client.connect("localhost", 6600)
        
        # 清空現有播放清單 (依照您之前的邏輯)
        client.clear()

        # 將音軌一首首加入並寫入使用者自訂的標籤
        for i, track_title in enumerate(tracks):
            track_num = i + 1
            track_url = f"cdda:///{track_num}"
            try:
                trk_id = client.addid(track_url)
                # 寫入 Metadata 標籤
                client.addtagid(trk_id, "album", album)
                client.addtagid(trk_id, "albumartist", artist)
                client.addtagid(trk_id, "artist", artist)
                client.addtagid(trk_id, "title", track_title)
                client.addtagid(trk_id, "track", str(track_num))
            except Exception as e:
                pass # 忽略單軌加入失敗的錯誤

        # 開始播放並斷開連線
        client.play()
        client.close()
        client.disconnect()
        
        # 處理完畢後刪除確認檔
        os.remove(CONFIRMED_FILE)

        # 新增這兩行：順手把 pending 檔也刪掉！
        if os.path.exists("/tmp/cd_pending.json"):
            os.remove("/tmp/cd_pending.json")

    except Exception as e:
        pass

if __name__ == "__main__":
    inject_to_mpd()
