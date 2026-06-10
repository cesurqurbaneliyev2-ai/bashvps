#!/bin/bash

# ==========================================================
# AZENODES PRO v2 - MODERN CLI EDITION
# ==========================================================

set -e

# ---------------- COLORS ----------------
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
BLUE="\e[34m"
BOLD="\e[1m"
NC="\e[0m"

# ---------------- UI FUNCTIONS ----------------

clear

banner() {
cat << "EOF"

 █████╗ ███████╗███████╗███╗   ██╗ ██████╗ ██████╗ ███████╗███████╗
██╔══██╗╚══███╔╝██╔════╝████╗  ██║██╔═══██╗██╔══██╗██╔════╝██╔════╝
███████║  ███╔╝ █████╗  ██╔██╗ ██║██║   ██║██████╔╝█████╗  ███████╗
██╔══██║ ███╔╝  ██╔══╝  ██║╚██╗██║██║   ██║██╔═══╝ ██╔══╝  ╚════██║
██║  ██║███████╗███████╗██║ ╚████║╚██████╔╝██║     ███████╗███████║
╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚══════╝╚══════╝

            AZENODES PRO v2 - MODERN CLI
EOF
}

pause() {
  echo -e "${YELLOW}\nPress ENTER davam etmək...${NC}"
  read
}

spinner() {
  local pid=$!
  local delay=0.1
  local spin='|/-\'
  while kill -0 $pid 2>/dev/null; do
    for i in $(seq 0 3); do
      echo -ne "\r${CYAN}Processing... ${spin:$i:1}${NC}"
      sleep $delay
    done
  done
  echo -ne "\r${GREEN}Done!        ${NC}\n"
}

error() {
  echo -e "${RED}[ERROR] $1${NC}"
  exit 1
}

# ---------------- CHECK ROOT ----------------
[[ $EUID -ne 0 ]] && error "Root kimi işə salınmalıdır!"

# ---------------- MENU ----------------
menu() {
  echo -e "${BLUE}${BOLD}"
  echo "=============================="
  echo "      AZENODES MAIN MENU"
  echo "=============================="
  echo -e "${NC}"

  PS3=$'\nSeçim et (1-3): '

  options=(
    "Pterodactyl Install"
    "Cloudflare Tunnel Setup"
    "Exit"
  )

  select opt in "${options[@]}"; do
    case $REPLY in
      1) install_pterodactyl; break;;
      2) install_cloudflare; break;;
      3) exit 0;;
      *) echo "Yanlış seçim";;
    esac
  done
}

# ---------------- INSTALL DEPS ----------------
deps() {
  echo -e "${YELLOW}[+] Dependencies install edilir...${NC}"
  apt update -y >/dev/null 2>&1 &
  spinner
  apt install -y curl wget git unzip sudo >/dev/null 2>&1
}

# ---------------- PTERODACTYL ----------------
install_pterodactyl() {

  echo -e "${CYAN}\n--- PTERODACTYL SETUP ---${NC}"

  read -p "Domain: " DOMAIN
  read -p "Admin Email: " EMAIL
  read -p "Admin Name: " NAME
  read -s -p "Password: " PASS
  echo
  read -p "Panel Port (default 80): " PORT
  PORT=${PORT:-80}

  deps

  echo -e "${GREEN}[+] Panel quraşdırılır...${NC}"

  apt install -y nginx mariadb-server php php-cli php-fpm php-mysql php-mbstring php-zip php-gd php-bcmath php-curl

  mysql -e "CREATE DATABASE panel;"
  mysql -e "CREATE USER 'ptero'@'127.0.0.1' IDENTIFIED BY 'ptero_pass';"
  mysql -e "GRANT ALL PRIVILEGES ON panel.* TO 'ptero'@'127.0.0.1'; FLUSH PRIVILEGES;"

  cd /var/www/
  curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
  mkdir -p panel
  tar -xzf panel.tar.gz -C panel

  echo -e "${GREEN}[✓] Base install tamamlandı${NC}"
}

# ---------------- CLOUDFLARE ----------------
install_cloudflare() {

  echo -e "${CYAN}\n--- CLOUDFLARE TUNNEL ---${NC}"

  read -p "Tunnel Token: " TOKEN

  deps

  echo -e "${YELLOW}[+] Cloudflared install edilir...${NC}"

  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
  dpkg -i cloudflared-linux-amd64.deb >/dev/null 2>&1

  cloudflared service install $TOKEN

  echo -e "${GREEN}[✓] Tunnel aktivdir${NC}"
}

# ---------------- RUN ----------------
banner
menu
