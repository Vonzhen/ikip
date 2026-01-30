# -*- coding: utf-8 -*-
import requests
import time

def get_timestamp():
    return time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())

def send_raven(cfg, msg):
    """发送 Telegram 通知"""
    tg = cfg.get("telegram", {})
    if not tg.get("enabled"):
        return

    token = tg.get("bot_token")
    chat_id = tg.get("chat_id")
    loc_name = cfg.get("location_name", "iKuai")
    
    if not token or not chat_id: return

    try:
        url = f"https://api.telegram.org/bot{token}/sendMessage"
        text = f"🛡️ *【{loc_name}】哨报*\n━━━━━━━━━━━━━━\n{msg}\n━━━━━━━━━━━━━━\n❄️ _ikip v2.0 - 凛冬将至_"
        requests.post(url, json={
            "chat_id": chat_id, 
            "text": text, 
            "parse_mode": "Markdown"
        }, timeout=10)
    except Exception as e:
        print(f"【渡鸦】信使迷路了: {e}")
