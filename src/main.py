# -*- coding: utf-8 -*-
import os
import sys
import json
import hashlib
import requests
from utils import send_raven, get_timestamp
from strategies.ikuai import IkuaiClient

CONFIG_FILE = "/etc/ikip/config.json"
CACHE_FILE = "/var/lib/ikip/last_hash.json"

def load_config():
    if not os.path.exists(CONFIG_FILE):
        print("【错误】未找到法典 (config.json)。")
        sys.exit(1)
    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)

def get_remote_ip_list(url):
    print(f"【侦察】正在前往 {url} 获取名录...")
    try:
        r = requests.get(url, timeout=30)
        r.raise_for_status()
        text = r.text.strip()
        return [l.strip() for l in text.splitlines() if l.strip()], text
    except Exception as e:
        print(f"【侦察】下载失败: {e}")
        return None, None

def main():
    # --- 1. 军令：检查是否强制执行 ---
    # 只要参数里有 force，就标记为强制模式
    force_update = False
    if len(sys.argv) > 1 and sys.argv[1] == "force":
        force_update = True
        print(f"[{get_timestamp()}] 【军令】领主下令强制巡逻，无视哈希缓存！")

    cfg = load_config()
    rule_cfg = cfg.get("rule_settings", {})
    
    # 2. 获取 IP 数据
    source_url = rule_cfg.get("source_url")
    ips, raw_text = get_remote_ip_list(source_url)
    if not ips: return

    # 3. 哈希比对逻辑
    current_hash = hashlib.md5(raw_text.encode('utf-8')).hexdigest()
    os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
    
    # ★关键：只有在【非强制】模式下，才检查哈希
    if not force_update:
        last_hash = ""
        if os.path.exists(CACHE_FILE):
            with open(CACHE_FILE, 'r') as f: last_hash = json.load(f).get("hash", "")

        if current_hash == last_hash:
            print(f"[{get_timestamp()}] 【静默】疆域无变动，哨兵继续潜伏。")
            return
    
    if not force_update:
        print(f"[{get_timestamp()}] 【警报】发现名录更迭！准备行动。")
    
    # 4. 初始化并执行
    ik = cfg.get("ikuai", {})
    client = IkuaiClient(
        url=ik.get("url"),
        username=ik.get("user"),
        password=ik.get("pass"),
        limit=rule_cfg.get("max_per_group", 4000)
    )

    if client.login():
        group_name = rule_cfg.get("group_name", "国内IP")
        if client.sync_rule(group_name, ips):
            # 成功后更新哈希
            with open(CACHE_FILE, 'w') as f: json.dump({"hash": current_hash}, f)
            msg = f"✅ 规则 [{group_name}] 同步成功！\n📜 共计 {len(ips)} 条疆域已刻录。"
            print(msg)
            # 强制模式下也发送通知，以便确认结果
            send_raven(cfg, msg)
        else:
            msg = f"❌ 规则 [{group_name}] 同步失败！"
            print(msg)
            send_raven(cfg, msg)
    else:
        print("【致命】无法登录爱快。")

if __name__ == "__main__":
    main()
