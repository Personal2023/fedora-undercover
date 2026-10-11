#!/usr/bin/env bash
set -e

# ==============================================================================
# Script de Transformação: Fedora XFCE -> Windows 10 (22H2 Look)
# ATENÇÃO: Execute SEM sudo (o script pedirá senha para o dnf quando necessário)
# ==============================================================================

if [ "$EUID" -eq 0 ]; then
  echo "[-] ERRO: Não execute este script como root ou via sudo!"
  echo "    Execute apenas: bash $0"
  exit 1
fi

CURRENT_USER="$USER"
USER_HOME="$HOME"
TEMP_DIR="/tmp/win10-undercover-setup"

echo "=================================================="
echo "  Fedora XFCE -> Windows 10 22H2 (Usuário: $CURRENT_USER)"
echo "=================================================="

# ------------------------------------------------------------------------------
# 1. Dependências do Sistema
# ------------------------------------------------------------------------------
echo -e "\n[1/6] Instalando dependências via DNF..."
sudo dnf install -y \
  xfconf \
  xfce4-panel \
  xfce4-whiskermenu-plugin \
  wget2 \
  curl \
  unzip \
  fontconfig \
  rsync \
  git \
  cabextract

# ------------------------------------------------------------------------------
# 2. Pastas do Usuário
# ------------------------------------------------------------------------------
echo -e "\n[2/6] Preparando diretórios do usuário..."
mkdir -p "$USER_HOME/.themes"
mkdir -p "$USER_HOME/.icons"
mkdir -p "$USER_HOME/.local/share/fonts/segoe"
mkdir -p "$USER_HOME/.local/share/backgrounds"
mkdir -p "$TEMP_DIR"

cd "$TEMP_DIR"

# ------------------------------------------------------------------------------
# 3. Download do Tema GTK e Ícones (B00merang Project)
# ------------------------------------------------------------------------------
echo -e "\n[3/6] Baixando temas e ícones do Windows 10..."

# Tema GTK / XFWM
if [ ! -d "$USER_HOME/.themes/Windows-10" ]; then
  echo " -> Baixando tema GTK/XFWM..."
  curl -fsSL "https://github.com/B00merang-Project/Windows-10/archive/refs/heads/master.tar.gz" -o win10-theme.tar.gz
  mkdir -p "$TEMP_DIR/theme"
  tar -xzf win10-theme.tar.gz -C "$TEMP_DIR/theme" --strip-components=1
  cp -r "$TEMP_DIR/theme" "$USER_HOME/.themes/Windows-10"
fi

# Ícones
if [ ! -d "$USER_HOME/.icons/Windows-10" ]; then
  echo " -> Baixando conjunto de ícones..."
  curl -fsSL "https://github.com/B00merang-Artwork/Windows-10/archive/refs/heads/master.tar.gz" -o win10-icons.tar.gz
  mkdir -p "$TEMP_DIR/icons"
  tar -xzf win10-icons.tar.gz -C "$TEMP_DIR/icons" --strip-components=1
  cp -r "$TEMP_DIR/icons" "$USER_HOME/.icons/Windows-10"
  gtk-update-icon-cache -f -t "$USER_HOME/.icons/Windows-10" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 4. Papel de Parede (Windows 10 Hero Wallpaper)
# ------------------------------------------------------------------------------
WALLPAPER_DEST="$USER_HOME/.local/share/backgrounds/windows10_default.jpg"

if [ ! -f "$WALLPAPER_DEST" ]; then
  echo -e "\n[4/6] Baixando wallpaper do Windows 10 22H2..."
  set +e
  curl -fsSL -A "Mozilla/5.0" \
    "https://upload.wikimedia.org/wikipedia/commons/e/ea/Windows_10_Default_Hero_Desktop_Background.jpg" \
    -o "$WALLPAPER_DEST"

  if [ ! -s "$WALLPAPER_DEST" ]; then
    curl -fsSL -A "Mozilla/5.0" \
      "https://raw.githubusercontent.com/B00merang-Project/Windows-10/master/src/wallpaper.png" \
      -o "$WALLPAPER_DEST"
  fi
  set -e
fi

# ------------------------------------------------------------------------------
# 5. Aplicação de Temas Globais e Fontes
# ------------------------------------------------------------------------------
echo -e "\n[5/6] Aplicando temas GTK, ícones e fontes..."

# Tema de Janelas e GTK
xfconf-query -c xfwm4 -p /general/theme -s "Windows-10" --create -t string
xfconf-query -c xsettings -p /Net/ThemeName -s "Windows-10" --create -t string
xfconf-query -c xsettings -p /Net/IconThemeName -s "Windows-10" --create -t string

