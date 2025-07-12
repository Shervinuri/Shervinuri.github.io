#!/data/data/com.termux/files/usr/bin/bash

#================================================================
# V2ray CollecSHΞN™ - نسخه نهایی با بنر اصلی و ضد خطا
#
# این اسکریپت ظاهر اصلی شما را با یک رابط کاربری پایدار
# و مقاوم در برابر خطا ترکیب می‌کند.
#================================================================

# --- تعریف رنگ‌ها ---
C_GREEN='\033[1;32m'
C_WHITE='\033[1;37m'
C_RED='\033[1;31m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'
C_MAGENTA='\033[1;35m'
C_BLUE='\033[1;34m'
C_NC='\033[0m' # بدون رنگ

# --- تنظیمات اصلی ---
WORKDIR="$HOME/collector_shen"
ALL_CONFIGS_RAW="$WORKDIR/all_configs_raw.txt"
ALL_CONFIGS_DECODED="$WORKDIR/all_configs_decoded.txt"
FILTERED_CONFIGS="$WORKDIR/filtered_configs.txt"
FINAL_OUTPUT="$WORKDIR/valid_configs_shen.txt"
BIN_PATH="$HOME/.local/bin"
SINGBOX_PATH="$BIN_PATH/sing-box"

# لیست لینک‌های اشتراک
SUBS=(
    "https://raw.githubusercontent.com/MatinGhanbari/v2ray-configs/main/subscriptions/v2ray/subs/sub1.txt"
    "https://raw.githubusercontent.com/liketolivefree/kobabi/main/sub.txt"
    "https://raw.githubusercontent.com/mahsanet/MahsaFreeConfig/main/mci/sub_3.txt"
    "https://raw.githubusercontent.com/Mohammadgb0078/IRV2ray/main/vless.txt"
    "https://raw.githubusercontent.com/NiREvil/vless/main/sub/nekobox-wg.txt"
    "https://v2.alicivil.workers.dev/?list=fi&count=200&shuffle=true&unique=false"
    "https://v2.alicivil.workers.dev/?list=us&count=200&shuffle=true&unique=false"
    "https://v2.alicivil.workers.dev/?list=gb&count=200&shuffle=true&unique=false"
    "https://raw.githubusercontent.com/barry-far/V2ray-config/main/Splitted-By-Protocol/vless.txt"
)

#================================================================
# توابع رابط کاربری (UI Functions)
#================================================================
declare -a RESULTS_WINDOW
RESULTS_MAX_LINES=10

