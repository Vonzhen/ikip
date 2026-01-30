#!/bin/sh

# 凛冬色彩定义
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'

# 标准化路径定义 (FHS Standard)
APP_DIR="/usr/share/ikip"
CONF_DIR="/etc/ikip"
BIN_FILE="/usr/bin/ikip"
LOG_FILE="/var/log/ikip.log"

# 创建阵地
mkdir -p $APP_DIR/src/strategies
mkdir -p $CONF_DIR

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    ⚔️  ikip v2.0: 凛冬哨兵标准化军团           ${NC}"
echo -e "${BLUE}    “守望开始，至死方休。” - Vaelen 领主专用   ${NC}"
echo -e "${BLUE}===============================================${NC}"

# 1. 领地授勋与密匙交换
printf "${YELLOW}1. 授予此哨位的领地名 (默认: 家): ${NC}"; read LOC_NAME; LOC_NAME=${LOC_NAME:-"家"}
printf "${YELLOW}2. 爱快城堡的密道地址 [http://10.10.10.1]: ${NC}"; read IK_URL; IK_URL=${IK_URL:-"http://10.10.10.1"}
printf "${YELLOW}3. 守城官署名 [admin]: ${NC}"; read IK_USER; IK_USER=${IK_USER:-"admin"}
printf "${YELLOW}4. 开启堡垒的秘密令牌 (必填): ${NC}"; read IK_PASS
while [ -z "$IK_PASS" ]; do printf "${RED}   令牌不可缺失，请重新输入: ${NC}"; read IK_PASS; done

# 2. 战术参数配置 (高级)
echo -e "\n${YELLOW}=== ⚙️  战术参数配置 ===${NC}"
DEFAULT_URL="https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt"
printf "${YELLOW}5. IP 列表源地址 [回车默认]: ${NC}"; read INPUT_URL
SOURCE_URL=${INPUT_URL:-$DEFAULT_URL}

DEFAULT_LIMIT=4000
while true; do
    printf "${YELLOW}6. 单组 IP 最大阈值 (默认 4000, Max 5000): ${NC}"; read INPUT_LIMIT
    LIMIT=${INPUT_LIMIT:-$DEFAULT_LIMIT}
    if [ "$LIMIT" -le 5000 ] 2>/dev/null && [ "$LIMIT" -ge 100 ] 2>/dev/null; then break; fi
    echo -e "${RED}   ❌ 无效阈值，请重新输入！${NC}"
done

# 3. 渡鸦设置
printf "\n${YELLOW}7. 渡鸦通讯设置 (若无请回车):${NC}\n"
printf "   Token: "; read TG_TOKEN
printf "   ChatID: "; read TG_ID
ENABLE_TG="false"
[ -n "$TG_TOKEN" ] && [ -n "$TG_ID" ] && ENABLE_TG="true"

# 4. 生成法典 (Config)
cat <<EOF > $CONF_DIR/config.json
{
  "location_name": "$LOC_NAME",
  "ikuai": { "url": "$IK_URL", "user": "$IK_USER", "pass": "$IK_PASS" },
  "rule_settings": { "source_url": "$SOURCE_URL", "group_name": "国内IP", "max_per_group": $LIMIT },
  "telegram": { "enabled": $ENABLE_TG, "bot_token": "$TG_TOKEN", "chat_id": "$TG_ID" }
}
EOF

# 5. 部署代码 (从 GitHub 拉取到 /usr/share/ikip)
echo -e "\n${BLUE}正在从学城征召军团 (Python Scripts)...${NC}"
if [ -x "$(command -v opkg)" ]; then opkg update && opkg install python3 python3-requests jq; fi

REPO_USER=$(echo "$0" | grep -o "githubusercontent.com/[^/]*" | cut -d'/' -f2); REPO_USER=${REPO_USER:-"Vonzhen"}
BASE_URL="https://raw.githubusercontent.com/$REPO_USER/ikip/master"

# 下载核心文件
wget -q -O $APP_DIR/src/main.py "$BASE_URL/src/main.py"
wget -q -O $APP_DIR/src/utils.py "$BASE_URL/src/utils.py"
wget -q -O $APP_DIR/src/strategies/ikuai.py "$BASE_URL/src/strategies/ikuai.py"
touch $APP_DIR/src/strategies/__init__.py

chmod -R +x $APP_DIR

# 6. 刻录巡逻契约 (Crontab: 每月1号凌晨4点)
CRON="0 4 1 * *"
PY_PATH=$(command -v python3)
(crontab -l 2>/dev/null | grep -v "ikip"; echo "$CRON $PY_PATH $APP_DIR/src/main.py >> $LOG_FILE 2>&1") | crontab -

# 7. 唤醒指挥官 (CLI)
cat << 'EOF_CLI' > $BIN_FILE
#!/bin/sh
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
CONF="/etc/ikip/config.json"
APP_MAIN="/usr/share/ikip/src/main.py"

show_cfg() {
    echo -e "\n${BLUE}--- 📋 军册检阅 ---${NC}"
    jq -r '"领地: \(.location_name)\n堡垒: \(.ikuai.url)\n源站: \(.rule_settings.source_url)\n阈值: \(.rule_settings.max_per_group)"' $CONF
}

while true; do
    RAVEN=$([ "$(jq -r '.telegram.enabled' $CONF)" = "true" ] && echo "${GREEN}开启${NC}" || echo "${RED}关闭${NC}")
    echo -e "\n${GREEN}=== ikip v2.0: 积木指挥官 (Vaelen) ===${NC}"
    echo -e " 1) 🦅 巡航长城 (立即更新)"
    echo -e " 2) 📋 检阅军册 (查看配置)"
    echo -e " 3) ⚙️  战术调整 (修改参数)"
    echo -e " 4) 📨 渡鸦传信 ($RAVEN)"
    echo -e " 5) 🔄 哨兵进化 (更新脚本)"
    echo -e " 0) ❌ 焚毁契约 (卸载)"
    echo -e " q) 告退"
    printf "指令: "; read c
    case $c in
        1) python3 $APP_MAIN ;;
        2) show_cfg ;;
        3) vi $CONF ;; 
        4) 
           st=$(jq -r '.telegram.enabled' $CONF); 
           if [ "$st" = "true" ]; then n=false; else n=true; fi
           jq ".telegram.enabled = $n" $CONF > ${CONF}.tmp && mv ${CONF}.tmp $CONF
           echo "状态已切换。" ;;
        5) curl -sL https://raw.githubusercontent.com/Vonzhen/ikip/master/install.sh | sh ;;
        0) crontab -l | grep -v "ikip" | crontab -; rm -rf /etc/ikip /usr/share/ikip $BIN_FILE; echo "已卸载"; exit ;;
        q) exit ;;
    esac
done
EOF_CLI
chmod +x $BIN_FILE

echo -e "${GREEN}🎉 部署完成！输入 ${YELLOW}ikip${NC} 唤醒指挥官。${NC}"
