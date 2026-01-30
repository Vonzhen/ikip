# -*- coding: utf-8 -*-
import requests
import hashlib
import time
import json

class IkuaiClient:
    def __init__(self, url, username, password, limit=4000):
        self.url = url.rstrip('/')
        self.username = username
        self.password = password
        self.limit = int(limit) # 确保阈值是整数
        self.session = requests.Session()
        self.session.headers.update({"Content-Type": "application/json"})

    def login(self):
        """登录仪式：MD5 + 时间戳 (100% 还原原版逻辑)"""
        print(f"【外交】正在敲击堡垒大门: {self.url}")
        try:
            ts = str(int(time.time() * 1000))
            # 密码加密逻辑：MD5(密码)
            passwd_md5 = hashlib.md5(self.password.encode('utf-8')).hexdigest()
            data = {
                "username": self.username,
                "passwd": passwd_md5,
                "pass": ts,
                "remember_password": 0
            }
            r = self.session.post(f"{self.url}/Action/login", json=data, timeout=15)
            res = r.json()
            if res.get("Result") == 10000:
                print("【外交】守备官已确认身份，大门开启。")
                # 更新 Cookie
                self.session.cookies.update(r.cookies)
                return True
            print(f"【外交】拒绝进入: {res.get('ErrMsg')}")
        except Exception as e:
            print(f"【外交】登录遭遇意外: {e}")
        return False

    def get_existing_ids(self, group_name):
        """侦察：获取指定名称的所有规则 ID"""
        try:
            r = self.session.post(f"{self.url}/Action/call", json={
                "func_name": "custom_isp",
                "action": "show",
                "param": {"TYPE": "data"}
            }, timeout=15)
            res = r.json()
            # 筛选出名字匹配的条目，提取 ID
            ids = [item['id'] for item in res.get('Data', {}).get('data', []) if item['name'] == group_name]
            return ids
        except Exception as e:
            print(f"【侦察】获取现有防线失败: {e}")
            return []

    def sync_rule(self, group_name, ip_list):
        """战术执行：动态分发与对齐"""
        total = len(ip_list)
        # 1. 动态切片 (Chunking)
        # 向上取整计算组数，例如 7500/4000 = 2组
        step = self.limit
        chunks = [ip_list[i:i + step] for i in range(0, total, step)]
        
        print(f"【战术】IP总数 {total}，阈值 {self.limit}，已切分为 {len(chunks)} 个方阵。")

        # 2. 获取现有 ID (Mapping)
        existing_ids = self.get_existing_ids(group_name)
        print(f"【战术】堡垒内现有同名防线 {len(existing_ids)} 道。")

        # 3. 对齐执行 (多退少补)
        # 循环次数取两者最大值，确保覆盖所有情况
        max_ops = max(len(chunks), len(existing_ids))
        success_count = 0

        for i in range(max_ops):
            time.sleep(0.5) # 战术停顿，防止并发冲突

            # 情况 A: 有新数据，也有旧 ID -> 【加固 (Edit)】
            if i < len(chunks) and i < len(existing_ids):
                print(f"【动作】正在加固第 {i+1} 道防线 (Edit ID: {existing_ids[i]})...")
                res = self._call_api("edit", {
                    "name": group_name,
                    "ipgroup": ",".join(chunks[i]),
                    "id": int(existing_ids[i]) # ★关键：强制整形
                })
                if self._check_success(res): success_count += 1

            # 情况 B: 有新数据，但没 ID -> 【扩建 (Add)】
            elif i < len(chunks) and i >= len(existing_ids):
                print(f"【动作】正在新建第 {i+1} 道防线 (Add)...")
                res = self._call_api("add", {
                    "name": group_name,
                    "ipgroup": ",".join(chunks[i])
                })
                if self._check_success(res): success_count += 1

            # 情况 C: 没数据了，还有旧 ID -> 【裁撤 (Del)】
            elif i >= len(chunks) and i < len(existing_ids):
                print(f"【动作】正在裁撤多余防线 (Del ID: {existing_ids[i]})...")
                res = self._call_api("del", {
                    "id": int(existing_ids[i])
                })
                if self._check_success(res): 
                    print(f"【动作】旧部已裁撤。")
                    # 删除操作不计入 success_count，因为它不是数据注入

        # 验证：成功的注入次数必须等于切片数
        return success_count == len(chunks)

    def _call_api(self, action, param):
        try:
            return self.session.post(f"{self.url}/Action/call", json={
                "func_name": "custom_isp",
                "action": action,
                "param": param
            }, timeout=20).json()
        except Exception as e:
            return {"Result": -1, "ErrMsg": str(e)}

    def _check_success(self, res):
        # 兼容 Success 文本返回
        if res.get("Result") == 10000 or res.get("ErrMsg") == "Success":
            return True
        print(f"【失败】堡垒反馈: {res.get('ErrMsg')}")
        return False