# Fontes (Segoe UI 10pt)
xfconf-query -c xsettings -p /Gtk/FontName -s "Segoe UI 10" --create -t string
xfconf-query -c xfwm4 -p /general/title_font -s "Segoe UI Bold 10" --create -t string

# Wallpaper
for prop in $(xfconf-query -c xfce4-desktop -l | grep "last-image"); do
  xfconf-query -c xfce4-desktop -p "$prop" -s "$WALLPAPER_DEST"
done

# ------------------------------------------------------------------------------
# 6. Reestruturação do Painel (Windows 10 22H2 Taskbar)
# ------------------------------------------------------------------------------
echo -e "\n[6/6] Configurando barra de tarefas e Whisker Menu..."

# 6.1 Eliminar painéis secundários (ex: dock padrão do Fedora)
ALL_PANELS=$(xfconf-query -c xfce4-panel -p /panels | grep -E '^[0-9]+$' || true)
for p in $ALL_PANELS; do
  if [ "$p" -ne 1 ]; then
    xfconf-query -c xfce4-panel -p "/panels/panel-$p" -r -R 2>/dev/null || true
  fi
done
xfconf-query -c xfce4-panel -p /panels -a -t int -s 1 --force-array

# 6.2 Posicionamento e dimensões do Painel 1 (Inferior, 40px altura)
xfconf-query -c xfce4-panel -p /panels/panel-1/locked -s false --create -t bool
xfconf-query -c xfce4-panel -p /panels/panel-1/mode -s 0 --create -t int
xfconf-query -c xfce4-panel -p /panels/panel-1/position -s "p=12;x=0;y=0" --create -t string
xfconf-query -c xfce4-panel -p /panels/panel-1/size -s 40 --create -t int
xfconf-query -c xfce4-panel -p /panels/panel-1/icon-size -s 24 --create -t int
xfconf-query -c xfce4-panel -p /panels/panel-1/locked -s true --create -t bool

# 6.3 Substituição do menu clássico pelo Whisker Menu (plugin-1)
OLD_MENU=$(xfconf-query -c xfce4-panel -p /plugins -lv 2>/dev/null | awk '$2 ~ /applicationsmenu/ {print $1}' | grep -o 'plugin-[0-9]*' || true)
if [ -n "$OLD_MENU" ]; then
  xfconf-query -c xfce4-panel -p "/plugins/$OLD_MENU" -r -R 2>/dev/null || true
fi

# Configuração do Whisker Menu com ícone do Windows
xfconf-query -c xfce4-panel -p /plugins/plugin-1 -s "whiskermenu" --create -t string
xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-icon -s "distributor-logo-windows" --create -t string
xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-title -s "" --create -t string
xfconf-query -c xfce4-panel -p /plugins/plugin-1/show-button-title -s false --create -t bool
xfconf-query -c xfce4-panel -p /plugins/plugin-1/show-button-icon -s true --create -t bool

# Garante que o Whisker Menu seja o primeiro item da barra
CURRENT_IDS=$(xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | grep -v "^$" | grep -v "^1$" || true)
CMD_ARRAY="xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -a -t int -s 1"
for id in $CURRENT_IDS; do
  CMD_ARRAY="$CMD_ARRAY -t int -s $id"
done
eval "$CMD_ARRAY" --force-array

# 6.4 Relógio no padrão Windows 10 (HH:MM na linha superior, DD/MM/AAAA na inferior)
CLOCK_ID=$(xfconf-query -c xfce4-panel -p /plugins -lv 2>/dev/null | awk '$2 ~ /clock/ {print $1}' | grep -o 'plugin-[0-9]*' | head -n 1 || true)
if [ -n "$CLOCK_ID" ]; then
  xfconf-query -c xfce4-panel -p "/plugins/$CLOCK_ID/mode" -s 4 --create -t int
  xfconf-query -c xfce4-panel -p "/plugins/$CLOCK_ID/digital-format" -s "%H:%M%n%d/%m/%Y" --create -t string
fi

# Limpeza dos temporários
rm -rf "$TEMP_DIR"

# ------------------------------------------------------------------------------
# 7. Recarregamento da Interface
# ------------------------------------------------------------------------------
echo -e "\nRecarregando componentes visuais do XFCE..."
xfsettingsd --replace >/dev/null 2>&1 &
xfwm4 --replace >/dev/null 2>&1 &
xfce4-panel -r >/dev/null 2>&1 &

echo -e "\n[+] Concluído com sucesso! Ambiente atualizado para Windows 10 22H2."