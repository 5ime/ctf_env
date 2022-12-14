# 🦉Kali 中 CTF 环境配置

由于 Kali 系统又双叒叕崩了，开个仓库记录配置和安装的软件，方便以后快速重装...

系统版本 `kali-linux-2022.4-vmware-amd64`

``` bash
wget -N --no-check-certificate https://raw.githubusercontent.com/5ime/auto_env/master/auto.sh && chmod +x auto.sh && bash auto.sh
```

- 更换 apt 源
- 安装 Python2 pip
- 更换 pip 源
- 升级 pip
- 安装 Docker 
- 安装 Docker-compose
- 更换 Docker 源
- 下载 SecLists
- 解压 rockyou
- 安装 zsteg
- 安装 steghide
- 安装 Pwntools
- 安装 pycrypto
- 安装 gmpy2
- 安装 dirsearch
- 安装 Ciphey