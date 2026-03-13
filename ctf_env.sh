#!/bin/bash
set -Eeuo pipefail

# ==============================
# 颜色定义
# ==============================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ==============================
# 全局变量
# ==============================
LOG_FILE="/var/log/ctf_env.log"
TMP_BASE=$(mktemp -d /tmp/ctf_env_XXXX)

trap 'rm -rf "$TMP_BASE"' EXIT

# ==============================
# 检查 root 用户
# ==============================
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[!] 请使用 root 用户运行该脚本！${NC}"
    exit 1
fi

exec > >(tee -a "$LOG_FILE") 2>&1

# ==============================
# 欢迎信息
# ==============================
echo -e "${CYAN}
#########################################################
#                    CTF_ENV                            #
#           Kali Linux 快速安装与配置CTF工具            #
#                                                       #
#                                   Version: 1.1.3      #
#                                   Author: iami233     #
#########################################################
${NC}"

# ==============================
# SSH 自动启动
# ==============================
enableSSH() {
    echo -e "${CYAN}[+] 启动 SSH 服务...${NC}"
    systemctl start ssh
    systemctl enable ssh
    echo -e "${GREEN}[✓] SSH 已启动并设置开机自启${NC}"
    systemctl status ssh --no-pager
}

# ==============================
# Kali 密钥环配置
# ==============================
installKaliKeyring() {
    echo -e "${CYAN}[+] 检查 Kali archive keyring...${NC}"
    if [ ! -f /usr/share/keyrings/kali-archive-keyring.gpg ]; then
        echo -e "${CYAN}[+] 下载 Kali archive keyring...${NC}"
        retryCmd wget -q https://archive.kali.org/archive-keyring.gpg -O /usr/share/keyrings/kali-archive-keyring.gpg
    else
        echo -e "${GREEN}[✓] Kali keyring 已存在${NC}"
    fi
}

# ==============================
# 镜像源配置
# ==============================
MIRRORS=(
    "阿里云|http://mirrors.aliyun.com/kali"
    "清华大学|https://mirrors.tuna.tsinghua.edu.cn/kali"
    "中科大|https://mirrors.ustc.edu.cn/kali"
    "官方|http://http.kali.org/kali"
)
MIRROR_BASE="${MIRRORS[0]#*|}"

chooseMirror() {
    echo -e "${CYAN}[+] 请选择 APT 源镜像:${NC}"
    for i in "${!MIRRORS[@]}"; do
        echo "$((i+1)). ${MIRRORS[i]%%|*}"
    done
    read -rp "输入选项: " mirror_choice
    if [[ "$mirror_choice" =~ ^[1-4]$ ]]; then
        MIRROR_BASE="${MIRRORS[$((mirror_choice-1))]#*|}"
        echo -e "${GREEN}[✓] 已选择镜像: $MIRROR_BASE${NC}"
    else
        echo -e "${YELLOW}[!] 输入无效，使用默认镜像${NC}"
    fi
}

# ==============================
# 通用函数
# ==============================
retryCmd() {
    local attempts=3
    local cmd=("$@")
    for i in $(seq 1 $attempts); do
        if "${cmd[@]}"; then
            return 0
        else
            echo -e "${YELLOW}[!] 执行失败，重试第 $i 次...${NC}"
            sleep 2
        fi
    done
    echo -e "${RED}[!] 命令多次失败: ${cmd[*]}${NC}"
    return 1
}

cleanConflictingSources() {
    echo -e "${CYAN}[+] 检查并清理可能冲突的第三方源...${NC}"
    if ls /etc/apt/sources.list.d/docker*.list 1>/dev/null 2>&1; then
        rm -f /etc/apt/sources.list.d/docker*.list
        echo -e "${YELLOW}[!] 已删除旧的 Docker 源文件${NC}"
    fi
}