print_at() { tput cup "$1" "$2"; echo -ne "$3"; }
print_center() {
    local term_width=$(tput cols)
    local padding=$(((term_width - ${#1}) / 2))
    printf "%*s%s\n" "$padding" '' "$1"
}

# بنر اصلی به سبک شما
show_banner_and_ui() {
    clear
    tput civis
    echo -e "${C_WHITE}"
    print_center "=============================="
    print_center " V2ray CollecSHΞN™"
    print_center "=============================="
    echo -e "${C_NC}"
    
    local width=$(tput cols); ((width--))
    
    # کادر آمار
    draw_box 5 1 "$width" 3
    print_at 5 3 "${C_WHITE}📊 آمار${C_NC}"
    
    # کادر نتایج
    draw_box 8 1 "$width" $((RESULTS_MAX_LINES + 2))
    print_at 8 3 "${C_WHITE}📡 نتایج زنده (کانفیگ‌های سالم)${C_NC}"
    
    # خط جداکننده
    print_at $((9 + RESULTS_MAX_LINES)) 1 "${C_CYAN}├$(printf '─%.0s' $(seq 1 $((width-2))))┤${C_NC}"
    
    # راهنمای کلیدها
    print_at $((10 + RESULTS_MAX_LINES)) 3 "${C_YELLOW}کنترل: ${C_WHITE}[p] توقف/ادامه ${C_CYAN}| ${C_WHITE}[q] خروج و ذخیره${C_NC}"
}

draw_box() {
    local r=$1 c=$2 w=$3 h=$4
    print_at $r $c "${C_CYAN}╭$(printf '─%.0s' $(seq 1 $((w-2))))╮${C_NC}"
    for i in $(seq 1 $((h-2))); do
        print_at $((r+i)) $c "${C_CYAN}│${C_NC}"
        print_at $((r+i)) $((c+w-1)) "${C_CYAN}│${C_NC}"
    done
    print_at $((r+h-1)) $c "${C_CYAN}╰$(printf '─%.0s' $(seq 1 $((w-2))))╯${C_NC}"
}

update_status() {
    local checked=$1 valid=$2 failed=$3 total=$4
    local status_text="${C_BLUE}تست شده: ${C_WHITE}$checked${C_NC} ${C_CYAN}| ${C_GREEN}سالم: ${C_WHITE}$valid${C_NC} ${C_CYAN}| ${C_RED}خطا: ${C_WHITE}$failed${C_NC} ${C_CYAN}| ${C_YELLOW}کل: ${C_WHITE}$total${C_NC}"
    print_at 6 3 "$status_text\033[K"
}

add_result_line() {
    ((${#RESULTS_WINDOW[@]} >= RESULTS_MAX_LINES)) && RESULTS_WINDOW=("${RESULTS_WINDOW[@]:1}")
    RESULTS_WINDOW+=("$1")
    for i in "${!RESULTS_WINDOW[@]}"; do
        print_at $((9 + i)) 3 "${RESULTS_WINDOW[$i]}\033[K"
    done
}

update_progress() {
    local percent=$1
    local width=$(tput cols)
    local bar_width=$((width - 10))
    local filled_len=$((percent * bar_width / 100))
    local bar="${C_GREEN}"
    for ((i=0; i<filled_len; i++)); do bar+="▓"; done
    bar+="${C_NC}${C_WHITE}"
    for ((i=filled_len; i<bar_width; i++)); do bar+="░"; done
    print_at $((9 + RESULTS_MAX_LINES)) 5 "${percent}% ${bar}"
}

#================================================================
# توابع اصلی اسکریپت
#================================================================
# (توابع install_dependencies, install_singbox, create_test_config از اسکریپت قبلی بدون تغییر اینجا کپی می‌شوند)
install_dependencies() { for pkg in curl jq base64 grep sed awk; do if ! command -v "$pkg" &>/dev/null; then echo -e "${C_YELLOW}نصب $pkg...${C_NC}"; pkg install -y "$pkg"; fi; done; }
install_singbox() {
    mkdir -p "$BIN_PATH"; if [[ -f "$SINGBOX_PATH" ]]; then echo -e "${C_GREEN}sing-box از قبل نصب است.${C_NC}"; return; fi
    echo -e "${C_YELLOW}در حال نصب sing-box...${C_NC}"; local arch; case $(uname -m) in "aarch64") arch="arm64" ;; "armv7l" | "armv8l") arch="armv7" ;; "x86_64") arch="amd64" ;; *) echo -e "${C_RED}معماری پشتیبانی نمی‌شود: $(uname -m)${C_NC}"; exit 1 ;; esac
    local arch_name="linux-${arch}"; local latest_version=$(curl -sL "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | jq -r .tag_name); if [[ -z "$latest_version" ]]; then echo -e "${C_RED}دریافت نسخه sing-box ناموفق بود.${C_NC}"; exit 1; fi
    local file_name="sing-box-${latest_version#v}-${arch_name}.tar.gz"; local url="https://github.com/SagerNet/sing-box/releases/download/${latest_version}/${file_name}"
    curl -sL -o "/tmp/sb.tar.gz" "$url" && tar -xzf "/tmp/sb.tar.gz" -C "/tmp/" && mv "/tmp/sing-box-${latest_version#v}-${arch_name}/sing-box" "$SINGBOX_PATH" && chmod +x "$SINGBOX_PATH" && rm -rf "/tmp/sb.tar.gz" "/tmp/sing-box-"* && echo -e "${C_GREEN}sing-box با موفقیت نصب شد.${C_NC}" || { echo -e "${C_RED}نصب sing-box ناموفق بود.${C_NC}"; exit 1; }
}
create_test_config() {
    local config_uri="$1"; local temp_json_path="$2"
    # از sing-box برای تبدیل URI به JSON استفاده می‌کنیم. اگر URI نامعتبر باشد، این دستور شکست می‌خورد.
    if ! "$SINGBOX_PATH" parse -j "$config_uri" > "$WORKDIR/proxy.json"; then return 1; fi
    # اگر فایل JSON خروجی خالی باشد، یعنی کانفیگ مشکل داشته است.
    if [[ ! -s "$WORKDIR/proxy.json" ]]; then rm "$WORKDIR/proxy.json"; return 1; fi
    # ساخت فایل کانفیگ نهایی برای تست
    jq --argfile proxy "$WORKDIR/proxy.json" \
       '{log: {level: "error"}, outbounds: [$proxy, {tag: "urltest", type: "urltest", outbounds: ["proxy"], url: "http://cp.cloudflare.com/"}]}' \
       > "$temp_json_path"
    rm "$WORKDIR/proxy.json"
    return 0
}

# --- نقطه شروع اصلی اسکریپت ---

clear
echo -e "${C_CYAN}به V2ray CollecSHΞN™ خوش آمدید!${C_NC}"
install_dependencies; install_singbox; mkdir -p "$WORKDIR"; : > "$FINAL_OUTPUT"
echo -e "${C_YELLOW}برای شروع جمع‌آوری و تست، Enter را بزنید...${C_NC}"; read -r

clear; echo -e "\n${C_CYAN}1. در حال جمع‌آوری کانفیگ‌ها...${C_NC}"
: > "$ALL_CONFIGS_RAW"
for LINK in "${SUBS[@]}"; do echo -e "   -> ${C_YELLOW}$LINK${C_NC}"; curl -sL --max-time 15 "$LINK" >> "$ALL_CONFIGS_RAW"; echo "" >> "$ALL_CONFIGS_RAW"; done

echo -e "${C_CYAN}2. در حال پردازش و فیلتر کردن...${C_NC}"
awk '{if ($0 ~ /^[A-Za-z0-9+/=]{20,}/) {print $0 | "base64 -d 2>/dev/null"} else {print $0}}' "$ALL_CONFIGS_RAW" > "$ALL_CONFIGS_DECODED"
grep -E '^(vless|vmess|ss)://' "$ALL_CONFIGS_DECODED" | sed -e 's/#.*//' -e 's/\r$//' | sort -u > "$FILTERED_CONFIGS"
TOTAL_FOUND=$(wc -l < "$FILTERED_CONFIGS")
echo -e "${C_GREEN}   -> ${TOTAL_FOUND} کانفیگ منحصر به فرد پیدا شد.${C_NC}"

echo -e "\n${C_CYAN}3. پروتکل مورد نظر برای تست را انتخاب کنید:${C_NC}"
echo -e "   ${C_WHITE}1) vless  2) vmess  3) shadowsocks (ss)  4) همه پروتکل‌ها${C_NC}"
read -p "   انتخاب شما [1-4]: " CHOICE
case $CHOICE in 1) P='^vless://';; 2) P='^vmess://';; 3) P='^ss://';; 4) P='^(vless|vmess|ss)://';; *) echo -e "${C_RED}نامعتبر.${C_NC}"; exit 1;; esac
TEMP_SELECTED_CONFIGS="$WORKDIR/selected_for_test.txt"
grep -E "$P" "$FILTERED_CONFIGS" > "$TEMP_SELECTED_CONFIGS"

