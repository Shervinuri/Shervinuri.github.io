#!/data/data/com.termux/files/usr/bin/bash

#================================================================
# V2ray CollecSHΞN™ - Final Version
#
# This version respects the original vision: Banner first.
# The UI is in English for a clean, technical feel.
# The script is robust and handles errors without crashing.
#================================================================

# --- Color Definitions ---
C_GREEN='\033[1;32m'
C_WHITE='\033[1;37m'
C_RED='\033[1;31m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[1;36m'
C_NC='\033[0m' # No Color

# --- Main Configuration ---
WORKDIR="$HOME/collector_shen"
ALL_CONFIGS_RAW="$WORKDIR/all_configs_raw.txt"
ALL_CONFIGS_DECODED="$WORKDIR/all_configs_decoded.txt"
FILTERED_CONFIGS="$WORKDIR/filtered_configs.txt"
FINAL_OUTPUT="$WORKDIR/valid_configs_shen.txt"
BIN_PATH="$HOME/.local/bin"
SINGBOX_PATH="$BIN_PATH/sing-box"

# List of subscription links
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
# UI & Core Functions
#================================================================

print_center() {
    local term_width=$(tput cols)
    local padding=$(((term_width - ${#1}) / 2))
    printf "%*s%s\n" "$padding" '' "$1"
}

# --- Initial Banner ---
# This is the VERY FIRST thing the user sees.
show_initial_banner() {
    clear
    echo -e "${C_WHITE}"
    print_center "=============================="
    print_center " V2ray CollecSHΞN™"
    print_center "=============================="
    echo -e "${C_NC}"
    echo ""
    echo ""
    print_center "${C_YELLOW}Press [Enter] to start the process...${C_NC}"
}

# --- Setup Functions (Run AFTER user presses Enter) ---
install_dependencies() {
    echo -e "\n${C_CYAN}Checking for required packages (curl, jq, etc)...${C_NC}"
    local pkgs_needed=()
    for pkg in curl jq base64 grep sed awk; do
        if ! command -v "$pkg" &>/dev/null; then
            pkgs_needed+=("$pkg")
        fi
    done
    if [ ${#pkgs_needed[@]} -gt 0 ]; then
        echo -e "${C_YELLOW}Installing: ${pkgs_needed[*]}${C_NC}"
        pkg install -y "${pkgs_needed[@]}" > /dev/null 2>&1
        echo -e "${C_GREEN}Dependencies installed.${C_NC}"
    else
        echo -e "${C_GREEN}All dependencies are already installed.${C_NC}"
    fi
}

install_singbox() {
    mkdir -p "$BIN_PATH"
    if [[ -f "$SINGBOX_PATH" ]]; then
        return # Silently exit if it exists
    fi
    echo -e "\n${C_CYAN}Sing-box not found. Installing...${C_NC}"
    local arch; case $(uname -m) in "aarch64") arch="arm64" ;; "armv7l" | "armv8l") arch="armv7" ;; "x86_64") arch="amd64" ;; *) echo -e "${C_RED}Unsupported architecture: $(uname -m)${C_NC}"; exit 1 ;; esac
    local arch_name="linux-${arch}"; local latest_version=$(curl -sL "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | jq -r .tag_name)
    if [[ -z "$latest_version" ]]; then echo -e "${C_RED}Failed to fetch sing-box version.${C_NC}"; exit 1; fi
    local file_name="sing-box-${latest_version#v}-${arch_name}.tar.gz"; local url="https://github.com/SagerNet/sing-box/releases/download/${latest_version}/${file_name}"
    if curl -sL -o "/tmp/sb.tar.gz" "$url" && tar -xzf "/tmp/sb.tar.gz" -C "/tmp/" > /dev/null 2>&1 && mv "/tmp/sing-box-${latest_version#v}-${arch_name}/sing-box" "$SINGBOX_PATH" && chmod +x "$SINGBOX_PATH"; then
        rm -rf "/tmp/sb.tar.gz" "/tmp/sing-box-"*
        echo -e "${C_GREEN}Sing-box installed successfully.${C_NC}"
    else
        echo -e "${C_RED}Failed to install sing-box.${C_NC}"; exit 1
    fi
}

# --- TUI (Terminal UI) Functions ---
print_at() { tput cup "$1" "$2"; echo -ne "$3"; }
draw_box() {
    local r=$1 c=$2 w=$3 h=$4
    print_at $r $c "${C_CYAN}╭$(printf '─%.0s' $(seq 1 $((w-2))))╮${C_NC}"
    for i in $(seq 1 $((h-2))); do print_at $((r+i)) $c "${C_CYAN}│${C_NC}"; print_at $((r+i)) $((c+w-1)) "${C_CYAN}│${C_NC}"; done
    print_at $((r+h-1)) $c "${C_CYAN}╰$(printf '─%.0s' $(seq 1 $((w-2))))╯${C_NC}"
}

setup_test_ui() {
    clear; tput civis
    local width=$(tput cols); ((width--))
    show_banner_and_ui() {
        clear; tput civis
        echo -e "${C_WHITE}"; print_center "=============================="; print_center " V2ray CollecSHΞN™"; print_center "=============================="; echo -e "${C_NC}"
        draw_box 5 1 "$width" 3; print_at 5 3 "${C_WHITE}📊 Live Stats${C_NC}"
        draw_box 8 1 "$width" 12; print_at 8 3 "${C_WHITE}📡 Live Results (Valid Configs)${C_NC}"
        print_at 19 1 "${C_CYAN}├$(printf '─%.0s' $(seq 1 $((width-2))))┤${C_NC}"
        print_at 20 3 "${C_YELLOW}Controls: ${C_WHITE}[p] Pause/Resume ${C_CYAN}| ${C_WHITE}[q] Quit & Save${C_NC}"
    }
    show_banner_and_ui
}

update_status_ui() {
    local checked=$1 valid=$2 failed=$3 total=$4
    local status_text="${C_CYAN}Checked: ${C_WHITE}$checked ${C_NC}| ${C_GREEN}Valid: ${C_WHITE}$valid ${C_NC}| ${C_RED}Failed: ${C_WHITE}$failed ${C_NC}| ${C_YELLOW}Total: ${C_WHITE}$total${C_NC}"
    print_at 6 3 "$status_text\033[K"
}

#================================================================
# SCRIPT EXECUTION STARTS HERE
#================================================================

# 1. Show banner and wait for user
show_initial_banner
read -r

# 2. Start the actual work AFTER user confirmation
clear
install_dependencies
install_singbox
mkdir -p "$WORKDIR"; : > "$FINAL_OUTPUT"

echo -e "\n${C_CYAN}1. Fetching configs from ${#SUBS[@]} sources...${C_NC}"
: > "$ALL_CONFIGS_RAW"
for LINK in "${SUBS[@]}"; do
    curl -sL --max-time 15 "$LINK" >> "$ALL_CONFIGS_RAW"
    echo "" >> "$ALL_CONFIGS_RAW"
done
echo -e "${C_GREEN}Done.${C_NC}"

echo -e "\n${C_CYAN}2. Decoding and filtering configs...${C_NC}"
awk '{if ($0 ~ /^[A-Za-z0-9+/=]{20,}/) {print $0 | "base64 -d 2>/dev/null"} else {print $0}}' "$ALL_CONFIGS_RAW" > "$ALL_CONFIGS_DECODED"
grep -E '^(vless|vmess|ss)://' "$ALL_CONFIGS_DECODED" | sed -e 's/#.*//' -e 's/\r$//' | sort -u > "$FILTERED_CONFIGS"
TOTAL_FOUND=$(wc -l < "$FILTERED_CONFIGS")
echo -e "${C_GREEN}   -> Found ${TOTAL_FOUND} unique configs.${C_NC}"

echo -e "\n${C_CYAN}3. Select protocol to test:${C_NC}"
echo -e "   ${C_WHITE}1) vless  2) vmess  3) shadowsocks (ss)  4) All protocols${C_NC}"
read -p "   Enter your choice [1-4]: " CHOICE
case $CHOICE in 1) P='^vless://';; 2) P='^vmess://';; 3) P='^ss://';; 4) P='^(vless|vmess|ss)://';; *) echo -e "${C_RED}Invalid choice.${C_NC}"; exit 1;; esac
TEMP_SELECTED_CONFIGS="$WORKDIR/selected_for_test.txt"
grep -E "$P" "$FILTERED_CONFIGS" > "$TEMP_SELECTED_CONFIGS"

