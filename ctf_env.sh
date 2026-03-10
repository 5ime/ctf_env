#!/bin/bash
set -Eeuo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 全局变量
LOG_FILE="/var/log/ctf_env.log"
TMP_BASE=$(mktemp -d /tmp/ctf_env_XXXX)

# 退出时清理临时目录
trap 'rm -rf "$TMP_BASE"' EXIT

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[!] 请使用 root 用户运行该脚本！${NC}"
    exit 1
fi

# 重定向输出到日志文件和终端
exec > >(tee -a "$LOG_FILE") 2>&1

# 欢迎信息
echo -e "${CYAN}
#########################################################
#                    CTF_ENV                            #
#           Kali Linux 快速安装与配置CTF工具               #
#                                                       #
#                                   Version: 1.1.1      #
#                                   Author: iami233     #
#########################################################
${NC}"

# -----------------------------
# Kali 密钥环配置
# -----------------------------
installKaliKeyring() {
    echo -e "${CYAN}[+] 检查 Kali archive keyring...${NC}"
    if [ ! -f /usr/share/keyrings/kali-archive-keyring.gpg ]; then
        echo -e "${CYAN}[+] 下载 Kali archive keyring...${NC}"
        retryCmd wget -q https://archive.kali.org/archive-keyring.gpg -O /usr/share/keyrings/kali-archive-keyring.gpg
    else
        echo -e "${GREEN}[✓] Kali keyring 已存在${NC}"
    fi
}

# -----------------------------
# 镜像源配置
# -----------------------------
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

# -----------------------------
# 通用函数
# -----------------------------
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

updateSources() {
    echo -e "${CYAN}[+] 更新 APT 源...${NC}"

    # 备份原有源文件
    [ -f /etc/apt/sources.list ] && mv /etc/apt/sources.list "/etc/apt/sources.list.bak.$(date +%s)"

    # 写入新的源配置
    cat <<EOF > /etc/apt/sources.list
deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg] ${MIRROR_BASE} kali-rolling main contrib non-free non-free-firmware
EOF

    retryCmd apt-get update -y
}

installPackages() {
    echo -e "${CYAN}[+] 安装依赖: $* ...${NC}"
    retryCmd apt-get install -y "$@"
}

# -----------------------------
# 基础工具安装
# -----------------------------
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