# 4. شروع فرآیند تست با رابط گرافیکی
TOTAL_TO_TEST=$(wc -l < "$TEMP_SELECTED_CONFIGS")
VALID_COUNT=0; CHECKED_COUNT=0; FAILED_COUNT=0; STATE="run"
handle_input() { while true; do read -rsn1 i; if [[ "$i" == "p" ]]; then [[ "$STATE" == "run" ]] && STATE="pause" || STATE="run"; elif [[ "$i" == "q" ]]; then STATE="quit"; fi; done; }
handle_input &
INPUT_PID=$!
trap 'tput cnorm; kill $INPUT_PID &>/dev/null; clear; exit' EXIT
show_banner_and_ui

while IFS= read -r CONFIG || [[ -n "$CONFIG" ]]; do
    while [[ "$STATE" == "pause" ]]; do print_at $((10 + RESULTS_MAX_LINES)) 50 "${C_YELLOW}■ متوقف شده...${C_NC}"; sleep 0.5; done
    [[ "$STATE" == "quit" ]] && break
    print_at $((10 + RESULTS_MAX_LINES)) 50 "${C_CYAN}▶ در حال تست...${C_NC}\033[K"
    
    ((CHECKED_COUNT++))
    PERCENT=$((CHECKED_COUNT * 100 / TOTAL_TO_TEST))
    update_status "$CHECKED_COUNT" "$VALID_COUNT" "$FAILED_COUNT" "$TOTAL_TO_TEST"
    update_progress "$PERCENT"

    TMP_JSON="$WORKDIR/test_$(date +%s%N).json"
    # اگر ساخت کانفیگ تست ناموفق بود (کانفیگ ورودی خراب است)، آن را به عنوان خطا ثبت کن و ادامه بده
    if ! create_test_config "$CONFIG" "$TMP_JSON"; then
        ((FAILED_COUNT++))
        rm -f "$TMP_JSON"
        continue
    fi
    
    DELAY_MS=$(timeout 8s "$SINGBOX_PATH" urltest -c "$TMP_JSON" 2>/dev/null | awk '/ms/ {print $2}' | tr -d 'ms')
    rm -f "$TMP_JSON"

    if [[ "$DELAY_MS" =~ ^[0-9]+$ && "$DELAY_MS" -le 2000 ]]; then
        ((VALID_COUNT++))
        HOST=$(echo "$CONFIG" | sed -E 's|.*@([^:/?#]+).*|\1|' | head -n1)
        REMARK="☬SHΞN™-${DELAY_MS}ms"
        REMARK_ENCODED=$(printf %s "$REMARK" | jq -sRr @uri)
        echo "${CONFIG}#${REMARK_ENCODED}" >> "$FINAL_OUTPUT"
        RESULT_LINE="${C_GREEN}✓ ${C_WHITE}${HOST:0:25} ${C_CYAN}- ${C_YELLOW}${DELAY_MS}ms${C_NC}"
        add_result_line "$RESULT_LINE"
    else
        # اگر پینگ تایم اوت شد یا نامعتبر بود، آن را هم خطا در نظر بگیر
        ((FAILED_COUNT++))
    fi
done < "$TEMP_SELECTED_CONFIGS"

# 5. پایان و نمایش خلاصه
tput cnorm; kill $INPUT_PID &>/dev/null
clear
show_banner_and_ui
update_status "$CHECKED_COUNT" "$VALID_COUNT" "$FAILED_COUNT" "$TOTAL_TO_TEST"
print_at $((10 + RESULTS_MAX_LINES)) 3 "${C_GREEN}✔ فرآیند تست کامل شد! نتایج در فایل زیر ذخیره شد:${C_NC}"
print_at $((11 + RESULTS_MAX_LINES)) 3 "${C_YELLOW}$FINAL_OUTPUT${C_NC}\n\n"

# پاکسازی فایل‌های موقت
rm -f "$ALL_CONFIGS_RAW" "$ALL_CONFIGS_DECODED" "$FILTERED_CONFIGS" "$TEMP_SELECTED_CONFIGS"