updateSources() {
    echo -e "${CYAN}[+] 更新 APT 源...${NC}"
    [ -f /etc/apt/sources.list ] && mv /etc/apt/sources.list "/etc/apt/sources.list.bak.$(date +%s)"
    cat <<EOF > /etc/apt/sources.list
deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg] ${MIRROR_BASE} kali-rolling main contrib non-free non-free-firmware
EOF
    retryCmd apt-get update -y
}

installPackages() {
    echo -e "${CYAN}[+] 安装依赖: $* ...${NC}"
    retryCmd apt-get install -y "$@"
}

# ==============================
# 基础工具安装
# ==============================
installBaseTools() {
    installPackages \
        git \
        build-essential \
        curl \
        wget \
        ca-certificates \
        libssl-dev \
        libffi-dev \
        libpcap-dev \
        libmcrypt4 \
        libmhash2
}

# ==============================
# Python 安装
# ==============================
installPython3() {
    installPackages \
        python3 \
        python3-pip \
        python3-venv
    python3 -m pip install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple
}

installPython2() {
    installPackages \
        python2 \
        python2-dev
    echo -e "${CYAN}[+] 正在为 Python2 安装 pip...${NC}"
    if retryCmd wget -O "$TMP_BASE/get-pip.py" https://bootstrap.pypa.io/pip/2.7/get-pip.py; then
        python2 "$TMP_BASE/get-pip.py"
        python2 -m pip install --upgrade pip
    else
        echo -e "${RED}[!] 下载 get-pip.py 失败${NC}"
        return 1
    fi
}

# ==============================
# Docker 安装
# ==============================
installDocker() {
    echo -e "${CYAN}[+] 安装 Docker...${NC}"
    cleanConflictingSources
    apt-get update -y
    installPackages \
        docker.io
    mkdir -p /etc/docker
    cat <<EOF > /etc/docker/daemon.json
{
    "registry-mirrors": ["https://docker.1ms.run"]
}
EOF
    systemctl daemon-reload
    systemctl enable docker --now
    echo -e "${GREEN}[✓] Docker 安装完成${NC}"
}

# ==============================
# CTF 工具安装
# ==============================
installPwntools() { python3 -m pip install pwntools; }

installSecLists() {
    [ -d /usr/share/wordlists/SecLists ] && { echo -e "${YELLOW}[!] SecLists 已存在${NC}"; return; }
    retryCmd git clone --depth 1 https://github.com/danielmiessler/SecLists.git /usr/share/wordlists/SecLists
}

installRockyou() {
    [ -f /usr/share/wordlists/rockyou.txt ] && { echo -e "${YELLOW}[!] rockyou 已存在${NC}"; return; }
    gzip -d /usr/share/wordlists/rockyou.txt.gz
}

installZsteg() {
    installPackages \
        ruby-full
    gem install zsteg
}

installSteghide() { installPackages steghide; }
installPycrypto() { python3 -m pip install pycrypto; }
installGmpy2() { python3 -m pip install gmpy2; }
installDirsearch() { installPackages dirsearch; }
installCiphey() { docker pull remnux/ciphey; docker run --rm remnux/ciphey echo "Docker 运行正常"; }

installStegseek() {
    retryCmd wget -O "$TMP_BASE/stegseek.deb" https://github.com/RickdeJager/stegseek/releases/download/v0.6/stegseek_0.6-1.deb
    dpkg -i "$TMP_BASE/stegseek.deb" || apt-get install -f -y
}

installOutguess() { installPackages outguess; }

installCrackle() {
    retryCmd git clone --depth 1 https://github.com/mikeryan/crackle.git "$TMP_BASE/crackle"
    (cd "$TMP_BASE/crackle" && make && make install)
}

# ==============================
# 安装验证
# ==============================
installAndVerify() {
    local name=$1
    local func=$2
    local verify=$3
    echo -e "${CYAN}[+] 正在安装 $name ...${NC}"
    if $func; then
        if eval "$verify" &>/dev/null; then
            echo -e "${GREEN}[✓] $name 安装并验证通过${NC}"
        else
            echo -e "${RED}[✗] $name 安装成功但验证失败，请手动检查${NC}"
        fi
    else
        echo -e "${RED}[✗] $name 安装过程出错${NC}"
    fi
}