# -----------------------------
# Python 环境安装
# -----------------------------
installPython3() {
    installPackages \
        python3 \
        python3-pip \
        python3-venv

    # 升级 pip 并使用清华源
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

# -----------------------------
# Docker 安装
# -----------------------------
installDocker() {
    installPackages \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # 配置 Docker GPG 密钥
    install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # 配置 Docker 源
    . /etc/os-release
    local docker_codename="${VERSION_CODENAME:-bookworm}"
    
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian $docker_codename stable" \
    > /etc/apt/sources.list.d/docker.list

    apt-get update -y

    # 安装 Docker 组件
    installPackages \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    # 配置 Docker 镜像加速
    mkdir -p /etc/docker
    cat <<EOF > /etc/docker/daemon.json
{
"registry-mirrors": ["https://docker.1ms.run"]
}
EOF

    # 重启 Docker 服务
    systemctl daemon-reload
    systemctl restart docker
}

# -----------------------------
# CTF 专用工具安装
# -----------------------------
installPwntools() {
    python3 -m pip install pwntools
}

installSecLists() {
    if [ -d /usr/share/wordlists/SecLists ]; then
        echo -e "${YELLOW}[!] SecLists 已存在，跳过克隆${NC}"
        return 0
    fi

    retryCmd git clone --depth 1 https://github.com/danielmiessler/SecLists.git /usr/share/wordlists/SecLists
}

installRockyou() {
    if [ -f /usr/share/wordlists/rockyou.txt ]; then
        echo -e "${YELLOW}[!] rockyou.txt 已存在，跳过解压${NC}"
        return 0
    fi

    if [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
        gzip -d /usr/share/wordlists/rockyou.txt.gz
    else
        echo -e "${RED}[!] 未找到 rockyou.txt.gz，请确保已安装 wordlists 包${NC}"
        return 1
    fi
}

installZsteg() {
    installPackages ruby-full && gem install zsteg
}

installSteghide() {
    installPackages steghide
}

installPycrypto() {
    python3 -m pip install pycrypto
}

installGmpy2() {
    python3 -m pip install gmpy2
}

installDirsearch() {
    installPackages dirsearch
}

installCiphey() {
    echo -e "${CYAN}[+] 正在拉取 Ciphey 镜像...${NC}"
    docker pull remnux/ciphey
    docker run --rm remnux/ciphey echo "Docker 运行正常"
}

installStegseek() {
    if command -v stegseek &>/dev/null; then
        echo -e "${YELLOW}[!] Stegseek 已安装，跳过${NC}"
        return 0
    fi

    retryCmd wget -O "$TMP_BASE/stegseek.deb" \
        https://github.com/RickdeJager/stegseek/releases/download/v0.6/stegseek_0.6-1.deb

    dpkg -i "$TMP_BASE/stegseek.deb" || apt-get install -f -y
}

installOutguess() {
    installPackages outguess
}

installCrackle() {
    if command -v crackle &>/dev/null; then
        echo -e "${YELLOW}[!] Crackle 已安装，跳过${NC}"
        return 0
    fi

    retryCmd git clone --depth 1 https://github.com/mikeryan/crackle.git "$TMP_BASE/crackle"
    (cd "$TMP_BASE/crackle" && make && make install)
}

# -----------------------------
# 安装验证通用函数
# -----------------------------
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

# -----------------------------
# 工具配置清单
# -----------------------------
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

# -----------------------------
# 主交互流程
# -----------------------------
# 选择镜像源
echo -en "${YELLOW}[?] 是否选择 APT 源镜像？(y/n): ${NC}"
read -r select_mirror

if [[ "$select_mirror" =~ ^[yY]$ ]]; then
    chooseMirror
    installKaliKeyring
    updateSources
fi

# 安装基础工具
echo -e "${YELLOW}[?] 是否安装基础依赖工具？(y/n): ${NC}"
read -r install_base
[[ "$install_base" =~ ^[yY]$ ]] && installBaseTools

# 选择安装模式
echo -en "${YELLOW}[?] 是否一键安装所有组件？(y/n): ${NC}"
read -r all_install

if [[ "$all_install" =~ ^[yY]$ ]]; then
    # 一键安装所有工具
    for tool in "${TOOLS_ORDER[@]}"; do
        IFS=":" read -r func verify <<< "${tools[$tool]}"
        installAndVerify "$tool" "$func" "$verify"
    done
else
    # 交互式选择安装
    while true; do
        echo -e "${CYAN}[+] 请选择要安装的组件（输入数字，0=全部安装, q=退出）:${NC}"
        
        # 显示工具列表
        for i in "${!TOOLS_ORDER[@]}"; do
            echo "$((i+1)). ${TOOLS_ORDER[i]}"
        done

        read -rp "输入选项: " choice

        # 退出
        [[ "$choice" == "q" ]] && break

        # 安装全部
        if [[ "$choice" == "0" ]]; then
            for tool in "${TOOLS_ORDER[@]}"; do
                IFS=":" read -r func verify <<< "${tools[$tool]}"
                installAndVerify "$tool" "$func" "$verify"
            done
            break
        # 安装指定工具
        elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice>=1 && choice<= ${#TOOLS_ORDER[@]} )); then
            tool="${TOOLS_ORDER[$((choice-1))]}"
            IFS=":" read -r func verify <<< "${tools[$tool]}"
            installAndVerify "$tool" "$func" "$verify"
        # 输入无效
        else
            echo -e "${RED}[!] 输入无效${NC}"
        fi
    done
fi

echo -e "${GREEN}[✓] 所有选定组件安装完成${NC}"