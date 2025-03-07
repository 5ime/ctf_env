# 🦉Kali 中 CTF 环境配置

由于 Kali 系统又双叒叕崩了，开个仓库记录配置和安装的软件，方便以后快速重装...

系统版本 `kali-linux-2022.4-vmware-amd64`

```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/5ime/ctf_env/main/ctf_env.sh && chmod +x ctf_env.sh && sudo bash ctf_env.sh
```

- 更换 apt 源
- 安装 Git、libssl-dev 等必要工具
- 安装并配置 Python2 / 3
- 安装并配置 Docker
- 安装 Docker Compose
- 下载并配置 SecLists
- 解压 rockyou 字典
- 安装 zsteg
- 安装 steghide
- 安装 Pwntools
- 安装 pycrypto
- 安装 gmpy2
- 安装 dirsearch
- 安装 Ciphey（Docker 容器）
- 安装 stegseek
- 安装 outguess
- 安装 crackle
