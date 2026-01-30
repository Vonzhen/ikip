#!/bin/sh

# ===============================================
#   ⚔️  ikip v2.4: 凛冬哨兵 - 疆域分流加固工具
# ===============================================

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
APP_DIR="/usr/share/ikip"
CONF_DIR="/etc/ikip"
BIN_FILE="/usr/bin/ikip"
LOG_FILE="/var/log/ikip.log"

# --- 0. 军备物资检查 ---
check_env() {
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}    ⚔️  正在检阅军备物资...                     ${NC}"
    NEED_INSTALL="false"
    if ! command -v python3 >/dev/null 2>&1; then NEED_INSTALL="true"; fi
    if ! command -v jq >/dev/null 2>&1; then NEED_INSTALL="true"; fi
    if command -v python3 >/dev/null 2>&1; then
        if ! python3 -c "import requests" >/dev/null 2>&1; then NEED_INSTALL="true"; fi
    fi

    if [ "$NEED_INSTALL" = "true" ]; then
        echo -e "${YELLOW}⚠️  发现缺失装备，正在请求补给...${NC}"
        if [ -x "$(command -v opkg)" ]; then
            opkg update >/dev/null 2>&1
            opkg install python3 python3-requests jq wget-ssl >/dev/null 2>&1 || opkg install python3 python3-requests jq wget
        elif [ -x "$(command -v apk)" ]; then
            apk update >/dev/null 2>&1
            apk add python3 py3-requests jq wget >/dev/null 2>&1
        elif [ -x "$(command -v apt-get)" ]; then
            apt-get update >/dev/null 2>&1
            apt-get install -y python3 python3-requests jq wget >/dev/null 2>&1
        else
            echo -e "${RED}❌ 未检测到包管理器，请手动安装 python3, requests, jq${NC}"
            exit 1
        fi
        echo -e "${GREEN}✅ 军备补给完成。${NC}"
    else
        echo -e "${GREEN}✅ 军备物资充足。${NC}"
    fi
}
check_env

# --- 1. 部署前置 ---
mkdir -p $APP_DIR/src/strategies
mkdir -p $CONF_DIR

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    ⚔️  ikip v2.4: 凛冬哨兵标准化军团           ${NC}"
echo -e "${BLUE}    “守望开始，至死方休。” - Vaelen 领主专用   ${NC}"
echo -e "${BLUE}===============================================${NC}"

# --- 2. 交互配置 ---
# 注意：read 命令在管道模式下会失效，v2.4 已在 CLI 中修复了调用方式
printf "${YELLOW}1. 授予此哨位的领地名 [默认: 家]: ${NC}"; read LOC_NAME; LOC_NAME=${LOC_NAME:-"家"}
printf "${YELLOW}2. 爱快城堡的密道地址 [http://10.10.10.1]: ${NC}"; read IK_URL; IK_URL=${IK_URL:-"http://10.10.10.1"}
printf "${YELLOW}3. 守城官署名 [admin]: ${NC}"; read IK_USER; IK_USER=${IK_USER:-"admin"}
printf "${YELLOW}4. 开启堡垒的秘密令牌 [必填]: ${NC}"; read IK_PASS
while [ -z "$IK_PASS" ]; do printf "${RED}   令牌不可缺失，请重新输入: ${NC}"; read IK_PASS; done

# --- 3. 战术参数 ---
echo -e "\n${YELLOW}=== ⚙️  战术参数配置 ===${NC}"
DEFAULT_URL="https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt"
printf "${YELLOW}5. IP 列表源地址 [回车默认]: ${NC}"; read INPUT_URL
SOURCE_URL=${INPUT_URL:-$DEFAULT_URL}

DEFAULT_LIMIT=4000
while true; do
    printf "${YELLOW}6. 单组 IP 最大阈值 [默认 4000, Max 5000]: ${NC}"; read INPUT_LIMIT
    LIMIT=${INPUT_LIMIT:-$DEFAULT_LIMIT}
    if [ "$LIMIT" -le 5000 ] 2>/dev/null && [ "$LIMIT" -ge 100 ] 2>/dev/null; then break; fi
    echo -e "${RED}   ❌ 无效阈值，请重新输入！${NC}"
done

# --- 4. 渡鸦设置 ---
printf "\n${YELLOW}7. 渡鸦通讯设置 [若无请回车]:${NC}\n"
printf "   Token: "; read TG_TOKEN
printf "   ChatID: "; read TG_ID
ENABLE_TG="false"
[ -n "$TG_TOKEN" ] && [ -n "$TG_ID" ] && ENABLE_TG="true"

# --- 5. 生成配置 ---
cat <<EOF > $CONF_DIR/config.json
{
  "location_name": "$LOC_NAME",
  "ikuai": { "url": "$IK_URL", "user": "$IK_USER", "pass": "$IK_PASS" },
  "rule_settings": { "source_url": "$SOURCE_URL", "group_name": "国内IP", "max_per_group": $LIMIT },
  "telegram": { "enabled": $ENABLE_TG, "bot_token": "$TG_TOKEN", "chat_id": "$TG_ID" }
}
EOF