# ==============================
# 工具清单
# ==============================
TOOLS_ORDER=(
    "Python3"
    "Python2"
    "Docker"
    "Pwntools"
    "SecLists"
    "Rockyou字典"
    "Zsteg"
    "Steghide"
    "Pycrypto"
    "Gmpy2"
    "Dirsearch"
    "Ciphey"
    "Stegseek"
    "Outguess"
    "Crackle"
)

declare -A tools=(
    ["Python3"]="installPython3:python3 -V"
    ["Python2"]="installPython2:python2 -V"
    ["Docker"]="installDocker:which docker"
    ["Pwntools"]="installPwntools:python3 -c 'import pwn'"
    ["SecLists"]="installSecLists:ls /usr/share/wordlists/SecLists"
    ["Rockyou字典"]="installRockyou:ls /usr/share/wordlists/rockyou.txt"
    ["Zsteg"]="installZsteg:which zsteg"
    ["Steghide"]="installSteghide:which steghide"
    ["Pycrypto"]="installPycrypto:python3 -c 'import Crypto'"
    ["Gmpy2"]="installGmpy2:python3 -c 'import gmpy2'"
    ["Dirsearch"]="installDirsearch:which dirsearch"
    ["Ciphey"]="installCiphey:docker images | grep remnux/ciphey"
    ["Stegseek"]="installStegseek:which stegseek"
    ["Outguess"]="installOutguess:which outguess"
    ["Crackle"]="installCrackle:which crackle"
)

# ==============================
# 主交互流程
# ==============================
echo -en "${YELLOW}[?] 是否开启 SSH 服务？(y/n): ${NC}"
read -r enable_ssh
[[ "$enable_ssh" =~ ^[yY]$ ]] && enableSSH

echo -en "${YELLOW}[?] 是否选择 APT 源镜像？(y/n): ${NC}"
read -r select_mirror
[[ "$select_mirror" =~ ^[yY]$ ]] && { chooseMirror; installKaliKeyring; cleanConflictingSources; updateSources; }

echo -e "${YELLOW}[?] 是否安装基础依赖工具？(y/n): ${NC}"
read -r install_base
[[ "$install_base" =~ ^[yY]$ ]] && installBaseTools

echo -en "${YELLOW}[?] 是否一键安装所有组件？(y/n): ${NC}"
read -r all_install

if [[ "$all_install" =~ ^[yY]$ ]]; then
    for tool in "${TOOLS_ORDER[@]}"; do
        IFS=":" read -r func verify <<< "${tools[$tool]}"
        installAndVerify "$tool" "$func" "$verify"
    done
else
    while true; do
        echo -e "${CYAN}[+] 请选择要安装的组件（输入数字，0=全部安装, q=退出）:${NC}"
        for i in "${!TOOLS_ORDER[@]}"; do
            echo "$((i+1)). ${TOOLS_ORDER[i]}"
        done
        read -rp "输入选项: " choice
        [[ "$choice" == "q" ]] && break
        if [[ "$choice" == "0" ]]; then
            for tool in "${TOOLS_ORDER[@]}"; do
                IFS=":" read -r func verify <<< "${tools[$tool]}"
                installAndVerify "$tool" "$func" "$verify"
            done
            break
        elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice>=1 && choice<= ${#TOOLS_ORDER[@]} )); then
            tool="${TOOLS_ORDER[$((choice-1))]}"
            IFS=":" read -r func verify <<< "${tools[$tool]}"
            installAndVerify "$tool" "$func" "$verify"
        else
            echo -e "${RED}[!] 输入无效${NC}"
        fi
    done
fi

echo -e "${GREEN}[✓] 所有选定组件安装完成${NC}"