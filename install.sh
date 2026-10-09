#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}    Fedora 44 XFCE -> Windows 10 22H2     ${NC}"
echo -e "${BLUE}===========================================${NC}"

echo -e "\n${YELLOW}[1/5] Instalando dependências do sistema...${NC}"
sudo dnf install -y \
    xfconf \
    xfce4-panel \
    wget \
    curl \
    unzip \
    cabextract \
    fontconfig \
    rsync

THEMES_DIR="$HOME/.themes"
ICONS_DIR="$HOME/.icons"
FONTS_DIR="$HOME/.local/share/fonts/win10"
BG_DIR="$HOME/.local/share/backgrounds"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"

mkdir -p "$THEMES_DIR" "$ICONS_DIR" "$FONTS_DIR" "$BG_DIR" "$BIN_DIR" "$APP_DIR" /tmp/win10-setup

echo -e "\n${YELLOW}[2/5] Baixando temas e ícones do Windows 10...${NC}"
cd /tmp/win10-setup

if [ ! -d "$THEMES_DIR/Windows-10" ]; then
    wget -q --show-progress https://github.com/B00merang-Project/Windows-10/archive/refs/heads/master.zip -O win10-theme.zip
    unzip -q win10-theme.zip
    rm -rf "$THEMES_DIR/Windows-10"
    mv Windows-10-master "$THEMES_DIR/Windows-10"
    rm -f win10-theme.zip
fi

if [ ! -d "$ICONS_DIR/Windows-10" ]; then
    wget -q --show-progress https://github.com/B00merang-Artwork/Windows-10/archive/refs/heads/master.zip -O win10-icons.zip
    unzip -q win10-icons.zip
    rm -rf "$ICONS_DIR/Windows-10"
    mv Windows-10-master "$ICONS_DIR/Windows-10"
    rm -f win10-icons.zip
fi

echo -e "\n${YELLOW}[3/5] Configurando fontes (Segoe UI / Consolas / Arial)...${NC}"
if [ ! -f "$FONTS_DIR/SegoeUI.ttf" ]; then
    wget -q --show-progress "https://raw.githubusercontent.com/mrbvrz/segoe-ui-linux/master/font/SegoeUI.ttf" -O "$FONTS_DIR/SegoeUI.ttf" || true
    wget -q --show-progress "https://raw.githubusercontent.com/mrbvrz/segoe-ui-linux/master/font/SegoeUI-Bold.ttf" -O "$FONTS_DIR/SegoeUI-Bold.ttf" || true
    wget -q --show-progress "https://raw.githubusercontent.com/mrbvrz/segoe-ui-linux/master/font/SegoeUI-SemiBold.ttf" -O "$FONTS_DIR/SegoeUI-SemiBold.ttf" || true
    fc-cache -f "$FONTS_DIR"
fi

echo -e "\n${YELLOW}[4/5] Baixando papel de parede oficial Windows 10 22H2...${NC}"
wget -q --show-progress "https://images.wallpapersden.com/image/download/windows-10-official_a2lmbWqUmZqaraWkpJRmbmdlrWZlbWU.jpg" -O "$BG_DIR/win10-22h2.jpg"

echo -e "\n${YELLOW}[5/5] Instalando atalhos e scripts de alternância...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/toggle.sh" "$BIN_DIR/fedora-undercover"
chmod +x "$BIN_DIR/fedora-undercover"
cp "$SCRIPT_DIR/fedora-undercover.desktop" "$APP_DIR/"

rm -rf /tmp/win10-setup

echo -e "\n${GREEN}✔ Instalação finalizada com sucesso!${NC}"
echo -e "${BLUE}Deseja ativar o visual Windows 10 agora? (s/n)${NC}"
read -r answer
if [[ "$answer" =~ ^[Ss]$ ]]; then
    "$BIN_DIR/fedora-undercover"
fi
