

---

# ⚔️ ikip: 凛冬哨兵 (Winter Sentinel)

> **“长夜将至，我从今开始守望。”**
> **ikip** 是一个专为 **爱快 (iKuai)** 路由设计的、工程化的国内 IP 分流规则自动化管理工具。

## 📖 简介 (Introduction)

在 **iKuai (L3) + OpenWrt (L7)** 的双路由架构中，我们需要将“国内流量”直接通过爱快网关出站，仅将“海外流量”转发至 OpenWrt。这依赖于爱快内部维护一份精准的 **CN-IP 分流规则**。

然而，随着国内 IP 列表膨胀至 7400+ 条，原生爱快面临 **5000 条规则上限** 和 **API 字节限制** 的双重壁垒。**ikip** 通过标准化的架构和智能的分片算法，完美解决了这一问题。

## ✨ 核心特性 (Features)

* **🧱 动态分片 (Dynamic Chunking)**: 自动突破 5000 条限制。根据 IP 总数智能计算分组（如 7500 条自动分为 2 组），支持多退少补。
* **🛡️ 鲁棒性设计**: 内置哈希缓存（无更迭不交互）、API 类型强校验（杜绝 `Success` 级误报）、战术停顿（防止并发冲突）。
* **🦅 指挥官面板**: 提供沉浸式的 CLI 交互终端，支持一键更新、参数调整、脚本热升级。
* **📨 渡鸦传信**: 集成 Telegram Bot，实时汇报防线变动与异常。
* **🏗️ 标准化架构**: 遵循 Linux FHS 标准，支持 OpenWrt / Alpine / Debian 等环境，自动管理依赖。

## 🚀 快速开始 (Quick Start)

### 一键部署

在 OpenWrt 或 Linux 终端执行以下命令（自动安装 Python3/jq 等依赖）：

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Vonzhen/ikip/master/install.sh)"

```

### 交互配置

安装过程中，脚本会引导您配置：

1. 爱快地址与账号密码。
2. **IP 源地址** (支持自定义 URL)。
3. **分流阈值** (默认 4000，建议保持)。
4. Telegram 通知参数。

## 🎮 使用指南 (Usage)

安装完成后，直接在终端输入 `ikip` 唤醒指挥官面板：

```text
=== ikip v2.1: 积木指挥官 (Vaelen) ===
 1) 🦅 巡航长城 (立即更新 IP 规则)
 2) 📋 检阅军册 (查看当前配置)
 3) ⚙️  战术调整 (修改源/阈值)
 4) 📨 渡鸦传信 (开启/关闭通知)
 5) 🔄 哨兵进化 (更新脚本内核)
 0) ❌ 焚毁契约 (完全卸载)

```

**定时任务**: 安装脚本已自动添加 Crontab，默认于 **每月 1 日 04:00** 自动执行巡逻。

## ⚙️ 配置文件

配置文件位于 `/etc/ikip/config.json`：

```json
{
  "location_name": "家",
  "ikuai": {
    "url": "http://10.10.10.1",
    "user": "admin",
    "pass": "您的密码"
  },
  "rule_settings": {
    "source_url": "https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt",
    "group_name": "国内IP",  // 爱快中显示的规则名称
    "max_per_group": 4000     // 单组最大条数 (安全阈值)
  },
  "telegram": {
    "enabled": true,
    "bot_token": "xxx",
    "chat_id": "xxx"
  }
}

```

## 🤝 致谢 (Acknowledgements)

本项目站在巨人的肩膀上，特别感谢以下先驱的贡献与启发：

* **[Jackie Wu](https://www.jackiewu.top/article/best-alternative-solution-for-transparent-gateway)**: 提供了透明网关架构的坚实理论基础。
* **[17mon/china_ip_list](https://github.com/17mon/china_ip_list)**: 提供了精准、长期维护的国内 IP 地址库。
* **[joyanhui/ikuai-bypass](https://github.com/joyanhui/ikuai-bypass)**: 在爱快 API 自动化领域的探索与参考。
* **[Li Dao (离岛)](https://www.youtube.com/@lidao)**: 优质的软路由教程与架构灵感来源。

## 📜 许可证

MIT License.
Designed by **Vaelen**.
