#!/usr/bin/env bash

STATE_FILE="$HOME/.config/undercover_state"
WALLPAPER_WIN="$HOME/.local/share/backgrounds/win10-22h2.jpg"

apply_windows() {
    touch "$STATE_FILE"

    xfconf-query -c xsettings -p /Gtk/FontName -s "Segoe UI 9"
    xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "Consolas 10"
    xfconf-query -c xfwm4 -p /general/title_font -s "Segoe UI Bold 9"

    xfconf-query -c xsettings -p /Net/ThemeName -s "Windows-10"
    xfconf-query -c xfwm4 -p /general/theme -s "Windows-10"
    xfconf-query -c xfwm4 -p /general/button_layout -s "O|HMC"

    xfconf-query -c xsettings -p /Net/IconThemeName -s "Windows-10"

    DESK_PROPS=$(xfconf-query -c xfce4-desktop -l | grep "last-image")
    for prop in $DESK_PROPS; do
        xfconf-query -c xfce4-desktop -p "$prop" -s "$WALLPAPER_WIN"
    done

    xfconf-query -c xfce4-panel -p /panels/panel-1/position -s "p=8;x=0;y=0"
    xfconf-query -c xfce4-panel -p /panels/panel-1/size -s 40

    xfce4-panel -r
    notify-send "Modo Undercover" "Visual Windows 10 ativado!" 2>/dev/null || true
}

restore_fedora() {
    rm -f "$STATE_FILE"

    xfconf-query -c xsettings -p /Gtk/FontName -s "Cantarell 10"
    xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "Source Code Pro 10"
    xfconf-query -c xfwm4 -p /general/title_font -s "Cantarell Bold 10"
    xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita"
    xfconf-query -c xfwm4 -p /general/theme -s "Adwaita"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Adwaita"

    xfce4-panel -r
    notify-send "Modo Undercover" "Visual Fedora padrão restaurado!" 2>/dev/null || true
}

if [ -f "$STATE_FILE" ]; then
    restore_fedora
else
    apply_windows
fi