# 4. Initialize and run the main testing UI
TOTAL_TO_TEST=$(wc -l < "$TEMP_SELECTED_CONFIGS")
VALID_COUNT=0; CHECKED_COUNT=0; FAILED_COUNT=0; STATE="run"
declare -a RESULTS_WINDOW
RESULTS_MAX_LINES=10

handle_input() { while true; do read -rsn1 i; if [[ "$i" == "p" ]]; then [[ "$STATE" == "run" ]] && STATE="pause" || STATE="run"; elif [[ "$i" == "q" ]]; then STATE="quit"; fi; done; }
handle_input &
INPUT_PID=$!
trap 'tput cnorm; kill $INPUT_PID &>/dev/null; clear; exit' EXIT

setup_test_ui

while IFS= read -r CONFIG || [[ -n "$CONFIG" ]]; do
    while [[ "$STATE" == "pause" ]]; do print_at 20 60 "${C_YELLOW}■ PAUSED...${C_NC}"; sleep 0.5; done
    [[ "$STATE" == "quit" ]] && break
    print_at 20 60 "${C_CYAN}▶ TESTING...${C_NC}\033[K"
    
    ((CHECKED_COUNT++))
    PERCENT=$((CHECKED_COUNT * 100 / TOTAL_TO_TEST))
    update_status_ui "$CHECKED_COUNT" "$VALID_COUNT" "$FAILED_COUNT" "$TOTAL_TO_TEST"
    
    # Progress Bar
    width=$(tput cols); bar_width=$((width - 10)); filled_len=$((PERCENT * bar_width / 100))
    bar="${C_GREEN}"; for ((i=0; i<filled_len; i++)); do bar+="▓"; done
    bar+="${C_NC}${C_WHITE}"; for ((i=filled_len; i<bar_width; i++)); do bar+="░"; done
    print_at 19 5 "${PERCENT}% ${bar}"

    TMP_JSON="$WORKDIR/test_$(date +%s%N).json"
    if ! "$SINGBOX_PATH" parse -j "$CONFIG" > "$WORKDIR/proxy.json" 2>/dev/null || [[ ! -s "$WORKDIR/proxy.json" ]]; then
        ((FAILED_COUNT++)); rm -f "$WORKDIR/proxy.json"; continue
    fi
    jq --argfile proxy "$WORKDIR/proxy.json" '{log:{level:"error"},outbounds:[$proxy,{tag:"urltest",type:"urltest",outbounds:["proxy"],url:"http://cp.cloudflare.com/"}]}' > "$TMP_JSON"
    rm -f "$WORKDIR/proxy.json"
    
    DELAY_MS=$(timeout 8s "$SINGBOX_PATH" urltest -c "$TMP_JSON" 2>/dev/null | awk '/ms/ {print $2}' | tr -d 'ms')
    rm -f "$TMP_JSON"

    if [[ "$DELAY_MS" =~ ^[0-9]+$ && "$DELAY_MS" -le 2000 ]]; then
        ((VALID_COUNT++))
        HOST=$(echo "$CONFIG" | sed -E 's|.*@([^:/?#]+).*|\1|' | head -n1)
        REMARK="☬SHΞN™-${DELAY_MS}ms"
        REMARK_ENCODED=$(printf %s "$REMARK" | jq -sRr @uri)
        echo "${CONFIG}#${REMARK_ENCODED}" >> "$FINAL_OUTPUT"
        
        RESULT_LINE="${C_GREEN}✓ ${C_WHITE}${HOST:0:25} ${C_CYAN}- ${C_YELLOW}${DELAY_MS}ms${C_NC}"
        ((${#RESULTS_WINDOW[@]} >= RESULTS_MAX_LINES)) && RESULTS_WINDOW=("${RESULTS_WINDOW[@]:1}")
        RESULTS_WINDOW+=("$RESULT_LINE")
        for i in "${!RESULTS_WINDOW[@]}"; do print_at $((9 + i)) 3 "${RESULTS_WINDOW[$i]}\033[K"; done
    else
        ((FAILED_COUNT++))
    fi
done < "$TEMP_SELECTED_CONFIGS"

# 5. Final Summary
tput cnorm; kill $INPUT_PID &>/dev/null
clear
echo -e "\n\n${C_GREEN}===========================================${C_NC}"
echo -e "${C_CYAN}            ✔ TESTING COMPLETE ✔             ${C_NC}"
echo -e "${C_GREEN}===========================================${C_NC}\n"
echo -e "  ${C_CYAN}Total configs checked: ${C_WHITE}$CHECKED_COUNT${C_NC}"
echo -e "  ${C_GREEN}Valid configs found:   ${C_WHITE}$VALID_COUNT${C_NC}"
echo -e "  ${C_RED}Failed/Invalid configs: ${C_WHITE}$FAILED_COUNT${C_NC}\n"
echo -e "  ${C_WHITE}✔ Valid configs saved to:${C_NC}"
echo -e "  ${C_YELLOW}$FINAL_OUTPUT${C_NC}\n"

# Cleanup
rm -f "$ALL_CONFIGS_RAW" "$ALL_CONFIGS_DECODED" "$FILTERED_CONFIGS" "$TEMP_SELECTED_CONFIGS"