# --- 6. 部署代码 ---
echo -e "\n${BLUE}正在从学城征召军团...${NC}"
REPO_USER=$(echo "$0" | grep -o "githubusercontent.com/[^/]*" | cut -d'/' -f2); REPO_USER=${REPO_USER:-"Vonzhen"}
BASE_URL="https://raw.githubusercontent.com/$REPO_USER/ikip/master"

wget -q -O $APP_DIR/src/main.py "$BASE_URL/src/main.py"
wget -q -O $APP_DIR/src/utils.py "$BASE_URL/src/utils.py"
wget -q -O $APP_DIR/src/strategies/ikuai.py "$BASE_URL/src/strategies/ikuai.py"
touch $APP_DIR/src/strategies/__init__.py
chmod -R +x $APP_DIR

if [ ! -s "$APP_DIR/src/main.py" ]; then
    echo -e "${RED}❌ 致命错误：文件下载失败，请检查网络或仓库地址！${NC}"
    exit 1
fi

# --- 7. Crontab ---
CRON="0 4 1 * *"
PY_PATH=$(command -v python3)
(crontab -l 2>/dev/null | grep -v "ikip"; echo "$CRON $PY_PATH $APP_DIR/src/main.py >> $LOG_FILE 2>&1") | crontab -

# --- 8. 生成 CLI 面板 ---
# ★关键修正：使用 wget 下载到临时文件再执行，避开管道冲突
cat << 'EOF_CLI' > $BIN_FILE
#!/bin/sh
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
CONF="/etc/ikip/config.json"
APP_MAIN="/usr/share/ikip/src/main.py"

show_cfg() {
    echo -e "\n${BLUE}--- 📋 军册检阅 ---${NC}"
    if [ -f "$CONF" ]; then
        jq -r '"领地: \(.location_name)\n堡垒: \(.ikuai.url)\n源站: \(.rule_settings.source_url)\n阈值: \(.rule_settings.max_per_group)"' $CONF
    else
        echo -e "${RED}法典缺失，请重新安装！${NC}"
    fi
}

while true; do
    RAVEN=$([ -f "$CONF" ] && [ "$(jq -r '.telegram.enabled' $CONF)" = "true" ] && echo "${GREEN}开启${NC}" || echo "${RED}关闭${NC}")
    echo -e "\n${GREEN}=== ikip v2.4: 积木指挥官 (Vaelen) ===${NC}"
    echo -e " 1) 🦅 巡航长城 (强制执行更新)"
    echo -e " 2) 📋 检阅军册 (查看配置)"
    echo -e " 3) ⚙️  战术调整 (手动编辑配置)"
    echo -e " 4) 📨 渡鸦传信 ($RAVEN)"
    echo -e " 5) 🔄 哨兵进化 (更新脚本)"
    echo -e " 0) ❌ 焚毁契约 (卸载)"
    echo -e " q) 告退"
    printf "指令: "; read c
    case $c in
        1) 
           echo -e "${YELLOW}正在强制巡逻，无视哈希缓存...${NC}"
           python3 $APP_MAIN force 
           ;;
        2) show_cfg ;;
        3) 
           [ -x "$(command -v vim)" ] && vim $CONF || vi $CONF 
           ;; 
        4) 
           st=$(jq -r '.telegram.enabled' $CONF); 
           if [ "$st" = "true" ]; then n=false; else n=true; fi
           jq ".telegram.enabled = $n" $CONF > ${CONF}.tmp && mv ${CONF}.tmp $CONF
           echo "状态已切换。" ;;
        5) 
           echo "正在从学城获取最新卷轴..."
           # ★修复点：下载到 /tmp 并断开管道连接，确保 read 命令正常工作
           INSTALL_SCRIPT="/tmp/ikip_install.sh"
           wget -q -O $INSTALL_SCRIPT https://raw.githubusercontent.com/Vonzhen/ikip/master/install.sh
           if [ -s "$INSTALL_SCRIPT" ]; then
               chmod +x $INSTALL_SCRIPT
               sh $INSTALL_SCRIPT
               rm -f $INSTALL_SCRIPT
               # 更新后直接退出面板，让用户重新进入以加载新逻辑
               exit 0 
           else
               echo -e "${RED}更新失败：无法下载安装脚本。${NC}"
           fi
           ;;
        0) 
           printf "${RED}确定要卸载吗？[y/n]: ${NC}"; read confirm
           if [ "$confirm" = "y" ]; then
               crontab -l | grep -v "ikip" | crontab -
               rm -rf /etc/ikip /usr/share/ikip $BIN_FILE
               echo "已卸载"; exit
           fi
           ;;
        q) exit ;;
    esac
done
EOF_CLI
chmod +x $BIN_FILE

echo -e "${GREEN}🎉 部署完成！输入 ${YELLOW}ikip${NC} 唤醒指挥官。${NC}"
